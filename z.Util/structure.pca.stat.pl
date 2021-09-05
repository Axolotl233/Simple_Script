#! perl

use warnings;
use strict;
use List::Util qw(sum);

open IN,'<',shift;
my @a;
while(<IN>){
    chomp;
    push @a,$_;
}
my $sum = sum(@a);

foreach my $n (@a){
    my $c = ($n*100)/$sum;
    print $n."\t".$c."%\n";
}
