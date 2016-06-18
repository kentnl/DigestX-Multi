use 5.006;    # our
use strict;
use warnings;

package DigestX::Multi;

our $VERSION = '0.001000';
use Carp qw( croak carp );

# ABSTRACT: Simplify digesting the same content with multiple digesters.

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY













sub new {
  my ( $class, @args, ) = @_;
  my $arg_hash = { ref $args[0] ? %{ $args[0] } : @args };
  my $self = bless $arg_hash, $class;
  return $self;
}
















sub add_digester {
  my ( $self, $name, $digester, ) = @_;
  croak "Can't add digester with name $name, one already exists" if exists $self->{digesters}->{$name};
  $self->{digesters}->{$name} = $digester;
  return $self;
}










sub clone {
  my ( $self, ) = @_;
  my $class = ref $self;
  my $clone = bless {}, $class;
  $clone->{digesters}->{$_} = $self->{digesters}->{$_}->clone for keys %{ $self->{digesters} || {} };
  return $clone;
}









sub reset_digesters {
  my ( $self, ) = @_;
  $self->{digesters}->{$_}->reset for keys %{ $self->{digesters} || {} };
  return $self;
}











sub append_bytes {
  my ( $self, @bytes ) = @_;
  $self->{digesters}->{$_}->add(@bytes) for keys %{ $self->{digesters} || {} };
  return $self;
}













sub append_filehandle {
  my ( $self, $filehandle ) = @_;
  my $n;
  my $buf = q[];
  while ( $n = read $filehandle, $buf, 4 * 1024 ) {
    $self->append_bytes($buf);
  }
  return $self;
}











sub append_file {
  my ( $self, $path ) = @_;
  open my $fh, '<:raw', $path or croak "Can't open $path, $!";
  $self->append_filehandle($fh);
  close $fh or carp "Error closing $path";
  return $self;
}

sub _digest_binary   { $_[0] }
sub _digest_hex      { unpack 'H*', $_[0] }
sub _digest_uuencode { pack 'u', $_[0] }

sub _digest_base64 {
  require MIME::Base64;
  ## no critic (ProhibitCallsToUnexportedSubs)
  my $encoded = MIME::Base64::encode( $_[0], q[] );
  $encoded =~ s{=+$}{}sx;
  return $encoded;
}























sub digests {
  my ( $self, @args ) = @_;
  my $arg_hash = { ref $args[0] ? %{ $args[0] } : @args };
  $arg_hash->{format} ||= 'binary';
  $arg_hash->{encode} ||= do {
    my $ref = $self->can( '_digest_' . $arg_hash->{format} );
    croak "Unknown format $arg_hash->{format}" if not defined $ref;
    $ref;
  };
  my $result = {};
  $result->{$_} = $arg_hash->{encode}->( $self->{digesters}->{$_}->clone->digest ) for keys %{ $self->{digesters} || {} };
  return $result;
}













sub is_valid {
  my ( $self, @args ) = @_;
  for my $result ( $self->_validity_map(@args) ) {
    return q[] if not $result->{pass};
  }
  return 1;
}













sub assert_valid {
  my ( $self, @args ) = @_;
  #<<<
  my (@errs) = map  { $_->{reason} || 'Undefined Reason' }
               grep { !$_->{pass}                        }
               $self->_validity_map(@args);
  #>>>
  return 1 unless @errs;
  croak "Hash digests failed validation against expected:\n\t-" . ( join qq[,\n\t], @errs ) . "\n at ";
}

