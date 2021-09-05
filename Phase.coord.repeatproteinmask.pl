#! perl

use warnings;
use strict;
print STDERR "perl $0 \$repeatpreteinmask.gff\n";
open IN,'<',shift or die "need gff\n";
while(<IN>){
    next if /^#/;
    my @l = split/\t/;
    $l[0] =~ /(.*?)\-(.*)/;
    $l[0] = $1;
    $l[3] += $2;
    $l[4] += $2;
    print join "\t",@l;
}
