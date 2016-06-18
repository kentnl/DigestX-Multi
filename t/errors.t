
use strict;
use warnings;

use Test::Needs 'Digest::MD5';
use Test::More;
use DigestX::Multi;

sub is_error;

is_error "Non-Hash initializer" => sub { DigestX::Multi->new( [] ) };

my $instance = DigestX::Multi->new()->clone->reset_digesters;
$instance->add_digester( 'digester-1', Digest::MD5->new() );

is_error "Duplicate digester" => sub { $instance->add_digester( 'digester-1', [] ) };

$instance = DigestX::Multi->new()->append_bytes("No hashes....");    # doesn't error, maybe it should.

is_error "Missing file" => sub { $instance->append_file( "I_DO_NOT_EXIST" . time() ) };

is_error "Invalid digester" => sub { $instance->digests( format => 'I_do_Not_Exist' ) };

is_error "Missing digest hash" => sub { $instance->is_valid() };

done_testing;

sub is_error {
  my ( $reason, $code ) = @_;
  my $result = catch($code);
  ok( defined $result, $reason );
  return $result;
}

sub catch {
  my ($code) = @_;
  local $@ = undef;
  my $ok = 1;
  eval {
    $code->();
    $ok = 0;
  };
  if ( $ok and defined $@ ) {
    return $@;
  }
  if ( $ok and not defined $@ ) {
    return "Code did not execute, but exception was undefined";
  }
  return undef;
}
