#! perl

use Bio::SeqIO;
my $s = Bio::SeqIO -> new (-file => shift , -format => "fasta");
my $b = shift;
while(my $i = $s -> next_seq){
    my $id = $i -> display_id;
    my $l = $i -> length;
    if($b){
        print "$id\t0\t$l\n";
    }else{
        print "$id\t$l\n";
    }
}
