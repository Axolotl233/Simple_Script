#! perl

use warnings;
use strict;

my %g;

open R,'<',shift;
while(<R>){
    chomp;
    my @line = split/\t/;
    @{$g{$line[1]}} = ($line[0],$line[2],$line[3]);
}
close R;

open IN,'<',shift;
while(<IN>){
    next if /^#/;
    my @row = split/\t/;
    next if ${$g{$row[1]}}[0] eq ${$g{$row[2]}}[0];
    my $g1 = join"\t",@{$g{$row[1]}};
    my $g2 = join"\t",@{$g{$row[2]}};
    print $g1."\t".$g2."\n";
}
close IN;
