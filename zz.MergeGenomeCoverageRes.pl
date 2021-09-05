#! perl

use warnings;
use strict;

my $jud = shift;
$jud //= 0;

my @files = sort{$a cmp $b }grep{/\.GCstat/} `ls `;
my $p;
for my $f (@files){
    chomp $f;
    open IN,'<',$f;
    my $first = readline IN;
    chomp $first;
    if($jud == 0){
        $p = $first."\t"."id\n";
		$jud += 1;
    }
    while(<IN>){
        chomp;
        my @l = split/\t/;
        $l[0] =~ s/(.*?)\..*/$1/;
        push @l , $f;
        my $tmp = join"\t",@l;
        $p .= $tmp."\n";
    }
    close IN
}
print $p;
