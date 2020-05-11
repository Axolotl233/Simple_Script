#! perl

use warnings;
use strict;

my $genome_size = shift;
my $repeat_size = shift;

my @tables = grep {/table/} `find ./split_gff`;

my %h;

for my $file (@tables){
    chomp $file;
    open IN,'<',$file;
    while(<IN>){
        my @line = split/\t/;
        $h{$line[0]} += $line[1];
    }
}

for my $k (sort {$a cmp $b}keys %h){
    my $rg = ($h{$k} * 100)/$genome_size;
    my $rr = ($h{$k} * 100)/$repeat_size;
    print "$k\t$h{$k}\t";
    printf "%.3f", $rr;
    print "\t";
    printf "%.3f", $rg;
    print "\n";
}
