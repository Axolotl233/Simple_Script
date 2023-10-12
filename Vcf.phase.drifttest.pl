#! perl

use warnings;
use strict;
use File::Basename;

my $ref = shift or die "need ref";
my $vcf = shift or die "nedd vcf";

open IN,'<',"$ref";
my %r;
my $c1 = 0;
my $c2 = 0;
my %t;
my %y;
while(<IN>){
    chomp;
    my @l = split/\t/;
    push @{$r{$l[1]}}, $l[0];
    $c1 += 1;
    $t{$l[0]} = 1;
}
close IN;

(my $vcf_n = basename $vcf) =~ s/\..*//;
my $vcf_d = dirname $vcf;
my $out = "$vcf_d/$vcf_n.data.txt";
my $out2 = "$vcf_d/$vcf_n.atlas.txt";
my @head;push @head, 0..8;
my %h;
open IN,'<',$vcf or die "$!";
while(<IN>){
    chomp;
    next if /^##/;
    if(/^#C/){
        my @line = (split/\t/,$_);
        for(my $i = 9;$i< @line;$i += 1){
            push @head, $line[$i];
        }
    }else{
        $c2 += 1;
        my @line = split/\t/,$_;
        $y{$c2} = "$line[0]\t$line[1]\n";
        D:for(my $i = 9;$i< @line;$i += 1){
            next D if !exists $t{$head[$i]};
            if(/^\./){
	push @{$h{$head[$i]}},"-9";
            }else{
	my @info = split/:/,$line[$i];
	if ($info[0] eq "./."){
	    push @{$h{$head[$i]}},"-9";
	}elsif($info[0] =~ /0[\/\|]1/){
	    push @{$h{$head[$i]}},"1";
	}elsif($info[0] =~ /1[\/\|]0/){
	    push @{$h{$head[$i]}},"1";
	}elsif($info[0] =~ /0[\/\|]0/){
	    push @{$h{$head[$i]}},"0";
	}elsif($info[0] =~ /1[\/\|]1/){
	    push @{$h{$head[$i]}},"2";
	}else{
	    print "$line[0],$line[1],unexcept genotype\n";
	    exit;
	}
            }
        }
    }
}
close IN;
open O,'>',$out;
print O "$c1\n$c2\n";
for my $k (sort {$a <=> $b} keys %r){
    for my $s (@{$r{$k}}){
        print O "$k";
        print O "\t$_" for @{$h{$s}};
        print O "\n";
    }
}
print O "\n";

open O2 ,'>',$out2;
print O2 "$_\t$y{$_}" for sort{$a <=>$b} keys %y;
close O2;
