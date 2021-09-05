#! perl

use warnings;
use strict;
use File::Basename;
use Cwd;
use Getopt::Long;

my (@refs,$hisat,$bwa,$bwa_mem2,$samtools,$dict,$bowtie2);

GetOptions(
           'ref=s' => \@refs,
           'hisat2' => \$hisat,
           'bwa' => \$bwa,
           'bwa-mem2' => \$bwa_mem2,
           'samtools' => \$samtools,
           'dict' => \$dict,
           'bowtie2' => \$bowtie2
          );
if (scalar @refs == 0 ){
    &print_help;
    exit;
}
for my $ref(@refs){
    my $h_dir = getcwd();
    my $dir = dirname $ref;
    $ref = basename $ref;
    (my $name = $ref) =~ s/(.*?)\.(.*)/$1/;
    (my $name2 = $ref) =~ s/(.*)\.(.*)/$1/;
    print "cd $dir\n";
    print "hisat2-build -p 4 $ref $name\n" if $hisat;
    print "bwa-mem2 index $ref\n" if $bwa_mem2;
    print "samtools faidx $ref\n" if $samtools;
    print "java -Xmx10g -jar /data/00/user/user112/software/picard/build/libs/picard.jar CreateSequenceDictionary R=$ref O=$name2.dict\n" if $dict;
    print "bwa index $ref\n" if $bwa;
    print "bowtie2-build $ref $name\n" if $bowtie2;
    print "cd $h_dir\n";
}

sub print_help{
   print STDERR<<USAGE;

  Usage: perl $0 --ref <path2ref> [--hisat2|--bwa|--bwa-mem2|--samtools|--dict|--bowtie2]

USAGE
}
