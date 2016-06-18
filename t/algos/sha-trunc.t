
use strict;
use warnings;

use Test::Needs { 'Digest::SHA' => '5.60' };
use Test::More;

use lib 't/lib/';
use KENTNL::DigestXTest;

KENTNL::DigestXTest->test_algo( 'SHA2-512/224' => sub { Digest::SHA->new(512224) } );
KENTNL::DigestXTest->test_algo( 'SHA2-512/256' => sub { Digest::SHA->new(512256) } );

done_testing;

