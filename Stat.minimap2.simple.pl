#! perl

use warnings;
use strict;

my $paf = shift;
my %h;

open IN,'<',$paf;
while(<IN>){
    chomp;
    my @l = split/\t/;
    $h{"$l[0]-$l[5]\t$l[4]"}{len_ref} += $l[3] - $l[2];
    $h{"$l[0]-$l[5]\t$l[4]"}{len_que} += $l[8] - $l[7];
    $h{"$l[0]-$l[5]\t$l[4]"}{count} += 1;
}
close IN;

for my $k(sort {$a cmp $b} keys %h){
    print "$k\t";
    print $h{$k}{len_ref}."\t".$h{$k}{len_que}."\t".$h{$k}{count};
    print "\n";
}
