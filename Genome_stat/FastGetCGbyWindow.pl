#! perl

use warnings;
use strict;
use Bio::SeqIO;

my $window =shift;
my $file = shift;
my $seqio_obj = Bio::SeqIO -> new (-file => $file,-format => "fasta");

while(my $seq_obj = $seqio_obj -> next_seq){
    my $name = $seq_obj -> display_id;
    my $seq = $seq_obj -> seq;
    my $length = $seq_obj -> length;
    my $count = 0;
    DO:while($length){
        my $count2 = 0;
        unless($window > $length){
            my $start = ($count * $window)+1;
            my $end = (($count+1) * $window);
            #print "$start,$end\n";
            my $line = substr($seq,$start,$window);
            #print length $line;
            $line =~ s/N//ig;
            my $line_length = length $line;
            $count2 = $line =~ s/(G|C)/N/ig;
            print "$name\t".$start;
            print "\t".$end."\t";
            my $cg = ($count2*100)/$line_length;
            #print "$count2\n";
            printf "%.2f",$cg;
            print "\n";
            $length = $length - $window;
            $count += 1
        }else{
            my $start = ($count*$window)+1;
            my $end = $start+$length;
            my $line = substr($seq,$start,$length);
            $line =~ s/N//ig;
            $count2 = $line =~s/[GC]/N/ig;
            my $line_length = length $line;
            last DO if $line_length == 0;
            print "$name\t".$start;
            print "\t".($end)."\t";
            #next unless ($line_length);
            my $cg = ($count2*100)/$line_length;
            printf "%.2f",$cg;
            print "\n";
            $length = 0;
        }
    }
}
