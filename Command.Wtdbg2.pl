#! perl

use warnings;
use strict;
use Getopt::Long;
my ($reads,$NGS,$prefix,$threads,$genome,$type);

GetOptions(
           'input=s' => \$reads,
           'ngs=s' => \$NGS,
           'prefix=s' => \$prefix,
           'threads=s' => \$threads,
           'genome=s' => \$genome,
           'type=s' => \$type
          );
$threads //= 10;
$NGS =~ s/,/ /g;
$reads =~ s/,/ /g;

print "wtdbg2 -x $type -g $genome -i $reads -t $threads -fo $prefix
wtpoa-cns -t $threads -i $prefix.ctg.lay.gz -fo $prefix.raw.fa
minimap2 -t$threads -ax map-pb -r2k $prefix.raw.fa $reads | samtools sort -@20 >$prefix.bam
samtools view -F0x900 $prefix.bam | wtpoa-cns -t 16 -d $prefix.raw.fa -i - -fo $prefix.cns.fa
bwa-mem2 index $prefix.cns.fa
bwa-mem2 mem -t $threads $prefix.cns.fa $NGS | samtools sort -O SAM | wtpoa-cns -t $threads -x sam-sr -d $prefix.cns.fa -i - -fo $prefix.srp.fa\n";
