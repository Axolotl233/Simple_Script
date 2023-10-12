#! perl

use warnings;
use strict;
use File::Basename;
use Getopt::Long;
use Cwd qw/abs_path getcwd/;
use Math::Combinatorics;
#diamond blastp --db ./bsta.dmnd  --query ./Ath.pep.clean.fa --out ath2bsta.out --outfmt 6 --sensitive --max-target-seqs 5 --evalue 1e-5 --block-size 20.0 --tmpdir ./tmp --index-chunks 1 -p 10
#diamond makedb --in evm.pep.fa  -d bsta
my $type = shift @ARGV;
if (!$type){
    print STDERR "LOOK SCRIPT FOR RIGHT ARGUMENT !\n";
    exit;
}
    
if ($type eq "all"){
    my %h;
    my ($threads,$max);
    GetOptions(
               'threads=s' => \$threads,
               'max=s' => \$max
              );
    $threads //= 10;
    $max //= 1;
    for my $f (@ARGV){
        chomp $f;
        #$f = abs_path($f);
        (my $n = basename $f) =~ s/\..*//;
        $h{$n} = $f;
    }
    open O,'>',"0.makedb.sh";
    for my $k (keys %h){
        print O "diamond makedb --in $h{$k}  -d $k\n";
    }
    close O;
    open O,'>',"1.blast.sh";
    my @tmp1 = combine(2,(keys %h));
    for my $t (@tmp1){
        my @tmp2 = @{$t};
        #print join"\t",@tmp2;exit;
        #mkdir "$tmp2[0]-$tmp2[1]_tmp" if !-e "$tmp2[0]-$tmp2[1]_tmp";
        print O "mkdir $tmp2[0]-$tmp2[1]\_tmp;diamond blastp --db ./$tmp2[0].dmnd  --query $h{$tmp2[1]} --out $tmp2[1]-$tmp2[0].out --outfmt 6 --sensitive --max-target-seqs $max --evalue 1e-5 --block-size 20.0 --tmpdir $tmp2[0]-$tmp2[1]\_tmp -p $threads;rm -fr $tmp2[0]-$tmp2[1]\_tmp\n";
        print O "mkdir $tmp2[1]-$tmp2[0]\_tmp;diamond blastp --db ./$tmp2[1].dmnd  --query $h{$tmp2[0]} --out $tmp2[0]-$tmp2[1].out --outfmt 6 --sensitive --max-target-seqs $max --evalue 1e-5 --block-size 20.0 --tmpdir $tmp2[1]-$tmp2[0]\_tmp -p $threads;rm -fr $tmp2[1]-$tmp2[0]\_tmp\n";
    }
    close O;
}elsif ($type eq "ref"){
    my ($ref,$threads,$max);
    GetOptions(
               'threads=s' => \$threads,
               'ref=s' => \$ref,
               'max=s' => \$max
              );
    $threads //= 10;
    $max //= 1;
    open O,'>',"0.run.sh";
    (my $ref_n = basename $ref)=~s/\..*//;
    print O "diamond makedb --in $ref -d $ref_n\n";
    for my $f (@ARGV){
        (my $n = basename $f) =~ s/\..*//;
        print O "mkdir $n-$ref_n\_tmp;diamond blastp --db ./$ref_n.dmnd  --query $f --out $n-$ref_n.out --outfmt 6 --sensitive --max-target-seqs $max --evalue 1e-5 --block-size 20.0 --tmpdir $n-$ref_n\_tmp -p $threads;rm -fr $n-$ref_n\_tmp\n";
    }
    close O;
}
