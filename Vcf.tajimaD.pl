#! perl

use warnings;
use strict;
use File::Basename;

my $cut = 10;

my $pop1 = shift or die "need pop1 \n";
my $pop2 = shift or die "need pop2 \n";
my $vcf = shift or die "need vcf";
(my $p1_n = basename $pop1) =~ s/(.*)\..*/$1/;
(my $p2_n = basename $pop2) =~ s/(.*)\..*/$1/;

print STDERR "###   enter your window\n";

chomp(my @a = <STDIN>);

for my $a1 (@a){
    (my $w_name = ($a1/1000)."K");
    my $o = "$w_name";
    `vcftools --gzvcf $vcf --keep $pop1 --TajimaD $a1 --out TajimaD.$p1_n.$o`;
    `vcftools --gzvcf $vcf --keep $pop2 --TajimaD $a1 --out TajimaD.$p2_n.$o`;
    my $o_prefix = "$o.Tajima.D";
    my @file = grep {/$o_prefix$/} `ls ./`;
    for my $f(@file){
        chomp $f;
        $f =~ /TajimaD\.(.*)\.$o/;
        my $p = $1;
        #print $p;exit;
        &phase($f,$p);
    }
    `cat *phase > $p1_n.$p2_n.tajimaD`;
    &plot("$p1_n.$p2_n.tajimaD");
}

sub phase{
    my $fi = shift @_;
    my $p = shift @_;
    open IN,'<',$fi;
    open O,'>',"$fi.phase";
    readline IN;
    while(<IN>){
        chomp;
        my @l = split/\t/;
        next if $l[2] < $cut;
        next if $l[3] eq "nan";
        print O $_."\t$p\n";
    }
    close IN;
    close O;
}

sub plot{
    my $f = shift @_;
    open R,'>',"$f.R";
    print R "library(ggplot2)
data = as.data.frame(read.table(\"$f\"))
colnames(data) = c(\"Chr\",\"start\",\"num\",\"TajimaD\",\"g\")
median.quartile <- function(x)\{
  out <- quantile(x, probs = c(0.25,0.5,0.75))
  names(out) <- c(\"ymin\",\"y\",\"ymax\")
  return(out)
\}
median.for.violin <- function(x){
  out <- quantile(x, probs = c(0.5))
  names(out) <- c(\"y\")
  return(out)
}

a = ggplot(data=data, aes(x=g,y=TajimaD))+
  geom_violin(aes(fill=g))+theme_bw()+
  geom_boxplot(width=0.08,position=position_dodge(0.9),fill=\"white\")+
  scale_fill_manual(
    #values = c(\"#1b86ee\",\"#ee0000\")
    values = c(\"#fb8072\",\"#80b1d3\")
  )+
  scale_y_continuous(
    breaks = seq(-3,5,1),limits = c(-3,5)
  )
  #stat_summary(fun.y=median.quartile,geom='line')+
  #stat_summary(fun.y=median.for.violin,geom='point')
ggsave(\"$f.pdf\",a,width = 4,height = 4)\n";    
    `Rscript $f.R`;
}
