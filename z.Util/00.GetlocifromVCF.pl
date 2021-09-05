#! perl

use warnings;
use strict;

my $vcf = shift;

open (IN, "zcat $vcf|");
open F,"> 00.GetlocifromVCF.pl.loci.txt";
while(<IN>){
    next if /^#/;
    (my $chr,my $loc) = (split/\t/,$_)[0,1];
    print F "$chr\t$loc\n";
}
close IN;
close F;
