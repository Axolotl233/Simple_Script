# ~perl

use warnings;
use strict;
use Bio::SeqIO;
use Bio::Seq;
use MCE::Hobo;
use MCE::Shared;
use List::Util qw (sum max min);

MCE::Hobo->init(
    max_workers => '10',
);
$[ = 1;

my $file = $ARGV[0];
my @len;

my $count =`grep -c '>' $file`;
my $seqIO = MCE::Shared -> share ({ module => 'Bio::SeqIO'}, -file => $file, -format => "fasta", -alphabet => "dna");

for my $hoboID (1 .. $count) {
    my $ref = MCE::Hobo->new( \&parallel_reader, $hoboID, $seqIO );
    push @len,$ref->join();
}
MCE::Hobo->waitall();

my $contig = scalar(@len);
print "contig_num\t$contig\n";
my $total_len = sum(@len);
print "total_length\t$total_len\n";
my $max_contig = max(@len);
my $min_contig = min(@len);
print "max\t$max_contig\n";
print "min\t$min_contig\n";

@len = sort {$b <=> $a} @len;

&stats(\@len,50,$total_len);
&stats(\@len,90,$total_len);

sub parallel_reader{
    my ($hoboID,$seqIO) = @_;
    while(my $next = $seqIO -> next_seq()){
        my $length = $next -> length;
        return $length;
    }
}

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
#
