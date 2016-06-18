use strict;
use warnings;

use Test::Needs 'Digest::MD5';
use Test::More;

use lib 't/lib/';
use KENTNL::DigestXTest;

KENTNL::DigestXTest->test_algo( 'MD5' => sub { Digest::MD5->new() } );

done_testing;
