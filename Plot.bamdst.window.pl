#! perl

use warnings;
use strict;
use MCE::Loop;
use File::Basename;
use Getopt::Long;

print STDERR "USAGE : perl $0 \$chr_list \$dir_region.tsv [\$dir_gypsy \$dir_copia]\n";

my $chr_list = shift or die "need chr_list";
my $dir_region = shift or die "need dir_region";
my $y_lim = shift;
$y_lim //= 150;
my $dir_copia = shift;
my $dir_gypsy = shift;
my $j = 1;
if($dir_copia || $dir_gypsy){
    $j = 2;
}

my $r_w = 10000;
my $thread = 15;
open IN,'<',"$chr_list";
my %chr;
while(<IN>){
  chomp;
  $chr{$_} = 1;
}
close IN;
#my $out = "out";
#mkdir $out if !-e $out;
MCE::Loop::init {max_workers => $thread, chunk_size => 1};
mce_loop {&run($_)} sort {$a cmp $b} keys %chr;

sub run{
    my $n = shift @_;
    
  my %h = &read_depth("$dir_region/$n.split.file");
  if($dir_copia){
      %h = read_repeat("$dir_copia/$n.split.file",\%h,"copia");
  }
   if($dir_gypsy){
      %h = read_repeat("$dir_gypsy/$n.split.file",\%h,"gypsy");
  }
  open O,'>',"$dir_region/$n.stat.tmp.txt";
  for my $k (keys %h){
    #print O $_ for @{$h{$k}};
    print O join"\t",@{$h{$k}};print O "\n";
  }
  close O;
  #chdir($out);
  `sort -k5,5 -k2,2n -k3,3n $dir_region/$n.stat.tmp.txt > $dir_region/$n.stat.txt`; 
  `rm -fr $dir_region/$n.stat.tmp.txt`;
  &plot("$dir_region/$n.stat.txt");
}

sub read_repeat{
  my $f = shift@_;
  my $ref = shift @_;
  my %h = %{$ref};
  my $b = shift @_;
  open I,'<',"$f" or die "$!";
   while(<I>){
      chomp;
      my @l = split/\t/,$_;
      $l[3] = $l[3] * 0.6;      
      my $n = ($l[2]-$l[1])/$r_w;
      my @a = $l[1];
      for (my $i = 1;$i<$n;$i+=1){
      push @a, $l[1] + $r_w*$i;
      }
      push @a,$l[2];
      for (my $i = 1;$i<@a;$i+=1){
        #print $a[$i-1]."\t".$a[$i];exit;
      next if !exists ($h{"$l[0]-$a[$i-1]-$a[$i]"});
      push @{$h{"$l[0]-$a[$i-1]-$a[$i]"}},$l[3];
      }
   }
   close I;
   return %h;
}

sub read_depth{
    my $f = shift @_;
    my %h;
    open I,'<',"$f" or die "$f";
    my $c = 0;
    while(<I>){
        chomp;
        my @l = split/\t/,$_;
        
        $l[1] = $l[1]-1;
        $l[2] = $l[2] + 1;
        $c += 1;
        my $b = "depth";
        if ($l[3] > 80){
            $l[3] = 80;
        }else{
          $l[3] = $l[3];
        }
        push @{$h{"$l[0]-$l[1]-$l[2]"}} , ($l[0],$l[1],$l[2],$l[3],$c);
    }
    close I;
    return %h;
}

sub plot{
    my $name = shift @_;
    open R,'>',"$name.R";
    (my $n = basename $name) =~ s/(.*?)\..*/$1/;
    print R "rm(list=ls())
library(ggplot2)
library(grid)
data = as.data.frame(read.table(\"$name\"))
l = format((nrow(data)/200) , digit = 2)
l = as.numeric(l)\n";
    if($j == 2){
        print R"colnames(data) = c(\"chr\",\"start\",\"end\",\"value\",\"pos\",\"g\",\"c\")
data\$gypsy = \"gypsy\"
data\$copia = \"copia\"\n";
    }else{
        print R"colnames(data) = c(\"chr\",\"start\",\"end\",\"value\",\"pos\")\n";
    }
    print R"data\$depth = \"depth\"
lpos = data\$pos[nrow(data)]
d_b <- seq(0,lpos,1000)
d_l <- d_b*10000
depth = ggplot(data)+
  geom_bar(aes(x=pos,y=value,fill = depth),stat=\"identity\",position = \"identity\") +
  scale_fill_manual(
    values = c(\"#ec7723\")   
  )+
  labs(y = NULL)+
  scale_x_continuous(breaks = NULL,labels = d_l)+
  scale_y_continuous(breaks = NULL,limits = c(0,100))+
  theme_bw()+
  theme( panel.grid.major = element_blank(),   
         panel.grid.minor = element_blank(),
         #legend.position = \"none\"
  )+
  geom_hline(aes(yintercept = quantile(value,
            probs = c(0.50)),linetype = chr),
            colour=\"firebrick3\",size=0.6,alpha = 2/3)+
  scale_linetype_manual(values=c(\"dashed\"))\n";
    if($j == 2){
        print R "re <- ggplot(data)+
  geom_line(aes(x=pos,y=g,color=gypsy))+
  geom_line(aes(x=pos,y=c,color=copia))+
  scale_x_continuous(breaks = NULL)+
  scale_y_continuous(breaks = NULL,limits = c(0,60))+
  theme_bw()+
  labs(x= NULL,y=NULL,title=\"$n\")+
  theme( panel.grid.major = element_blank(),   
         panel.grid.minor = element_blank(),
         #legend.position = \"none\"
  )

pdf(\"$name.pdf\",width = l,height = 4)
grid.newpage()
pushViewport(viewport(layout = grid.layout(3, 2)))
print(depth, vp = viewport(layout.pos.row = 2:3, layout.pos.col = 1:2))
print(re, vp = viewport(layout.pos.row = 1, layout.pos.col = 1:2))
dev.off()
";
    }else{
        print R "ggsave(\"$name.pdf\",depth,width = l,height = 4)";
    }
    close R;
    `Rscript $name.R`;
}
