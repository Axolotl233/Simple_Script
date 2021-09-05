#! perl

use warnings;
use strict;
use Bio::SeqIO;

my $s_ioobj = Bio::SeqIO -> new(-file => shift,-format => "fasta");
while(my $s_io = $s_ioobj->next_seq){
    my $id = $s_io -> display_id;
    my $seq = $s_io -> seq;
    $seq =~ s/\*$//;
    print ">$id\n$seq\n";
}
