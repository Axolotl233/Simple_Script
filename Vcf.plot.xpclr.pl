#! perl

use warnings;
use strict;
use File::Basename;
use List::Util qw(sum);
use Statistics::Distributions;
use Getopt::Long;

(my $xpclr,my $chr,my $color,my $arg_d,my $zsorce,my $plot_windth,my $plot_height);
GetOptions(
           'xpclr=s' => \$xpclr,
           'chr=s' => \$chr,
           'color=s' => \$color,
           'argd=s' => \$arg_d,
           'zscore' => \$zsorce,
           'windth=s' => \$plot_windth,
           'height=s' => \$plot_height
          );

for my $s ($xpclr,$chr){
    if(!$s){
        exit;
    }
}
my $out = $xpclr.".phase";
my $cut = 10;

$color //= "/data/00/user/user112/code/script/z.Util/color.txt";
$arg_d //= 200;
$plot_windth //= 8;
$plot_height //= 2.5;

my $plot_height2 = $plot_height * 2;
my %color_hash = &get_color($color);
my %chr_hash = &get_chr($chr);
my @chr_name;my @chr_coord;

my @a = sort {$a cmp $b} keys %color_hash;
my @b;
for my $e(@a){
    push @b, "\"$color_hash{$e}\"";
}

my $c1 = -1;
my $c2 = 0;
my $interval = 1;
my $coord = 0;

open IN,'<',$xpclr;
readline IN;
open O,'>',$out;
my $last = "NA";
while(<IN>){
    chomp;
    my @l = split/\t/;
    next unless (exists $chr_hash{$l[0]} || $chr eq "NA");
    $l[-2] = 0 if $l[-1] < 0;
    if(scalar @l < 12){
        push @l,(0,0);
    }
    my @t = @l[0,1,2,9,10,11];
    $t[4] = 0 if $t[4] < 0;
    my $a = join"\t",@t;
    if ($last ne $l[0]){
        $last = $l[0];
        if($c1 == ((scalar @a) - 1)){
            $c1 = -1;
        }
        if ($coord == 0){
            $coord += $interval;
        }else{
            $coord += (2* $interval);
        }
        $c2 += (2*$interval) + 1;
        push @chr_name,$l[0];
        push @chr_coord,$c2;
        $c2 = 0;
        $c1 += 1;
        print O $a."\t".$a[$c1]."\t".$coord."\n";
    }else{
        print O $a."\t".$a[$c1]."\t".$coord."\n";
    }
    $coord += 1;
    $c2 += 1;
}
$c2 += (2*$interval) + 1;
push @chr_coord, $c2;
shift @chr_coord;
close O;

@chr_coord = &cal_coord(\@chr_coord);
#map{$_ = "\"$_\""} @chr_coord;
map{$_ = "\"$_\""} @chr_name;
my $cc = join",",@chr_coord;
my $cn = join",",@chr_name;
my $b = join",",@b;
my $res = &plot($out,$arg_d);
(my $mean,my $var) = (split/\s+/,$res)[1,2];
print "Mean : $mean\n Var : $var\n";
open O,'>',"$out.stat";
print O "$res\n";
close O;
open O,'>',"$out.chr_coord.txt";
print O "$cc\n$cn\n";
close O;

if($zsorce){
    &z_score($out,$mean,$var);
}

