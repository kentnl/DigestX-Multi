use strict;
use warnings;

package KENTNL::DigestXTest;

use DigestX::Multi;
use Test::Builder;

sub test_algo {
  my ( $class, $label, $algo_gen_sub ) = @_;

  my $md = DigestX::Multi->new();
  $md->add_digester( 'digest-1' => $algo_gen_sub->() );
  $md->append_bytes("Hello World");

  my $hash_1 = $md->digests( { format => 'base64' } );
  my $hash_2 = $md->digests( { format => 'base64' } );

  my $builder = Test::Builder->new();

  $builder->note('Testing digests() is non-destructive');

  return
    unless $builder->ok( exists $hash_1->{'digest-1'}, $label . ': digest-1 exists in digest-hash 1' )
    and $builder->ok( exists $hash_2->{'digest-1'}, $label . ': digest-1 exists in digest-hash 2' );

  return
    unless $builder->ok( defined $hash_1->{'digest-1'}, $label . ': digest-1 defined in digest-hash 1' )
    and $builder->ok( defined $hash_2->{'digest-1'}, $label . ': digest-1 defined in digest-hash 2' );

  if ( $hash_1->{'digest-1'} eq $hash_2->{'digest-1'} ) {
    $builder->ok( 1, $label . ': First digest() matches second digest() for digest-1' );
  }
  else {
    $builder->ok( 0, $label . ': First digest() matches second digest() for digest-1' );
    $builder->diag("Digests do not match for $label");
    $builder->diag( " - Expected: " . $hash_1->{'digest-1'} );
    $builder->diag( " - Got: " . $hash_2->{'digest-1'} );
    return;
  }

  $builder->note('Testing adding new digesters late in cycle');

  $md->add_digester( 'digest-2', $algo_gen_sub->() );
  $md->append_bytes("Hello World");

  my $hash_3 = $md->digests( { format => 'base64' } );

  return
    unless $builder->ok( exists $hash_3->{'digest-1'}, $label . ': digest-1 exists in digest-hash 3' )
    and $builder->ok( exists $hash_3->{'digest-2'}, $label . ': digest-2 exists in digest-hash 3' );

  return
    unless $builder->ok( defined $hash_3->{'digest-1'}, $label . ': digest-2 defined in digest-hash 3' )
    and $builder->ok( defined $hash_3->{'digest-2'}, $label . ': digest-2 defined in digest-hash 3' );

  if ( $hash_3->{'digest-1'} ne $hash_3->{'digest-2'} ) {
    $builder->ok( 1, $label . ': Early digest-1 does not equal later digest-2' );
  }
  else {
    $builder->ok( 0, $label . ': Early digest-1 does not equal later digest-2' );
    $builder->diag("Digests unexpectedly match for $label");
    $builder->diag(" - Expected: Anything else");
    $builder->diag( " - Got: " . $hash_3->{'digest-1'} );
    return;
  }

  $builder->ok( $md->is_valid( { format => 'base64', digests => $hash_3 } ), "$label: Should validate against identical hash" );
  $builder->ok( !$md->is_valid( { format => 'base64', digests => $hash_2 } ), "$label: Should not validate against stale hash" );

  my $copy = $md->clone();

  my $ltest = $builder->ok(
    $md->is_valid( { format => 'base64', digests => $hash_3 } ),
    "$label: Original Should validate against identical hash after a clone"
  );
  undef $ltest
    unless $builder->ok(
    $copy->is_valid( { format => 'base64', digests => $hash_3 } ),
    "$label: Clone Should validate against identical hash after a clone"
    );

  if ( not $ltest ) {
    require Test::More;
    $builder->diag(
      Test::More::explain(
        {
          hash_cmp => $hash_3,
          orig     => [ $md->_validity_map( { format => 'base64', digests => $hash_3 } ) ],
          orig_hash => $md->digests( format => 'base64' ),
          copy      => [ $copy->_validity_map( { format => 'base64', digests => $hash_3 } ) ],
          copy_hash => $copy->digests( format  => 'base64' ),
        }
      )
    );
  }

  $copy->reset_digesters();

  $ltest = $builder->ok( $md->is_valid( { format => 'base64', digests => $hash_3 } ),
    "$label: Original Should validate against identical hash after a clone+reset" );
  undef $ltest
    unless $builder->ok(
    !$copy->is_valid( { format => 'base64', digests => $hash_3 } ),
    "$label: Clone Should not validate against identical hash after a clone+reset"
    );

  if ( not $ltest ) {
    require Test::More;
    $builder->diag(
      Test::More::explain(
        {
          hash_cmp => $hash_3,
          orig     => [ $md->_validity_map( { format => 'base64', digests => $hash_3 } ) ],
          orig_hash => $md->digests( format => 'base64' ),
          copy      => [ $copy->_validity_map( { format => 'base64', digests => $hash_3 } ) ],
          copy_hash => $copy->digests( format  => 'base64' ),
        }
      )
    );
  }

}

1;

