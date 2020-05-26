#! perl

use warnings;
use strict;

open IN,'<',shift;

my %h;

while(<IN>){
    my $contig = (split/\t/,$_)[0];
    $h{$contig} .= $_;
}

`mkdir split_bed` if (! -e "split_bed");

foreach my $k (sort {$a cmp $b} keys %h){
    open OUT,'>',"split_bed/$k.bed.txt";
    print OUT $h{$k};
    close OUT;
}
