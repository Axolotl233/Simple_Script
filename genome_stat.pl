# ~perl

#use warnings;
use strict;
use Bio::SeqIO;
use List::Util qw (sum max min);

$[ = 1;

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
my $max_contig = max(@len);
my $min_contig = min(@len);
print "max\t$max_contig\n";
print "min\t$min_contig\n";

@len = sort {$b <=> $a} @len;
#map {print "$_\n"}@len;exit;
&stats(\@len,50,$total_len);
&stats(\@len,90,$total_len);

sub stats{
    my $contigs = shift @_;
    my $N = shift @_;
    my $alllen = shift @_;
    my @contig = @{$contigs};
    my $dy;
    my $per = ($alllen * $N)/100;
    for (my $i = 1 ;$i < @contig; $i++){
        $dy += $contig[$i];
        if ($dy >= $per){
        print "N"."$N"."\t$contig[$i]\n"."L"."$N"."\t$i\n";
        last;
            }
    }
    return;
}
