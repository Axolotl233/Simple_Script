#! perl

use warnings;
use strict;

my $gtf = shift or exit;
my $genome = shift or exit;

my $soft_util = "/data/00/user/user112/software/TransDecoder-TransDecoder-v5.5.0/util";
my $out = shift;
$out //= "transcript";

print "$soft_util/gtf_genome_to_cdna_fasta.pl $gtf $genome > $out.fasta
$soft_util/gtf_to_alignment_gff3.pl $gtf > $out.gff3
TransDecoder.LongOrfs -t $out.fasta
TransDecoder.Predict -t $out.fasta
$soft_util/cdna_alignment_orf_to_genome_orf.pl $out.fasta.transdecoder.gff3 $out.gff3 $out.fasta > $out.fasta.transdecoder.genome.gff3\n";
