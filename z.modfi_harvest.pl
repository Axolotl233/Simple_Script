#! perl

use warnings;
use strict;

my $f2 = shift;

open IN2,'<',$f2;
while(<IN2>){
    chomp;
    my @l = split/\s+/;
    if($l[11] eq "ctg000000"){
        $l[10] = 0;
        print  join" ",@l;;
        print "\n";
        next;
    }
    (my $t = $l[11]) =~ s/ctg0+//;
    $t =~ s/(.*)0/$1/;
    $l[10] = $t;
    print  join" ",@l;
    print "\n";
}
close IN2;
