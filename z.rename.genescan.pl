#! perl

use warnings;
use strict;

open IN,'<',shift;
my $n = "g";
my $c = "0";

while(<IN>){
    if (/gene/){
        $c += 1;
    }
    s/\_g\d+/\_$n$c/g;
    
    print $_;
}
