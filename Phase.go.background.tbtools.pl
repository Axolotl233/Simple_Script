#! perl

use strict;
use warnings;

open IN ,'<',$ARGV[0];
while(<IN>){
    chomp;
    my @go = split /\t/,$_;
    my $id = shift @go;
    my $go = join ',' ,@go;
    #print $go;exit;
    print "$id\t$go\n";
}
