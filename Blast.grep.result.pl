#! perl

use warnings;
use strict;
use Getopt::Long;

my $gene = shift or die "need gene\n";
my $blast = shift or die "need blast\n";
my $max = shift;
$max //= 1;
my %blast = %{&blast_load($blast)};

open IN,'<',$gene;
while(<IN>){
    chomp;
    if(exists $blast{$_}){
        print join "\n",@{$blast{$_}};
        print "\n";
    }
}

sub blast_load{
    my $f = shift @_;
    my %h;
    open IN,'<', $f or die "$!";
    while(<IN>){
        chomp;
        my @l = split/\t/;
        push @{$h{$l[0]}} , [$l[1],$l[-1]];
    }
    close IN;
    %h = &blast_filter(\%h,$max);
    return \%h;
}
sub blast_filter{
    my $ref = shift @_;
    my %h = %{$ref};
    my %p;
    for my $k (keys %h){
        my @a = @{$h{$k}};
        #print $a[1][0];exit;
        @a = sort{${$b}[1] <=> ${$a}[1]} @a;
        my $num = scalar @a;
        if($num >= $max){
            for(my $i = 0;$i <= ($max-1);$i++){
	my $n = @{$a[$i]}[0];
	push @{$p{$k}} , $n;
            }
        }else{
            for(my $i = 0;$i <= ($num-1);$i++){
	my $n = @{$a[$i]}[0];
	push @{$p{$k}} , $n;
            }
        }
    }
    return %p;
}
