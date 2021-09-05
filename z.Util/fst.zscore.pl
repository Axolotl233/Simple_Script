#! perl

use warnings;
use strict;
use File::Basename;
use List::Util qw(sum);
use Statistics::Distributions;

my $f = shift or die "need phased fst file\n";
my $f2 = shift or die "need out name\n";
my $stat = shift or die "need stat file\n";
my $color = shift or die "need color file\n";
my $coord = shift or die "need chr coord file\n";
my $windth = shift;
my $height = shift;

open IN,'<',$stat or die "$!";
chomp(my $stat_line = readline IN);
close IN;
open IN,'<',$coord;
chomp(my $cc = readline IN);
chomp(my $cn = readline IN);
close IN;

(my $mean,my $var,my $line) = (split/\s+/,$stat_line)[1,2,3];
print "$f\t$mean\t$var\t$line\n";
&z_score($f,$mean,$var,$f2);
my %color_hash = &get_color($color);
my @a = sort {$a cmp $b} keys %color_hash;
my @b;
for my $e(@a){
    push @b, "\"$color_hash{$e}\"";
}
my $sb = join",",@b;
&z_score_p($f2);
&z_filter($f2,6,0.01);
&z_filter($f2,7,0.005);
&z_filter($f2,8,0.001);

sub z_score{
    my $file = shift @_;
    my $avg = shift @_;
    my $var = shift @_;
    my $name = shift @_;
    $var = sqrt($var);
    open I,'<',$file or die"$!";
    my %hash;
    my $i = 0;
    while(<I>){
        chomp;
        my @line = split/\s+/;
        my @t = @line[0..2];
        push @t, $line[4];
        push @t, $line[6];
        $hash{$i} = \@t;
        $i += 1;
        #print join",",@t;
        #print "\n";
    }
    #exit;
    close I;
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
    open OUT,'>',$name;
    #for my $k (sort keys %hash){
    #    print $k.":".${$hash{$k}}[1]."\n";
    #}
    #exit;
    print OUT "Chr\tStart\tEnd\tWeight_Fst\tclass\tzscore\tZ-001\tZ-0005\tZ-0001\tP\n";
    for my $uniKey (sort {$a <=> $b} keys %hash){
        my $print_temp=join("\t",@{$hash{$uniKey}})."\t".(Statistics::Distributions::uprob($hash{$uniKey}->[5]));
        print OUT "$print_temp\n";
    }
    close OUT;
}
sub z_score_p{
    my $f = shift @_;
    open R,'>',"$f.zscore_plot.R";
    print R "library(ggplot2)
data <- read.table(\"$f\",header = T)
data\$n = 200:(nrow(data) + 199 )
data\$li = c(\"l\")
data\$lp = -log10(data\$P)
cut = qnorm(0.99)
a <- ggplot(data)+
  geom_point(aes(x = n,y= zscore,color = class),size = 0.75)+
  theme_classic()+
  scale_color_manual(
    values = c($sb)
              )+
  theme(legend.position = \"none\") +
  labs(x = NULL)+
  scale_x_continuous(breaks = c($cc),labels = c($cn))+
  geom_hline(aes(yintercept = cut,linetype = li),colour=\"grey50\",size = 0.4,alpha = 2/3)+
  scale_linetype_manual(values=c(\"dashed\"))
ggsave(\"$f.point.pdf\",a,width = 6,height = 2.5)
b <- ggplot(data)+
  geom_point(aes(x = n,y= lp,color = class),size = 0.75)+
  theme_classic()+
  scale_color_manual(
    values = c($sb)
              )+
  #scale_color_manual(
  #  values = c(\"#66c2a5\",\"#fdc086\",\"#8da0cb\",\"#e78ac3\")
  #            )+
  theme(legend.position = \"none\") +
  labs(x = NULL)+
  scale_x_continuous(breaks = c($cc),labels = c($cn))+
  geom_hline(aes(yintercept = cut,linetype = li),colour=\"grey50\",size = 0.4,alpha = 2/3)+
  scale_linetype_manual(values=c(\"dashed\"))
ggsave(\"$f.point.logp.pdf\",b,width = $windth,height = $height)";
    `Rscript $f.zscore_plot.R`;
    close R;
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
