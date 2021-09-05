#! perl

use warnings;
use strict;
use File::Basename;

my $picard = "/data/00/user/user112/software/picard/build/libs/picard.jar";
my $dir = shift;
my $java_max = shift;
$java_max //= "20g";
my @file = sort{$a cmp $b } grep{/\.bam/} `find $dir`;

foreach (@file) {
    chomp;
    (my $name = (basename $_)) =~ s/\.sort\.bam//;
    #print $name;exit;
    next if (-e "$name.dup.txt");
    print "java -Xmx$java_max -jar $picard MarkDuplicates INPUT=$_ OUTPUT=$name\.sort.nodup.bam METRICS_FILE=$name\.dup.txt REMOVE_DUPLICATES=true ; samtools index $name\.sort.nodup.bam\n";
}
