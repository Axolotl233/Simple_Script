#! perl

use warnings;
use strict;

my %h;
while(<>){
    chomp;
    my @l = split/\t/;
    if ($l[2] eq "TF"){
        $h{$l[1]} += 1;
    }
}
for my $k (sort {$a cmp $b} keys %h){
    print "$k\t$h{$k}\n";
}
