#! perl

use Bio::SeqIO;

my $file = shift or die "need fasta file\n";
my $window = shift;
$window //= "no";

my $s = Bio::SeqIO -> new (-file => $file , -format => "fasta");
while(my $i = $s -> next_seq){
    my $id = $i -> display_id;
    my $l = $i -> length;
    if ($window eq "no"){
        print "$id\t0\t$l\n";
    }else{
      DO:for(my $start = 0;$start < $l;$start += $window){
            my $jud = 0;
            $start += 1;
            my $end = $start + $window - 2;
            if($end > $l){
	$jud = 1;
	$end = $l;
            }
            print "$id\t$start\t$end\n";
            $start -= 1;
            last DO if $jud == 1;
        }
    }
}
