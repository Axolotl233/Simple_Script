#!/usr/bin/perl
use strict;
use warnings;

my $indir=shift or die "give a dir like this 'annotation_v2/02.prediction_output_05.04/gff/homolog/Ath.pep.final.fasta'\n";
my @in;
if (-d $indir){
    @in=<$indir/*gff*>;
}else{
    @in=($indir);
}

my %gff;
my $line=0;
for my $in (@in){
    open (F,"$in");
    while (<F>) {
        chomp;
        next if /^#/;
        next if /^\s*$/;
        my @a=split(/\t/,$_);
        $line++;
	next if (! $a[8]);
	$a[8]=~/ID=([^;]+);/;
	my $gene=$1;
	my $k="$a[0]_$a[8]";
	($gff{$k}{$line}{start},$gff{$k}{$line}{end})=sort{$a<=>$b} ($a[3],$a[4]);
    }
    close F;
}
my %len;
for my $k1 (sort keys %gff){
    my @k2=sort{$a<=>$b} keys %{$gff{$k1}};
    $len{gene}{num}++;
    my @genelen=sort{$a<=>$b} ($gff{$k1}{$k2[-1]}{start},$gff{$k1}{$k2[-1]}{end},$gff{$k1}{$k2[0]}{start},$gff{$k1}{$k2[0]}{end});
    $len{gene}{len} += ($genelen[-1] - $genelen[0] + 1);
    $len{cds}{num}++;
    for my $k2 (@k2){
        my $tmplen=abs($gff{$k1}{$k2}{end} -$gff{$k1}{$k2}{start}) + 1;
        $len{cds}{len} += $tmplen;
        $len{exon}{num}++;
        $len{exon}{len} += $tmplen;
    }
    if (scalar(@k2)>1){
        for (my $i=0;$i<(scalar(@k2)-1);$i++){
            my $j=$i+1;
            my @intronlen=sort{$a<=>$b} ($gff{$k1}{$k2[$i]}{start},$gff{$k1}{$k2[$i]}{end},$gff{$k1}{$k2[$j]}{start},$gff{$k1}{$k2[$j]}{end});
            #my @intronlen1=sort{$a<=>$b} ($gff{$k1}{$k2[$i]}{start},$gff{$k1}{$k2[$j]}{start});
            #my @intronlen2=sort{$a<=>$b} ($gff{$k1}{$k2[$i]}{end},$gff{$k1}{$k2[$j]}{end});
            $len{intron}{num}++;
            $len{intron}{len} += ($intronlen[2] - $intronlen[1] - 1);
            #print $intronlen[2] - $intronlen[1] + 1,"\t$k1\n";
            
        }
    }
}

#open (O,"> $indir.gene.stats")||die"$!";
$indir=~/([^\/]+)$/;
my $tool=$1;
print  "tools\tTotal_Genes_Predicted\tAverage_Gene_Length_(bp)\tAverage_CDS_Length_(bp)\tAverage_Exons_per_Gene\tAverage_Exon_Length_(bp)\tAverage_Intron_Length_(bp)\n";
print  "$tool\t$len{gene}{num}\t",$len{gene}{len}/$len{gene}{num},"\t",$len{cds}{len}/$len{cds}{num},"\t",$len{exon}{num}/$len{gene}{num},"\t",$len{exon}{len}/$len{exon}{num},"\t",$len{intron}{len}/$len{intron}{num},"\n";
#close O;
