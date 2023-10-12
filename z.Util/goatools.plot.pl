#! perl

use warnings;
use strict;
use File::Basename;

my $f = shift or die"$!";
(my $n = basename $f) =~ s/(.*?)\..*/$1/;
print "#! Rscript
library(tidyverse)
dataA <- as.data.frame(read_delim(\"$f\",delim = \"\\t\",col_names = c(\"go_class\",\"description\",\"ratio\",\"count\",\"padj\")))
dataA\$y<-factor(dataA\$description,levels = rev(dataA\$description))
dataA\$x=-(log10(dataA\$padj))
a <- ggplot(dataA,aes(ratio,y))+
  geom_point(aes(size=count,color=-log10(dataA\$padj),shape=go_class))+
  scale_color_gradient(low = \"blue\", high = \"red\")+ 
  labs(color=expression(-Log.P.value.),x=\"Gene Ratio\",y=\"\",title=\"$n\")+
  theme_bw()+
  theme(axis.line = element_line(colour = \"black\"), 
        axis.text = element_text(color = \"black\",size = 14),
        legend.text = element_text(size = 14),
        legend.title=element_text(size=14),
        axis.title.x = element_text(size = 14))+
  scale_size_continuous(range=c(4,8))
ggsave(\"$n.goplot.png\",a,width=10,height=8)
"
