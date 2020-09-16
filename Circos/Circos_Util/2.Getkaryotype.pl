#! perl

use warnings;
use strict;
use Bio::SeqIO;

my $seqio_obj = Bio::SeqIO -> new (-file => shift, -format=>"fasta");
my %h;
while(my $seq_obj = $seqio_obj-> next_seq){
    my $id = $seq_obj -> display_id;
    my $length = $seq_obj -> length;
    $h{$id} = $length;
}

my $count = 1;
for my $k (sort {$a cmp $b} keys %h){
    
    print "chr - $k Chr$count 0 $h{$k} chr$count\n";
    $count ++;
}
