use strict;
use warnings;

use Test::Needs 'Digest::SHA3';
use Test::More;
use lib 't/lib/';
use KENTNL::DigestXTest;

KENTNL::DigestXTest->test_algo( 'SHA3-224' => sub { Digest::SHA3->new(224) } );
KENTNL::DigestXTest->test_algo( 'SHA3-256' => sub { Digest::SHA3->new(256) } );
KENTNL::DigestXTest->test_algo( 'SHA3-384' => sub { Digest::SHA3->new(384) } );
KENTNL::DigestXTest->test_algo( 'SHA3-512' => sub { Digest::SHA3->new(512) } );

KENTNL::DigestXTest->test_algo( 'SHAKE-128' => sub { Digest::SHA3->new(128000) } );
KENTNL::DigestXTest->test_algo( 'SHAKE-256' => sub { Digest::SHA3->new(256000) } );

done_testing;

