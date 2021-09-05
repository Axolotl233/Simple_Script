#!/usr/bin/perl -w
use strict;

my %gff;
my %out;

my $in=shift or die "give the input dir or input gff\n";
my @in;
if (-d $in){
    @in=<$in/*gff*>;
}else{
    @in=($in);
}

for my $ingff (@in){
    open (F,"$ingff");
    while (<F>) {
        chomp;
        next if /^#/;
        next if /^$/;
        my @a=split(/\t/,$_);
        if ($a[2] eq 'gene'){
            $a[8]=~/ID=([^\;]+)/ or die "$_\n";
            $gff{gene}{$a[0]}{$1}{len}=abs($a[4]-$a[3])+1;
        }elsif($a[2] =~ /^mRNA$/i ){
            $a[8]=~/ID=([^\;]+);.*Parent=([^;]+)/ or die "$_\n";
            $gff{gene}{$a[0]}{$2}{mrna}{$1}{len}=abs($a[4]-$a[3])+1;
            $gff{gene}{$a[0]}{$2}{mrna}{$1}{start}=$a[3];
            $gff{gene}{$a[0]}{$2}{mrna}{$1}{end}=$a[4];
        }elsif($a[2] =~ /^CDS$/i ){
            $a[8]=~/ID=([^\;]+);.*Parent=([^;]+)/ or die "$_\n";
            $gff{cds}{$a[0]}{$2}{$a[3]}=$a[4];
        }
    }
    close F;
}

for my $chr (sort keys %{$gff{gene}}){
    for my $geneid (sort keys %{$gff{gene}{$chr}}){
        $out{gene}{num}++;
        my $genelen=$gff{gene}{$chr}{$geneid}{len};
        $out{gene}{len} += $genelen;
        my @mrna=sort{$gff{gene}{$chr}{$geneid}{mrna}{$b}{len} <=> $gff{gene}{$chr}{$geneid}{mrna}{$a}{len}} keys %{$gff{gene}{$chr}{$geneid}{mrna}};
        my $mrna=$mrna[0];
        my @start=sort{$a<=>$b} keys %{$gff{cds}{$chr}{$mrna}};
        if (scalar(@start) == 1){
            $out{cds}{num} ++;
            $out{cds}{len} += abs($gff{cds}{$chr}{$mrna}{$start[0]} - $start[0])+1;
        }elsif(scalar(@start) > 1){
            for (my $i=0;$i<@start;$i++){
	my $j=$i+1;
	$out{cds}{num} ++;
	$out{cds}{len} += abs($gff{cds}{$chr}{$mrna}{$start[$i]} - $start[$i])+1;
	if ($j < @start){
	    my @intron=sort{$a<=>$b} ($start[$i],$gff{cds}{$chr}{$mrna}{$start[$i]},$start[$j],$gff{cds}{$chr}{$mrna}{$start[$j]});
	    $out{intron}{num}++;
	    $out{intron}{len} += $intron[2]-$intron[1]-1;
	}
            }
        }else{
            die "$chr\t$geneid\t:no cds\n";
        }
    }
}

$in=~/([^\/]+)$/;
my $tools=$1;
print "tools\tTotal_Genes_Predicted\tAverage_Gene_Length_(bp)\tAverage_CDS_Length_(bp)\tAverage_Exons_per_Gene\tAverage_Exon_Length_(bp)\tAverage_Intron_Length_(bp)\n";
print "$tools\t$out{gene}{num}\t",$out{gene}{len}/$out{gene}{num},"\t",$out{cds}{len}/$out{gene}{num},"\t",$out{cds}{num}/$out{gene}{num},"\t",$out{cds}{len}/$out{cds}{num},"\t",$out{intron}{len}/$out{intron}{num},"\n";
