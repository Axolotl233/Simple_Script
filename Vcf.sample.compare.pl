#! perl

use strict;
use warnings;
my $f = shift or die "USAGE : perl $0 \$phased_vcf\n";
my @sample;
my %h;

open IN,"zcat $f|";
while(<IN>){
    chomp;
    next if /^##/;
    if(/^#C/){
        my @l = split/\t/,$_;
        for(my $i = 9;$i < @l;$i++){
            push @sample ,$l[$i];
            
        }
        next;
    }
    my @l =split/\t/;
    for(my $i = 9;$i < @l;$i++){
        my $j = $i-9;
        my @gt = split/\|/,$l[$i];
        @gt = sort{$a <=> $b} @gt;
        my $tmp = join"-",@gt;
        $h{$l[0]}{$l[1]}{$sample[$j]} = $tmp;
    }
}
close IN;
my %s;
for my $e1 (@sample){
    for my $e2(@sample){
        next if $e1 eq $e2;
        (my $tmp1,my $tmp2) = sort{$a cmp $b} ($e1,$e2);
        $s{"$tmp1|$tmp2"} += 1;
    }
}
for my $k(sort {$a cmp $b} keys %s){
    (my $a1,my $a2) = split/\|/,$k;
    my $same = 0;
    my $diff = 0;
    for my $k1(sort {$a cmp $b}keys %h){
        for my $k2(sort {$a <=> $b} keys %{$h{$k1}}){
            if($h{$k1}{$k2}{$a1} eq $h{$k1}{$k2}{$a2}){
                $same += 1
            }else{
                $diff += 1;
            }
        }
    }
    print "$k\t$same\t$diff\n";
}
