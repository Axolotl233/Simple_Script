#! perl

use warnings;
use strict;

my $t = shift;
$t //= 0.354;
my %o; my %p;
my $i = 0;
open IN,'<',"king.kin0";
my @t;
<IN>;
while(<IN>){
    chomp;
    my @a=split(/\s+/);
    my ($id1,$id2)=sort($a[0],$a[2]);
    my $value=$a[-1];
    push @t,"$id1,$id2,$value";
    push @t,"$id2,$id1,$value";
}
close IN;
#print join"\n",sort {$a cmp $b} @t;
#exit;
for my $l (sort {$a cmp $b} @t){
    my ($id1,$id2,$v)=split/,/,$l;
    my $j = 0;
    if(!exists $o{0}){
        $o{0}{$id1} = 1;
        $p{$id1} += 1;
        next;
    }
    if($v > $t){
        for my $n(sort {$a <=> $b} keys %o){
            #print $n;exit;
            if (exists $o{$n}{$id1}){
                $o{$n}{$id2} += 1;
                $p{$id2} += 1;
                $j += 1;
            }
        }
        if($j == 0){
            $i += 1;
            $o{$i}{$id1} += 1;
            $p{$id1} += 1;
        }
    }else{
        if(!exists $p{$id1}){
            $i += 1;
            $o{$i}{$id1} += 1;
            $p{$id1} += 1;
        }
    }
}
for my $n(sort {$a <=> $b} keys %o){
    print "$n:";
    print join ",",sort {$a cmp $b} keys %{$o{$n}};
    print "\n";
}