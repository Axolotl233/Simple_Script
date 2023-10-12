#! perl

use warnings;
use strict;

my $ref = shift;
my $query = shift;
my $col = shift;
$col = "0,1,2,3";
my @cols = split/,/,$col;

my %h;
open IN,'<',$ref;
while(<IN>){
    chomp;
    my @l = split/\t/;
    $h{$l[$cols[0]]}{$l[$cols[1]]} = [$l[$cols[2]],$l[$cols[3]]];
}
close IN;
open IN,'<',$query;
while(<IN>){
    chomp;
    my @info1 = split/:/;
    my $chr = $info1[0];
    my @info2 = split/\-/,$info1[1];
    for my $g (sort{$a cmp $b} keys %{$h{$chr}}){
        my @t = @{$h{$chr}{$g}};
        if($info2[1] >= $t[0] && $t[1] >= $info2[0]){
            print "$_\t$g\t$t[0]\t$t[1]\n";
        }
    }
}

