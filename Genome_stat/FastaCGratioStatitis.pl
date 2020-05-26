#! perl

use warnings;
use strict;

my ($count_A,$count_T,$count_C,$count_G,$count_N);

open IN,'<',$ARGV[0];

while(<IN>){
    chomp;
    next if $_ =~/^>/;
    $count_A=$count_A+($_=~tr/Aa//);
    $count_T=$count_T+($_=~tr/Tt//);
    $count_G=$count_G+($_=~tr/Gg//);
    $count_C=$count_C+($_=~tr/Cc//);
    $count_N=$count_N+($_=~tr/Nn//);
}
my $total = ($count_A+$count_T+$count_G+$count_C+$count_N);
print"total:".($count_A+$count_T+$count_G+$count_C+$count_N)."\nA:$count_A\t".(($count_A/$total)*100)."%\nT:$count_T\t".(($count_T/$total)*100)."%\nC:$count_C\t".(($count_C/$total)*100)."%\nG:$count_G\t".(($count_G/$total)*100)."%\nN:$count_N\n";
print "CG%:".($count_G+$count_C)/($count_A+$count_T+$count_G+$count_C)."\n";
