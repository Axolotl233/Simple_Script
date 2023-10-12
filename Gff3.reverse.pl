#! perl

use warnings;
use strict;

if(scalar @ARGV != 3){
    print STDERR "USAGE : perl $0 \$chr_len \$rev_chr \$ori_gff\n";
    exit;
}

my $len_f = shift;
my $rev_f = shift;
my $gff_f = shift;

open IN,'<',$len_f;
my %r1;my %r2;
while(<IN>){
    chomp;
    my @l = split/\t/;
    $r1{$l[0]} = $l[1];
}
close IN;

open IN,'<',$rev_f;
while(<IN>){
    chomp;
    $r2{$_} = 1;
}
close IN;

open IN,'<',$gff_f;
my $last_gene;
my @p;
my %h;
D:while(<IN>){
    chomp;
    my @l = split/\t/;
    if($l[2] eq "gene"){
        $l[8] =~ /ID=(.*?);?/;
        $last_gene = $l[8];
        push @p, $_;
        last D;
    }
}

while(<IN>){
    chomp;
    my @l = split/\t/;
    if($l[2] eq "gene"){
        @{$h{$last_gene}} = @p;
        @p = ();
        $l[8] =~ /ID=(.*?);?/;
        $last_gene = $l[8];
        push @p,$_;
    }else{
        push @p,$_;
    }
}
@{$h{$last_gene}} = @p;
close IN;
for my $g(sort {$a cmp $b} keys %h){
    my @tmp = @{$h{$g}};
    my @pp = @tmp;
    my $n = scalar @tmp - 1;
    my $d = 0;
    for (my $i = 0;$i <= $n;$i++){
        my @l = split/\t/, $tmp[$i];
        if ( !exists $r2{$l[0]}){
            $pp[$i] = $tmp[$i];
        }else{
            my $n_e = $r1{$l[0]} - $l[3] + 1;
            my $n_s = $r1{$l[0]} - $l[4] + 1;
            $l[3] = $n_s;
            $l[4] = $n_e;
            $l[6] = $l[6] eq "+"?"-":"+";
            $tmp[$i] = join"\t",@l;
            if($l[2] eq "gene"){
	$pp[0] = $tmp[$i];
            }elsif($l[2] eq "mRNA") {
	$pp[1] = $tmp[$i];
            }elsif($l[2] eq "exon") {
	$pp[$n-$d-1] = $tmp[$i];
            }elsif ($l[2] eq "CDS") {
	$pp[$n-$d] = $tmp[$i];
	$d = $d+2;
            }
        }
    }
    print join"\n",@pp;
    print "\n";
}
