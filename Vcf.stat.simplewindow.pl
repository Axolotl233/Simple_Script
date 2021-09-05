#! perl

use warnings;
use strict;

my $file = shift;
my $window =shift;
my $bp = shift;
open IN,"zcat $file |" or die "$!";
my %h;
while(<IN>){
    chomp;
    next if /^#/;
    my @line = split/\t/;
    $h{$line[0]}{$line[1]} = 1;
}
close IN;
my %r;
for my $k1 (sort {$a cmp $b} keys %h){
    my @loc = sort {$a <=> $b} keys %{$h{$k1}};
    my $last = $loc[-1];
    DO:for(my $start = 0;$start < $last;$start += $bp){
        my $jud = 0;
        my $c2 = 0;
        my $end = $start + $window;
        if($end > $last){
            $jud = 1;
            $end = $last;
        }
        for (my $i = $start;$i <= $end;$i++){
            if (exists $h{$k1}{$i}){
	$c2 += 1;
	$r{$c2} += 1;
            }
        }
        last DO if $jud == 1;
    }
}
for(my $i = 1;$i < $window;$i++){
    if(exists $r{$i}){
        print $i."\t".$r{$i}."\n";
    }else{
        print $i."\t"."0\n";
    }
}
print STDERR $_."\n" for sort keys %r;
exit;
