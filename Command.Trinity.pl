#! perl

use warnings;
use strict;
use Getopt::Long;
use File::Basename;

(my $in, my $out,my $sample);
GetOptions(
           'in=s' => \$in,
           'out=s' => \$out,
           'sample=s' => \$sample
          );
exit if(!$in);
my %h;
$out//= "./Trinity_out";
if($sample){
    open IN,'<',$sample;
    while(<IN>){
        chomp;
        my @l = split/\t/;
        $h{$l[0]} = 1;
    }
}
my @f1;my @f2;
my @fs = sort {$a cmp $b} `find $in`;
for my $file(@fs){
    next unless ($file =~ /_1(\.|\_)(clean\.)?(fq|fastq)(\.gz)?/);
    chomp ($file);
    (my $name = $file) =~ s/(.*?)(\_|\.).*/$1/;
    if($sample){
        next if !exists $h{$name};
    }
    my $fastq1 = $file;
    (my $fastq2 = $fastq1) =~ s/_1/_2/;
    push @f1,$fastq1;
    push @f2,$fastq2;
}
my $f1 = join",",@f1;
my $f2 = join",",@f2;
#Trinity --seqType fq --max_memory 50G --left ./es/ES14C1_1.fastq.gz,./es/ES6C1_1.fastq.gz,./es/ES9C1_1.fastq.gz  --right ./es/ES14C1_2.fastq.gz,./es/ES6C1_2.fastq.gz,./es/ES9C1_2.fastq.gz --CPU 30 --trimmomatic --output Trinity.SSZYC --full_cleanup
print "Trinity --seqType fq --max_memory 50G --left $f1  --right $f2 --CPU 30 --trimmomatic --output $out --full_cleanup\n";
