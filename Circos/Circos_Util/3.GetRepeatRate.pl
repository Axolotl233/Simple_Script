#! perl

use warnings;
use strict;

open IN,'<',shift or die "$!" ;

my %h;
while(<IN>){
    next unless /^\w/;
    chomp;
    my @line = split/\t/;
    for(my $i = $line[1];$i<$line[2];$i++){
        $h{$line[0]}{$i} ++;
    }
}

close IN;

open IN,'<',shift or die "$!";

my %h2;

while(<IN>){
    my @line = split/\s+/;
    $h2{$line[2]} = $line[5];
}

my $window = 100000;

for my $key(sort keys %h2){

    my $length = $h2{$key};
    my $count = 0;

    while($length > 0){

        my $j = 1;
        my $count2 = 0;
        $j = 2 if $length < $window;
        
        my $start = ($count * $window);
        my $end = ($j == 1)?(($count+1) * $window):$length+$start;
        for(my $i = $start;$i<$end;$i++){
            $count2 ++ if exists $h{$key}{$i};
        }
        
        my $rate = ($count2 * 100)/$window;
        print "$key\t$start\t$end\t";
        printf "%.2f",$rate;
        print "\n";
        
        $count += 1;
        $length = $length - $window;
    }
}
