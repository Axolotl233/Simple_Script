#! perl

use warnings;
use strict;

my $dir = shift;
chomp($dir);
my @gffs=<$dir/*.gff>;

for my $gff (sort{$a cmp $b } @gffs){
    open IN,'<',$gff or die "$!";
    my %h;
    my $method;
    while(<IN>){
        next if /^#/;
        (my $contig,$method) = (split/\t/,$_)[0,1];
        $h{$contig} .= $_;
    }
    `mkdir split_gff` if (! -e "split_gff");
    
    foreach my $k (sort {$a cmp $b} keys %h){
        open OUT,'>>',"split_gff/$k.gff3";
        print OUT $h{$k};
        close OUT;
    }
}
