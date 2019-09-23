# ~perl

use warnings;
use strict;
use Bio::SeqIO;
use List::Util qw (sum max min);

my $file = $ARGV[0];
my @len;
my $seqio_obj = Bio::SeqIO -> new (-file => $file, -format => "fasta", -alphabet => "dna");

while(my $seq_obj = $seqio_obj -> next_seq){
    my $seq = $seq_obj -> seq;
    my $length = $seq_obj -> length;
    push @len , $length;
}

my $contig = scalar(@len);
print "contig_num\t$contig\n";
my $total_len = sum(@len);
print "total_length\t$total_len\n";
my $per_50 = $total_len * 0.5;
my $per_90 = $total_len * 0.9;
my $max_contig = max(@len);
@len = sort {$b <=> $a} @len;

my ($dy1,$dy2);
$[ = 1;
for (my $i = 1 ;$i < @len; $i++){
    $dy1 += $len[$i];
    if ($dy1 >= $per_90){
        print "N90\t$len[$i]\n"."L90\t$i\n";
        last;
    }
}
for (my $i = 1 ; $i < @len; $i++){
    $dy2 += $len[$i];
    if ($dy2 >= $per_50){
        print "N50\t$len[$i]\n"."L50\t$i\n";
        last;
    }
}
