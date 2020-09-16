#! perl

use warnings;
use strict;
use Bio::SeqIO;

open R,'<',shift;
my %ref;
while(<R>){
    chomp;
    $ref{$_} = 1;
}
close R;

my $seqio_obj = Bio::SeqIO -> new (-file => shift, -format => "fasta", -alphabet => "dna");

while(my $seq_obj = $seqio_obj -> next_seq){
    my $seq = $seq_obj -> seq;
    my $chr = $seq_obj -> display_id;
    next if !exists $ref{$chr};
    print ">$chr\n$seq\n";
}

