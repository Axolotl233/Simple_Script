#! perl

use warnings;
use strict;
use Bio::SeqIO;

my $window =shift;

my $seqio_obj = Bio::SeqIO -> new (-file => shift,-format => "fasta");

while(my $seq_obj = $seqio_obj -> next_seq){
    my $name = $seq_obj -> display_id;
    my $seq = $seq_obj -> seq;
    my $length = $seq_obj -> length;
    my $count = 0;
    while($length){
        my $count2 = 0;
        unless($window > $length){
            my $start = ($count * $window)+1;
            my $end = (($count+1) * $window);
            my $line = substr($seq,$start,$window);
            $count2 = $line =~ s/(G|C)/N/ig;
            print "$name\t".$start;
            print "\t".$end."\t";
            my $cg = ($count2*100)/$window;
            printf "%.2f",$cg;
            print "\n";
            $length = $length - $window;
            $count += 1
        }else{
            my $start = ($count*$window)+1;
            my $end = $start+$length;
            my $line = substr($seq,$start,$length);
            $count2 = $line =~s/[GC]/N/ig;
            print "$name\t".$start;
            print "\t".($end)."\t";
            my $cg = ($count2*100)/$length;
            printf "%.2f",$cg;
            print "\n";
            $length = 0;
        }
    }
}