sub _validity_map {
  my ( $self, @args ) = @_;
  my $arg_hash = { ref $args[0] ? %{ $args[0] } : @args };

  croak q[No hash 'digests' to validate] unless exists $arg_hash->{'digests'};

  my %want_hash = %{ delete $arg_hash->{'digests'} };
  my %got_hash  = %{ $self->digests($arg_hash) };

  my %all_keys = map { ( $_ => 1 ) } keys %got_hash, keys %want_hash;

  my @results;

  push @results, { pass => 0, reason => 'HASH:INPUT:EMPTY' }    if not keys %got_hash;
  push @results, { pass => 0, reason => 'HASH:EXPECTED:EMPTY' } if not keys %want_hash;

  ## no critic (ProhibitCommaSeparatedStatements)
  for my $key ( keys %all_keys ) {
    ( push @results, { pass => 0, reason => "KEY:$key:MISSING", } ), next if !exists $got_hash{$key};
    ( push @results, { pass => 0, reason => "KEY:$key:EXCESS", } ),  next if !exists $want_hash{$key};
    ( push @results, { pass => 0, reason => "KEY:$key:NOMATCH", } ), next if $got_hash{$key} ne $want_hash{$key};
    push @results, { pass => 1, reason => "KEY:$key:MATCH", };
  }
  return @results;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DigestX::Multi - Simplify digesting the same content with multiple digesters.

=head1 VERSION

version 0.001000

=head1 SYNOPSIS

  require Digest::SHA3;
  require Digest::SHA;
  require Digest::Whirlpool;

  my $md = DigestX::Multi->new();
  $md->add_digester( 'sha3-512' => Digest::SHA3->new(512) );
  $md->add_digester( 'sha2-512' => Digest::SHA->new(512) );

  # Add byte-strings to all current digesters.
  $md->append_bytes("ByteString", "ByteString", "ByteString");

  # Read IO Handle into all current digesters.
  $md->append_filehandle( $io_handle );

  # Add a digester later that only includes later content
  $md->append_digester( 'whirlpool' => Digest::Whirlpool->new() );

  # Open "path/to/file" and read it into all current digesters.
  $md->append_file( "path/to/file" );

  # Get digest hashes
  # Note: This is intended to be **nondestructive**
  # and internally clones each digester before computing the state.
  my $hashref = $md->digests( format => 'binary' );
   ..         = $md->digests( format => 'hex' );
   ..         = $md->digests( format => 'base64' );


  # true/false
  if ( $md->is_valid( format => 'base64' , digests => $hashref ) ) {
    ...
  }


  # throw exception with details if not valid
  $md->assert_valid( format => 'base64', digests => $hashref );

=head1 METHODS

=head2 C<new>

Create an instance of DigestX::Multi.

  my $instance = DigestX::Multi->new();
  my $instance = DigestX::Multi->new( digesters => { identity => Digest::MD5->new(), } );

This instance starts off with no child digesters, but they can be added via C<add_digester>,
or passed in during construction via C<digesters> as a hash.

=head2 C<add_digester>

Add a new C<Digest> child to this instance.

  $instance->add_digester( my-name => Digest::SHA->new(512) );

C<my-name> must be unique and non-existing.

This method can be called at any time, as long as the user is aware that adding a new C<Digester> late in the cycle
will result in the "Late" digester not including data that was "append"'d previously.

This is deemed a feature.

=head2 C<clone>

Create a new C<Digest::Multi> object where all its child C<digesters> are clones
of this one.

  my $clone = $instance->clone;

=head2 C<reset_digesters>

Call C<reset> on all child digesters.

  $instance->reset_digesters;

=head2 C<append_bytes>

Append all of the strings passed to each child C<digester>.

  $instance->append_bytes("Hello World", "This is also a byte string");

This essentially calls L<< C<< ->add >>|Digest::base/add >> on all child C<digesters> as is.

=head2 C<append_filehandle>

Stream a given C<IO::Handle> until C<EOF> and append its contents efficiently to each current C<digester> child.

  $instance->append_filehandle( path('./foo')->openr_raw );

This will read the given C<filehandle> in C<4KB> chunks and rotate each chunk into each digester via C<append_bytes>

The given C<filehandle> really should be opened in C<raw> mode as everything in C<Digest> really expects C<bytes>.

=head2 C<append_file>

Open the given file in raw mode and iterate its contents through all attached C<digesters>.

  $instance->append_file("./foo");

This will open the given file in C<raw> mode and rotate its contents into the digesters via C<append_filehandle>

=head2 C<digests>

Return a C<HashRef> of C<< identity => digest >>.

  my $hash = $instance->digests(); # format binary assumed

  my $hash = $instance->digests( format => 'binary' );    # use literal binary data
           = $instance->digests( format => 'hex' );       # hex encode digest data
           = $instance->digests( format => 'uuencode' );  # uuencode digest data
           = $instance->digests( format => 'base64' );    # base64(*) encode digest data
           = $instance->digests( encode => sub { } );     # use a custom binary encoding function.

B<*> Base64 data has trailing C<=> padding characters stripped like C<Digest::base>.

B<NOTE:> This method is B<NON DESTRUCTIVE> and can called multiple times to provide the same hash in different encodings.

To facilitate this, C<< ->clone >> is called on each underlying C<digester> before calling their respective C<digest> method.

If a destructive pattern is required, please call C<< ->reset_digesters >> at the appropriate time.

=head2 C<is_valid>

Validate an existing C<HashRef> against accumulated data.

  my $boolean = $instance->is_valid( digests => $hash );  # format binary assumed
  my $boolean = $instance->is_valid( format => binary,  digests => $hash );
              = $instance->is_valid( encode => sub { }, digests => $hash );

See L</VALIDATION>

=head2 C<assert_valid>

Demand accumulated data to be valid using C<HashRef> as a reference, or die explaining all the reasons it isn't.

  $instance->assert_valid( digests => $hash );  # format binary assumed
           ->assert_valid( format => 'binary', digests => $hash );
           ->assert_valid( encode => sub { } , digests => $hash );

See L</VALIDATION>

=head1 VALIDATION

Validation rules are as follows:

=over 4

=item * If the "Digests" hash ( that is, the result of digesting the data )
has no keys, then its a failure, on grounds of the digest configuration being
broken.

=item * If the "Validation" hash ( that is, the hash the digested data is to be
compared against ), then its a failure, on grounds that the validation hash
being empty indicates data corruption.

=item * If a key is present in the "Validation hash" but not in the "Digests"
hash, then its a failure, on grounds that we were unable to locally validate
the data against it.

=item * If a key is present in the "Digests" hash, but not in the "Validation"
hash, then its a failure, on grounds that this may be a hash that is necessary
to confirm no-tampering, and thus, its absence is equivalent to it being
wrong.

=item * If any digest does not match in each hash via corresponding keys, then
its a failure, because any digest failing to match is a sure sign of some kind
of problem occurring.

=item * Finally, if the above conditions are satisfied, assuming the values in
the "Digests" and "Validation" hash are equal for all keys, then its a success.

=back

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
