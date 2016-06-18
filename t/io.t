
use strict;
use warnings;

use Test::Needs 'Digest::MD5';
use Test::More;
use DigestX::Multi;

my $md = DigestX::Multi->new();
$md->add_digester( 'digester-1', Digest::MD5->new() );
$md->add_digester( 'digester-2', Digest::MD5->new() );

open my $fh, '<:raw', __FILE__ or die "Cant open " . __FILE__ . ": $!";
$md->append_filehandle($fh);

my $hash = $md->digests();

$md->add_digester( 'digester-3', Digest::MD5->new() );

$md->append_file(__FILE__);

my $hash2 = $md->digests();

is( $hash2->{'digester-3'}, $hash->{'digester-1'}, "Filehandle reader and file reader give same result" );

done_testing;

