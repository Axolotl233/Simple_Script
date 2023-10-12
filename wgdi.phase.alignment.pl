#! perl

use warnings;
use strict;

if (@ARGV != 3){
    print STDERR "USAGE : perl $0 convert1 convert2 alignment.csv\n";
    exit;
}
my %h1 = read_info($ARGV[0]);
my %h2 = read_info($ARGV[1]);

open IN,'<',$ARGV[2];
while(<IN>){
    chomp;
    my @l = split/,/;
    next if scalar @l == 1;
    next if ($l[1] eq '.');
    $l[0] = $h1{$l[0]};
    $l[1] = $h2{$l[1]};
    @l = sort {$a cmp $b} @l;
    print join",",@l;
    print "\n";
}

sub read_info{
    my $f = shift;
    my %h;
    open IN,'<',$f;
    while(<IN>){
        chomp;
        my @l = split/\t/;
        $h{$l[0]} = $l[1];
    }
    close IN;
    return %h;
}
