
use strict;
use warnings;

use Test::Needs 'Digest::SHA';
use Test::More;

use lib 't/lib/';
use KENTNL::DigestXTest;

KENTNL::DigestXTest->test_algo( 'SHA1'         => sub { Digest::SHA->new(1) } );
KENTNL::DigestXTest->test_algo( 'SHA2-224'     => sub { Digest::SHA->new(224) } );
KENTNL::DigestXTest->test_algo( 'SHA2-256'     => sub { Digest::SHA->new(256) } );
KENTNL::DigestXTest->test_algo( 'SHA2-384'     => sub { Digest::SHA->new(384) } );
KENTNL::DigestXTest->test_algo( 'SHA2-512'     => sub { Digest::SHA->new(512) } );
KENTNL::DigestXTest->test_algo( 'SHA2-512/224' => sub { Digest::SHA->new(512224) } );
KENTNL::DigestXTest->test_algo( 'SHA2-512/256' => sub { Digest::SHA->new(512256) } );

done_testing;

