#! perl
# BamDeal statistics Coverage -i ES-12.realn.bam -r ../../01.genome/Bsta.v1.fasta -o test

use warnings;
use strict;
use File::Basename;
use Cwd qw/abs_path getcwd/;

my $h_dir = getcwd();
my $dir = shift;
my $fa = shift;
$fa = abs_path($fa);
if(!$dir || ! $fa){
    print "USAGE : perl $0 \$dir(contain bam file) \$fasta (genome fa)\n";
    exit;
}
my @file = sort {$a cmp $b} grep {/bam$/} `find $dir`;
foreach my $file (@file){
    chomp $file;
    $file = abs_path($file);
    (my $name = basename $file) =~ s/(.*?)\..*/$1/;
    next if -s "$name/$name.stat";
    system("mkdir $name") if ! -e $name;
    print "cd $name;BamDeal statistics Coverage -i $file -r $fa -o $name;cd $h_dir\n";
}
