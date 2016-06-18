use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.18

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/DigestX/Multi.pm',
    't/00-compile/lib_DigestX_Multi_pm.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/algos/md5.t',
    't/algos/sha-trunc.t',
    't/algos/sha.t',
    't/algos/sha3.t',
    't/algos/whirlpool.t',
    't/errors.t',
    't/io.t',
    't/lib/KENTNL/DigestXTest.pm',
    't/validity.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
