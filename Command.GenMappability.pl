#! perl

use warnings;
use strict;
use File::Basename;

my $ref = shift;
my $threads = shift;
$threads //= 10;
if(!$ref){
    print STDERR "\nUSAGE : perl $0 \$ref \[\$threads]\n\n";
    exit;
}
(my $name = basename $ref) =~ s/(.*?)\..*/$1/;

print "gem-indexer -T $threads -c dna -i $ref -o $name\.index
gem-mappability -T $threads -I $name\.index.gem -l 150 -o $name\_150
gem-2-wig -I $name\.index.gem -i $name\_150.mappability -o $name\_150
perl /data/00/user/user112/code/script/Convert.Wig2Bed.pl $name\_150.wig | bgzip -c > $name\_150.wig.mapQ.gz
zcat $name\_150.wig.mapQ.gz | awk '\$4==1' | cut -f 1-3 > $name\.keepPos.bed\n";
