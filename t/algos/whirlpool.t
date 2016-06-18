
use strict;
use warnings;

use Test::Needs 'Digest::Whirlpool';

use Test::More;

use lib 't/lib/';
use KENTNL::DigestXTest;

KENTNL::DigestXTest->test_algo( 'Whirlpool' => sub { Digest::Whirlpool->new() } );

done_testing;

