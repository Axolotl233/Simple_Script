#! perl

use warnings;
use strict;

print STDERR "### USAGE : perl $0 \$data_dir \$out_dir
### Fastq must named xxxx_1.fq.gz xxxx_2.fq.gz\n";
my $data_dir = shift ;
my $out_dir = shift;
mkdir $out_dir if !-e $out_dir;
opendir (F, $data_dir) or die "need dir";
while (my $file = readdir F) {
    next unless ($file =~ /_1(\.|\_)(clean\.)?(fq|fastq)(\.gz)?/);
    (my $name = $file) =~ s/(.*?)\_(.*)/$1/;
    my $fastq1 = $file;
    chomp ($fastq1);
    (my $fastq2 = $fastq1) =~ s/_1\./_2\./;
    next if (-e "$out_dir/$name\_fix_1.fastq.gz" && -e "$out_dir/$name\_fix_2.fastq.gz");
    #print  "fastp -i $data_dir/$fastq1 -I $data_dir/$fastq2 -o $out_dir/$name\_fix_1.fastq.gz -O $out_dir/$name\_fix_2.fastq.gz -f 10 -F 10 -q 20 -l 50 -5 -3 -h $out_dir/$name.html -w 20 2>&1 2>$out_dir/$name.log\n";
    print  "fastp -i $data_dir/$fastq1 -I $data_dir/$fastq2 -o $out_dir/$name\_fix_1.fastq.gz -O $out_dir/$name\_fix_2.fastq.gz -q 20 -l 50 -5 -3 -h $out_dir/$name.html -w 20 2>&1 2>$out_dir/$name.log\n";
}
