#! perl

use warnings;
use strict;
use Bio::SeqIO;

my $file = shift;
my $o = shift;
$o //= "z.split.fasta";
mkdir $o if ! -e $o;
my $seqio_obj = Bio::SeqIO -> new (-file => $file, -format => "fasta", -alphabet => "dna");

while(my $seq_obj = $seqio_obj -> next_seq){
    my $id = $seq_obj -> display_id;
    my $seq = $seq_obj -> seq;
    open O,'>',"$o/$id.fa";
    print O ">$id\n$seq\n";
    close O;
}
