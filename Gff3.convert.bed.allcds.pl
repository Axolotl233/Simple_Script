#! perl

use strict;
use warnings;

my $f = shift;
my $class = shift;
$class //= "cds";
my $up_down = shift;
$up_down //= 0;
if($class eq "cds"){
    &get_cds($f);
}elsif($class eq "gene"){
    &get_gene($f,$up_down);
}
sub get_gene{
    my $g = shift @_;
    my $ex = shift @_;
    open (F,$g)||die"$!";
    open (O,">$g.mrna.bed")||die "$!";
    while (<F>){
        chomp;
        my @a=split(/\s+/,$_);
        if ($a[2] eq 'mRNA'){
            my $s = ($a[3] - $ex < 0)? 0 : $a[3] - 2000;
            my $e = $a[4] + $ex;
            $a[8]=~/ID=([^;]+);.*?;?Parent=([^;]+)/;
            print O "$a[0]\t$2\t$1\t$s-$e\n";
        }
    }
    close O;
}

sub get_cds{
    my $g = shift @_;
    my %gff;
    open (F,$g)||die"$!";
    while (<F>) {
        chomp;
        my @a=split(/\s+/,$_);
        if ($a[2] eq 'mRNA'){
            $a[8]=~/ID=([^;]+);.*?;?Parent=([^;]+)/;
            my ($trans,$gene)=($1,$2);
            $gff{gene}{$a[0]}{$gene}{$trans}=$a[4]-$a[3]+1;
        }elsif ($a[2] eq 'CDS') {
        $a[8]=~/ID=([^;]+);Parent=([^;]+)/;
        my ($CDS,$trans)=($1,$2);
        $gff{CDS}{$trans}{$a[3]}=$a[4];
    }
    }
    close F;
    open(O,">$g.CDS.bed");
    for my $chr (sort keys %{$gff{gene}}){
        for my $gene (sort keys %{$gff{gene}{$chr}}){
            my @trans=sort{$gff{gene}{$chr}{$gene}{$b} <=> $gff{gene}{$chr}{$gene}{$a}} keys %{$gff{gene}{$chr}{$gene}};
        my $trans=$trans[0];
            print O "$chr\t$gene\t$trans\t";
            my @pos;
            for my $s (sort{$a<=>$b} keys %{$gff{CDS}{$trans}}){
	push @pos,"$s-$gff{CDS}{$trans}{$s}";
            }
            print O join(";",@pos),"\n";
        }
    }
    close O;
}
