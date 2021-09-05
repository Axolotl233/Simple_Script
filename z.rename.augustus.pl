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
    s/=g\d+/=$n$c/g;
    s/cds.g\d+/cds.g$c/g;
    print $_;
}
