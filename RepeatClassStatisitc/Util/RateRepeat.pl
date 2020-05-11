#! perl

use warnings;
use strict;
use List::Util qw (sum);

my $genome_size = shift;
open IN,'<',shift;

(my %h,my %sum);

my @head = split/\t/,readline IN;

while(<IN>){
    chomp;
    my @line = split/\t/,$_;
    for(my $i = 1; $i < @line;$i ++){
        push @{$h{$head[$i]}},$line[$i];
    }
}
close IN;
for my $k(sort keys %h){
    my $t = sum(@{$h{$k}});
    #map{print $_}@{$h{$k}};exit;
    chomp $k;
    print "$k\t$t\t";
    my $r = ($t*100)/$genome_size;
    printf "%.2f",$r;
    print "%\n";
}
