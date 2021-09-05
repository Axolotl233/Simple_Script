#! perl

use warnings;
use strict;

my $trembl = "/data/01/user112/database/trembl/uniprot_trembl.fasta";
my $nr = "/data/01/user112/database/nr/nr";
my $swissport = "/data/01/user112/database/swissprot/swissprot";

my $query = shift or die "need query\n";
my $threads = shift;
$threads //= 40;
mkdir "tmp";
my $max_target = shift;
$max_target //= 10;

open O,'>',"0.blast.anno.sh";
print O "diamond blastp --db $trembl --query $query --out blast.trembl.tab --outfmt 6 --sensitive --max-target-seqs $max_target --evalue 1e-5 --block-size 20.0 --tmpdir ./tmp --index-chunks 1 -p $threads\n";
print O "diamond blastp --db $nr --query $query --out blast.nr.tab --outfmt 6 --sensitive --max-target-seqs $max_target --evalue 1e-5 --block-size 20.0 --tmpdir ./tmp --index-chunks 1 -p $threads\n";
print O "diamond blastp --db $swissport --query $query --out blast.swissport.tab --outfmt 6 --sensitive --max-target-seqs $max_target --evalue 1e-5 --block-size 20.0 --tmpdir ./tmp --index-chunks 1 -p $threads\n";
close O;

#diamond blastp --db /data/01/user112/database/trembl/uniprot_trembl.fasta --query ./evm.pep.fa --out blast.trembl.tab --outfmt 6 --sensitive --max-target-seqs 10 --evalue 1e-5 --block-size 20.0 --tmpdir ./tmp --index-chunks 1 -p 40
