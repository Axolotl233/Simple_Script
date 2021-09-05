#! perl

use warnings;
use strict;
use File::Basename;

my $dir = shift;
my $bed = shift;
if(!$dir || ! $bed){
    print "USAGE : perl $0 \$dir(contain bam file) \$bed(chr region_start region_end)\n";
    exit;
}
my @file = sort {$a cmp $b} grep {/bam$/} `find $dir`;
foreach my $file (@file){
    chomp $file;
    (my $name = basename $file) =~ s/(.*?)\..*/$1/;
    next if -s "$name/coverage.report";
    system("mkdir $name") if ! -e $name;
    print "bamdst -p $bed -o ./$name $file\n";
}
    
