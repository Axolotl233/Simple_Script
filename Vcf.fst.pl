#! perl

use warnings;
use strict;
use File::Basename;
use List::Util qw(sum);
use Statistics::Distributions;
use Getopt::Long;
use Cwd;
my $h_dir = getcwd();
(my $pop1,my $pop2,my $run,my $vcf,my $chr);
GetOptions(
           'pop1=s' => \$pop1,
           'pop2=s' => \$pop2,
           'vcf=s' => \$vcf,
           'chr=s' => \$chr,
           'run' => \$run
          );

my %ch;
unless($chr){
    $chr = "NA";
}else{
    %ch = &get_chr($chr);
}

for my $s ($pop1,$pop2,$vcf){
    if(!$s){
        &print_help();
        exit;
    }
}

(my $p1_n = basename $pop1) =~ s/(.*)\..*/$1/;
(my $p2_n = basename $pop2) =~ s/(.*)\..*/$1/;

print STDERR "###   enter your window and step, format : window step\n";
chomp(my @a = <STDIN>);
(my $o1);
if(@a == 0){
    exit;
}

open O,'>',"0.fst_calculate.sh";
for my $a1 (@a){
    my @l = split/\s/,$a1;
    (my $w_name = ($l[0]/1000)."K");
    my $s_name = ($l[1]/1000)."K";
    my $o1 = "Fst.$p1_n\-$p2_n.$w_name.$s_name";
    print O "vcftools --gzvcf $vcf --weir-fst-pop $pop1 --weir-fst-pop $pop2 --fst-window-size $l[0] --fst-window-step $l[1] --out $o1\n";
}
close O;
if($run){
    `sh 0.fst_calculate.sh`;
}
my @files = sort {$a cmp $b} grep {/windowed.weir.fst$/} `ls ./`;
exit if (scalar @files == 0);
print STDERR "###   This script will filter window with \"fst value < 0 and N_VARIANTS < 10\" \n";
for my $f (@files){
    chomp $f;
    `sort -k1,1 -k2,2n -k3,3n $f  > $f.sort`;
    $f .= ".sort";
    &plot_d($f);
    &phase($f);
}
my @files_p = sort{$a cmp $b} grep {/.windowed.weir.class.fst$/} `ls ./`;

