#! perl

use strict;
use warnings;

print STDERR "This Script is used for gene number histogram\n";

open IN,'<',shift;

my %h;

while(<IN>){

    my @line = split/\s+/,$_;
    $h{$line[2]} = $line[5];
}

close IN;

open IN2,'<',shift;

my $window = shift;

my %h2;

while(<IN2>){
    my @line = split/\t/,$_;
    push @{$h2{$line[0]}}, $line[1];
}

close IN2;

for my $key (sort keys %h){
    
    my $length = $h{$key};
    my $count = 0;
    
    my @m = @{$h2{$key}};
    
    while($length > 0){
        
        my $j = 1;
        my $count2 = 0;
        $j = 2 if $length < $window;
        #print "$length\n";
        my $start = ($count * $window);
        my $end = ($j == 1)?(($count+1) * $window):$length+$start;
        for my $v(@m){
            if($v >= $start && $v < $end){
	$count2 += 1;
            }
        }
        print "$key\t$start\t$end\t$count2\n";
        $count += 1;
        $length = $length - $window;
       
    }
    
}