sub plot{
    my $file = shift @_;
    my $c3 = shift @_;
    my $c4 = $c3 + 1;
    open R,'>',"$file.R" or die "$!";
    print R "library(patchwork)
library(ggplot2)
library(tidyverse)
data <- read.table(\"$file\")
data[,9] = c(\"t\")
colnames(data) <- c(\"chr\",\"start\",\"end\",\"var_num\",\"xpclr\",\"norm_xpclr\",\"class\",\"s\",\"li\")
data\$group <- findInterval(data\$var_num,seq(1,".$c3.",1))
res <- data.frame(i = seq(1,".$c4.",1),s = 0,r=0)
a_s <- sum(data\$var_num)

for(i in seq(1,".$c4.",1)){
  tmp_d <- data[data\$group == i,]
  tmp_s <- sum(tmp_d\$var_num)
  tmp_r <- tmp_s/a_s
  res[i,2] = tmp_s
  res[i,3] = tmp_r
}
res\$c_r <- cumsum(res\$r)
a <- ggplot(res)+
  geom_line(aes(x=i,y=c_r))+
  xlab(\"var_num_in_window\")+
  ylab(\"cumulative_percentage\")+
  scale_x_continuous(breaks = seq(0,".$c3.",10))+
  scale_y_continuous(breaks = seq(0,1,0.1))+
  theme_bw()
b <- ggplot(data,aes(x=var_num))+
  geom_histogram(binwidth = 1,colour= \"black\",position = \"identity\",boundary=0)+
  scale_x_continuous(breaks = seq(0,50,5),limits = c(0,50))+
  theme_bw()
c = a/b
ggsave(\"$file.density.snp_num.pdf\",c,width = $plot_windth,height = $plot_height2)
datad = data[data\$xpclr != 0,]
d <- ggplot(datad,aes(x=xpclr))+
  geom_histogram(binwidth = 0.1,colour= \"black\",position = \"identity\",boundary=0)+
  theme_bw()+
  theme(
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank()
  )+
  scale_x_continuous(
    breaks = c(
      seq(0,20,5),
      round(as.numeric(quantile(data\$xpclr,probs = c(0.99))),2),
      round(as.numeric(quantile(data\$xpclr,probs = c(0.95))),2)
      )
  )+
  geom_vline(aes(xintercept = quantile(data\$xpclr,probs = c(0.99))),colour=\"firebrick3\",size=0.4,alpha = 2/3,linetype=\"dashed\")+
  geom_vline(aes(xintercept = quantile(data\$xpclr,probs = c(0.95))),colour=\"navy\",size=0.4,alpha = 2/3,linetype=\"dashed\")
ggsave(\"$file.density.xpclr_value.pdf\",d,width = $plot_windth,height = $plot_height2)
e <- ggplot(data)+
  geom_point(aes(x = s,y= xpclr,color = class),size = 0.75)+
  theme_classic()+
  scale_color_manual(
    values = c($b)
              )+
  theme(
      legend.position = \"none\"
  ) +
  labs(x = NULL)+
  scale_x_continuous(breaks = c($cc),labels = c($cn))+
  scale_y_continuous(breaks = seq(0,15,3))+
  ylab(\"xpclr value\")+
  geom_hline(aes(yintercept = quantile(xpclr,probs = c(0.99)),linetype = li),colour=\"firebrick3\",size=0.4,alpha = 2/3)+
  scale_linetype_manual(values=c(\"dashed\"))
ggsave(\"$file.point.pdf\",e,width = $plot_windth,height = $plot_height)
f_mean <- mean(data\$xpclr)
f_var <- var(data\$xpclr)
line <- as.numeric(quantile(data\$xpclr,probs = c(0.99)))
print (c(f_mean,f_var,line))
datatop1 <- data[data\$xpclr > line,]
line <- as.numeric(quantile(data\$xpclr,probs = c(0.95)))
datatop5 <- data[data\$xpclr > line,]
write_tsv(\"$file.top1.xpclr\",x =datatop1)
write_tsv(\"$file.top5.xpclr\",x =datatop5)
";
    close R;
    chomp(my $res = `Rscript $file.R`);
    return $res;
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
        ##chr start end nsnp xpclr class n
        my @t = @line[0..2];
        push @t, $line[4];
        push @t, $line[5];
        $hash{"$line[0]-$line[1]"} = \@t;
    }
    for my $key (keys %hash){
        my $z = ($hash{$key}->[3] - $avg)/$var;
        #if($z < 0){
        #    $z = abs($z);
        #}
        push (@{$hash{$key}} ,$z);
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

    (my $name = $file) =~ s/.phase/.zcore.txt/;
    open OUT,'>',$name;
    print OUT "Chr\tStart\tEnd\txpclr\tclass\tzscore\tZ-001\tZ-0005\tZ-0001\tP\n";
    for my $uniKey (sort { $hash{$a}->[0] cmp $hash{$b}->[0] or $hash{$a}->[1] <=> $hash{$b}->[1] } keys %hash){
        my $print_temp=join("\t",@{$hash{$uniKey}})."\t".(Statistics::Distributions::uprob($hash{$uniKey}->[5]));
        print OUT "$print_temp\n";
    }
    close OUT;
    &zcore_p($name);
    &z_filter($name,6,0.01);
    &z_filter($name,7,0.005);
    &z_filter($name,8,0.001)
}
sub z_filter{
    my $f = shift @_;
    my $i = shift @_;
    my $p = shift @_;
    open O,'>',"$f.$p";
    open IN,'<',$f;
    readline IN;
    while(<IN>){
        my @a = split/\t/;
        my $j = $a[$i];
        print O $_ if ($j == 1);
    }
    close O;
}
sub zcore_p{
    my $f = shift @_;
    print STDERR "###   Plot $f\n";
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
  ylim(0,25)+
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
  ylim(0,25)+
  geom_hline(aes(yintercept = cut,linetype = li),colour=\"grey50\",size = 0.6,alpha = 2/3)+
  scale_linetype_manual(values=c(\"dashed\"))
ggsave(\"$f.point.logp.pdf\",b,width = 12,height = 5)";
    `Rscript $f.R`;
    close R;
}

sub cal_coord{
    my $ref = shift @_;
    my @a = @{$ref} ;#coord;
    my @new;
    for(my $i = 0;$i < @a;$i+=1){
        my @tmp_a = @a[0..$i];
        my $sum = sum(@tmp_a);
        my $tmp_s = int($a[$i]/2);
        $tmp_s = $sum - $tmp_s;
        push @new, $tmp_s;
    }
    return @new;
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
sub get_color{
    my $f = shift @_;
    my %t;
    open IN,'<',$f or die "$!";
    while(<IN>){
        chomp;
        my @line = split/\s+/;
        $t{$line[0]} = $line[1];
    }
    close IN;
    return %t;
}
