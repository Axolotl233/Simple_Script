#! perl

use warnings;
use strict;

my $vcf = shift;
my $fh;
if($vcf =~ /gz$/){
    open ($fh, "zcat $vcf|");
}else{
    open $fh,'<',$vcf;
}
open F,"> 00.GetlocifromVCF.pl.loci.txt";
while(<$fh>){
    next if /^#/;
    (my $chr,my $loc,my $ref,my $ale) = (split/\t/,$_)[0,1,3,4];
    next if (length $ref > 1);
    next if (length $ale > 1);
    print F "$chr\t$loc\n";
}
close $fh;
close F;
