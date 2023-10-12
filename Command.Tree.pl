#! perl

use warnings;
use strict;
use File::Basename;
use Cwd qw/abs_path getcwd/;

my $h_dir = getcwd();
my @fa = @ARGV;

for my $f (@fa){
    (my $n = basename $f)=~s/\..*//;
    $f = abs_path($f);
    mkdir $n if !-e $n;
    print "cd $n;ln -s $f ./$n.fa;mafft --thread 10 --quiet --auto $n.fa > $n.mafft.fa;iqtree -s $n.mafft.fa -pre $n -quiet -nt 10 -bb 1000 -redo;cd $h_dir\n";
}
