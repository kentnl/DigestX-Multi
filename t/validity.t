
use strict;
use warnings;

use Test::Needs 'Digest::MD5';
use Test::More;
use DigestX::Multi;

my $md = DigestX::Multi->new();
$md->add_digester( 'digester-1', Digest::MD5->new() );
$md->append_bytes('hello_world');

note "Testing permutations of invalid hashes";
validate( 0, 'hex',      { 'digester-1' => 'abcdef' } );
validate( 0, 'base64',   { 'digester-1' => 'abcdef' } );
validate( 0, 'uuencode', { 'digester-1' => 'abcdef' } );
validate( 0, 'binary',   { 'digester-1' => 'abcdef' } );
validate( 0, 'binary',   {} );
validate( 0, 'binary', { 'digester-1' => 'abcdef', 'digester-2' => 'abcdef' } );

note "Testing permutations of valid hashes";
validate( 1, 'binary',   $md->digests( format => 'binary' ) );
validate( 1, 'base64',   $md->digests( format => 'base64' ) );
validate( 1, 'uuencode', $md->digests( format => 'uuencode' ) );
validate( 1, 'hex',      $md->digests( format => 'hex' ) );

note "Testing invalid source hashes";

# Both source and target are empty creating a pass, but either being empty is itself
# an error and results in a failure
$md = DigestX::Multi->new();
validate( 0, undef, {} );

done_testing;

sub validate {
  my ( $truth, $format, $hash ) = @_;
  my $format_desc = defined $format ? $format : 'binary(default)';

  if ($truth) {
    my $ok = ok( $md->is_valid( { format => $format, digests => $hash } ), "Digest w/ $format_desc is valid as expected" );
    local $@ = undef;
    undef $ok unless ok(
      eval {
        $md->assert_valid( { format => $format, digests => $hash } );
        1;
      },
      "Digest w/ $format_desc does not throw any exception w/ assert_valid"
    );
    if ( !$ok ) {
      diag explain $md->_validity_map( { format => $format, digests => $hash } );
    }
  }
  else {
    my $ok = ok( !$md->is_valid( { format => $format, digests => $hash } ), "Digest w/ $format_desc is not valid as expected" );
    local $@ = undef;
    undef $ok unless ok(
      !eval {
        $md->assert_valid( { format => $format, digests => $hash } );
        1;
      },
      "Digest w/ $format_desc throws exception w/ assert_valid"
    );
    if ( !$ok ) {
      diag explain $md->_validity_map( { format => $format, digests => $hash } );
    }
  }
}
