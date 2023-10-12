#! perl

use warnings;
use strict;
use Bio::SeqIO;

my $fa = shift;
my $s_obj = Bio::SeqIO -> new (-file => $fa);
while(my $s_io = $s_obj -> next_seq){
    my $id = $s_io -> display_id;
    my $seq = $s_io -> seq;
    my $len = $s_io -> length;
    $seq = uc($seq);
    my @l = split /N+/,$seq;
    $seq =~ s/N//g;
    my $n = $len - (length $seq);
    my @p = ($id,$len,$n,(scalar @l -1));
    print join"\t",@p;
    print "\n";
}
