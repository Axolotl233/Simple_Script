#! perl

use warnings;
use strict;
use List::Util qw(max min);

my $vcf = shift;
open IN,"zcat $vcf |";
my %h;
my $pre = "NA";
while(<IN>){
    next if /^#/;
    my @line = split/\t/;
    $h{$line[0]}{$line[1]} = 1;
}
close IN;

my %r;
my %c;
for my $c (sort {$a cmp $b} keys %h){
    my @in = sort {$a <=> $b} keys %{$h{$c}};
    for(my $i = 1 ;$i < $#in;$i += 1){
        my $pre = $in[$i-1];
        my $next = $in[$i+1];
        my @r;
        push @r ,$in[$i]-$pre;
        push @r ,$next-$in[$i];
        my $min = min(@r);
        if($min < 201){
            if($r[0] >= $r[1]){
	$r{$min} += 1;
	$c{"$in[$i]-$next"} = 1
            }else{
	if(! exists $c{"$pre-$in[$i]"}){
	    $r{$min} += 1;
	}
            }
        }else{
            if($r[0] >= $r[1]){
	$r{200} += 1;
	$c{"$in[$i]-$next"} = 1
            }else{
	if(! exists $c{"$pre-$in[$i]"}){
	    $r{200} += 1;
	}
            }
        }
    }
}
print $_."\t".$r{$_}."\n" for sort{$a <=> $b} keys %r;
