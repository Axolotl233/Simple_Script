use strict;
use warnings;

my $in=shift;
my $out="$in.plot";
my $rscript="$out.R";
my %h;
open (F,"$in")||die"$!";
while (<F>) {
    chomp;
    next if /^FID1/;
    my @a=split(/\s+/);
    if($a[7]<=0.0442){
        $a[7]=0;
    }elsif($a[7]>0.0442 && $a[7]<=0.0884){
        $a[7]=1;
    }elsif($a[7]>0.0884 && $a[7]<=0.177){
        $a[7]=2;
    }elsif($a[7]>0.177 && $a[7]<=0.354){
        $a[7]=3;
    }elsif($a[7]>0.354){
        $a[7]=4;
    }

    $h{$a[0]}{$a[2]}=$a[7];
    $h{$a[2]}{$a[0]}=$a[7];
}
close F;
open (O,">$out");
print O" \t",join("\t",sort keys %h),"\n";
foreach my $k1(sort keys %h){
    print O "$k1";
    foreach my $k2(sort keys %h){
        if(exists $h{$k1}{$k2}){
            print O "\t$h{$k1}{$k2}";
        }else{
            print O "\t0";
        }
    }
    print O "\n";
}
close O;
open (O1,">$rscript");
print O1 "library(pheatmap)
b=read.table(\"$out\")
b=as.matrix(b)
pdf(\"$out.pdf\",width=15,height=15)
pheatmap(b,cluster_rows=0,cluster_cols=0,color=c(\"white\",\"#b0e0e6\",\"#6a5acd\",\"#0000cd\",\"#a020f0\"),border_color=\"#ebebeb\")
dev.off()
";
close O1;
