#! perl

use warnings;
use strict;

my $tb = "/data/01/user112/database/go/go.tb";
my %h;
open IN,'<',$tb;
readline IN;
while(<IN>){
    chomp;
    my @l = split/\t/;
    $h{$l[0]} = $l[2];
}
close IN;
open IN,'<',shift;
print "gene\tGO\tlevel\n";
while(<IN>){
    chomp;
    my @l = split/\t/;
    my $g = shift @l;
    for my $a (@l){
        next if !exists $h{$a};
        print "$g\t$a\t$h{$a}\n";
    }
}