for my $f_p (@files_p){
    chomp $f_p;
    print STDERR "###   Plot \"$f_p\"\n";
    (my $name = basename $f_p) =~ s/.windowed.weir.class.fst//;
    my $res = &plot_p($f_p);
    (my $mean,my $var,my $line) = (split/\s+/,$res)[1,2,3];
    print "$name\t$mean\t$var\t$line\n";
    &z_score($f_p,$mean,$var);
    my $z_name = $name.".windowed.weir.z_score";
    &z_score_p($z_name);
    &z_filter($z_name,6,0.01);
    &z_filter($z_name,7,0.005);
    &z_filter($z_name,8,0.001);
}
sub z_filter{
    my $f = shift @_;
    my $i = shift @_;
    my $p = shift @_;
    open O,'>',"$f.$p.fst";
    open IN,'<',$f;
    readline IN;
    while(<IN>){
        my @a = split/\t/;
        my $j = $a[$i];
        print O $_ if ($j == 1);
    }
    close O;
}
sub z_score_p{
    my $f = shift @_;
    open R,'>',"$f.R";
    print R "library(ggplot2)
data <- read.table(\"$f\",header = T)
data\$n = 1:nrow(data)
data\$li = c(\"l\")
data\$lp = -log10(data\$P)
cut = qnorm(0.99)
a <- ggplot(data)+
  geom_point(aes(x = n,y= zscore,color = class),size = 0.75)+
  theme_classic()+
  scale_color_manual(
    values = c(\"#3288bd\",\"#66c2a5\",\"#e6f598\")
              )+
  #scale_color_manual(
  #  values = c(\"#66c2a5\",\"#fdc086\",\"#8da0cb\",\"#e78ac3\")
  #            )+
  theme(legend.position = \"none\") +
  labs(x = NULL)+
  scale_x_continuous(breaks = NULL)+
  ylim(0,15)+
  geom_hline(aes(yintercept = cut,linetype = li),colour=\"grey50\",size = 0.6,alpha = 2/3)+
  scale_linetype_manual(values=c(\"dashed\"))
ggsave(\"$f.point.pdf\",a,width = 12,height = 5)
b <- ggplot(data)+
  geom_point(aes(x = n,y= lp,color = class),size = 0.75)+
  theme_classic()+
  scale_color_manual(
    values = c(\"#3288bd\",\"#66c2a5\",\"#e6f598\")
              )+
  #scale_color_manual(
  #  values = c(\"#66c2a5\",\"#fdc086\",\"#8da0cb\",\"#e78ac3\")
  #            )+
  theme(legend.position = \"none\") +
  labs(x = NULL)+
  scale_x_continuous(breaks = NULL)+
  ylim(0,15)+
  geom_hline(aes(yintercept = cut,linetype = li),colour=\"grey50\",size = 0.6,alpha = 2/3)+
  scale_linetype_manual(values=c(\"dashed\"))
ggsave(\"$f.point.logp.pdf\",b,width = 12,height = 5)";
    `Rscript $f.R`;
    close R;
}

sub z_score{
    my $file = shift @_;
    my $avg = shift @_;
    my $var = shift @_;
    $var = sqrt($var);
    open IN,'<',$file or die"$!";
    my %hash;
    while(<IN>){
        chomp;
        my @line = split/\t/;
        my @t = @line[0..2];
        push @t, $line[4];
        push @t, $line[6];
        $hash{"$line[0]-$line[1]"} = \@t;
    }
    for my $key (keys %hash){
        my $z = ($hash{$key}->[3] - $avg)/$var;
        push (@{$hash{$key}} ,$z );
        if ($z > 2.326){
            push (@{$hash{$key}} ,'1' );
        }else{
            push (@{$hash{$key}} ,'0' );
        }
        if ($z > 2.576){
            push (@{$hash{$key}} ,'1' );
        }else{
            push (@{$hash{$key}} ,'0' );
        }
        if ($z > 3.090){
            push (@{$hash{$key}} ,'1' );
        }else{
            push (@{$hash{$key}} ,'0' );
        }
    }
    (my $name = $file) =~ s/.windowed.weir.class.fst/.windowed.weir.z_score/;
    open OUT,'>',$name;
    print OUT "Chr\tStart\tEnd\tWeight_Fst\tclass\tzscore\tZ-001\tZ-0005\tZ-0001\tP\n";
    for my $uniKey (sort { $hash{$a}->[0] cmp $hash{$b}->[0] or $hash{$a}->[1] <=> $hash{$b}->[1] } keys %hash){
        my $print_temp=join("\t",@{$hash{$uniKey}})."\t".(Statistics::Distributions::uprob($hash{$uniKey}->[5]));
        print OUT "$print_temp\n";
    }
    close OUT;
}

sub plot_d{
    my $file = shift @_;
    open R,'>',"$file.R";
    print R "library(patchwork)
library(ggplot2)
dataraw <- read.table(\"$file\",header = T)
b <- ggplot(dataraw,aes(x=N_VARIANTS))+
  geom_histogram(binwidth = 1,colour= \"black\",position = \"identity\",boundary=0)+
  xlim(0,50)+
  theme_bw()
c <- ggplot(dataraw,aes(x=N_VARIANTS))+
  geom_density()+
  theme_classic()
d = b/c
ggsave(\"$file.density.pdf\",d,width = 12,height = 10)
e <- ggplot(dataraw,aes(x=WEIGHTED_FST))+
  geom_histogram(binwidth = 0.005,colour= \"black\",position = \"identity\",boundary=0)+
  theme_bw()
ggsave(\"$file.density.fst.pdf\",e,width = 12,height = 10)\n";
    close R;
    `Rscript $file.R`;
}

sub plot_p{
    my $file = shift @_;
    open R,'>',"$file.R";
    print R "library(tidyverse)
data <- read.table(\"$file\")
data[9] = c(\"t\")
colnames(data) <- c(\"chr\",\"start\",\"end\",\"num\",\"w_fst\",\"m_fst\",\"class\",\"s\",\"li\")
a <- ggplot(data)+
  geom_point(aes(x = s,y= w_fst,color = class),size = 0.75)+
  theme_classic()+
  scale_color_manual(
    values = c(\"#3288bd\",\"#66c2a5\",\"#e6f598\")
              )+
  #scale_color_manual(
  #  values = c(\"#66c2a5\",\"#fdc086\",\"#8da0cb\",\"#e78ac3\")
  #            )+
  theme(legend.position = \"none\") +
  labs(x = NULL)+
  scale_x_continuous(breaks = NULL)+
  ylim(0,0.5)+
  geom_hline(aes(yintercept = quantile(w_fst,probs = c(0.99)),linetype = li),colour=\"firebrick3\",size=0.6,alpha = 2/3)+
  scale_linetype_manual(values=c(\"dashed\"))
ggsave(\"$file.point.pdf\",a,width = 12,height = 5)
f_mean <- mean(data\$w_fst)
f_var <- var(data\$w_fst)
line <- as.numeric(quantile(data\$w_fst,probs = c(0.99)))
print (c(f_mean,f_var,line))
datatop1 <- data[data\$w_fst > line,]
line <- as.numeric(quantile(data\$w_fst,probs = c(0.95)))
datatop5 <- data[data\$w_fst > line,]
write_tsv(\"$file.top1.fst\",x =datatop1)
write_tsv(\"$file.top5.fst\",x =datatop5)
";
    my $res = `Rscript $file.R`;
    return $res;
}

sub phase{
    my $file = shift @_;
    my @a = ("a","b","c");
    my $c = -1;
    my $d = 200;
    
    (my $name = basename $file) =~ s/\.windowed\.weir\.fst\.sort//;
    open IN,'<',$file;
    open O,'>',$name.".windowed.weir.class.fst";
    my $last = "NA";
    while(<IN>){
        chomp;
        next if /^CHROM/;
        my @l = (split/\t/,$_);
        next unless (exists $ch{$l[0]} || $chr eq "NA");
        $l[4] = 0 if $l[4] < 0;
        unless($l[3] > 10){
            $l[4] = 0;
        }
        my $a = join"\t",@l;
        if ($last ne $l[0]){
            $last = $l[0];
            if($c == 2){
	$c = -1;
            }
            $c += 1;
            print O $a."\t".$a[$c]."\t".$d."\n";
        }else{
            print O $a."\t".$a[$c]."\t".$d."\n";
        }
        $d += 1;
    }
    close O;
    print STDERR "###   \"$file\" phased\n"
}

sub get_chr{
    my $f = shift @_;
    my %t;
    open IN,'<',$f or die "$!";
    while(<IN>){
        chomp;
        my @line = split/\s+/;
        $t{$line[0]} = 1;
    }
    close IN;
    return %t;
}

sub print_help{
print STDERR<<USAGE;
  
  Usage: perl $0 --pop1 <pop1_lst> --pop2 <pop2_lst> --vcf <vcf_file> [--chr <chr_file>]
    
      Options:
      --pop1   A list[one sample one line] contain pop A samples
      --pop2   A list[one sample one line] contain pop B samples
      --vcf    vcf file
      --chr    include chr you want to analysis [chr info in first col space separate file]
       
USAGE
}
