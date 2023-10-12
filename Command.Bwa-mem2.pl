#! perl

use warnings;
use strict;
use Getopt::Long;
use Cwd qw(abs_path getcwd);
use File::Basename;

my($ref,@in_dir,$out_dir,$second,$sort,$threads,$sam,$cover,$black_lst);
GetOptions(
           'genome=s' => \$ref,
           'in=s' => \@in_dir,
           'out=s' => \$out_dir,
           'second=s' => \$second,
           'sort=s' => \$sort,
           'threads=s' => \$threads,
           'black=s' => \$black_lst,
           'sam=s' => \$sam,
           'cover' => \$cover,
          );
if ((! $ref) || (scalar @in_dir == 0)){
    &print_help;
    exit;
}
#$ref = abs_path($ref);
$out_dir //= ".";
$threads //= 10;
$second //= "no";
$sort //= "yes";
$sam //= "no";
my %b;
if($black_lst){
    open IN,'<',"$black_lst" or die "black_lst error";
    while(<IN>){
        chomp;
        $b{$_} = 1;
    }
}

mkdir $out_dir if !-e $out_dir;
my @files;

for my $dir (@in_dir){
    my @t_file = sort{$a cmp $b} grep {/_1(\.|\_)(fq|fastq)(\.[gz]?)/} `ls $dir`;
    for(my $i = 0;$i < scalar @t_file;$i ++){
        $t_file[$i] = "$dir\/$t_file[$i]";
    }
    push @files , @t_file;
}
if(scalar @files == 0){
    &print_help;
    exit;
}

foreach my $fastq1 (@files){
    chomp $fastq1;
    #$fastq1 = abs_path($fastq1);
    my $r_dir = dirname $fastq1;
    (my $name = basename $fastq1) =~ s/(.*?)\_(.*)/$1/;
    next if exists $b{$name};
    (my $fastq2 = basename $fastq1) =~ s/\_1(\.|\_)/_2$1/;
    $fastq2 = "$r_dir/$fastq2";
    if($sam eq "yes"){
        if($cover){
            print "bwa-mem2 mem -t $threads -R '\@RG\\tID:$name\\tPL:illumina\\tPU:illumina\\tLB:$name\\tSM:$name' -M $ref $fastq1 $fastq2 > $name.sam";
            next;
        }else{
            next if -e "$out_dir/$name.sam";
            print "bwa-mem2 mem -t $threads -R '\@RG\\tID:$name\\tPL:illumina\\tPU:illumina\\tLB:$name\\tSM:$name' -M $ref $fastq1 $fastq2 > $out_dir/$name.sam";
        }
    }
    if($cover){
        
        print "bwa-mem2 mem -t $threads -R '\@RG\\tID:$name\\tPL:illumina\\tPU:illumina\\tLB:$name\\tSM:$name' -M $ref $fastq1 $fastq2 ";
        if ($second eq "yes" && $sort eq "yes"){
            print "| samtools view -b - |samtools sort -O bam -@ $threads -T $name\.tmp -o $out_dir/$name\.sort.bam\n";
            next;
        }elsif ($second eq "yes" && $sort eq "no"){
            print "| samtools view -b - > $name\.bam\n";
            next;
        }elsif ($second eq "no" && $sort eq "no"){
            print "| samtools view -b -hF 256 - > $name\.bam\n";
            next;
        }
        print "| samtools view -hF 256 - |samtools sort -O bam -@ $threads -T $name\.tmp -o $name\.sort.bam\n";
    }else{
        if($sort eq "no"){
            next if -e "$out_dir/$name.bam";
        }else{
            next if -e "$out_dir/$name.sort.bam";
        }
        print "bwa-mem2 mem -t $threads -R '\@RG\\tID:$name\\tPL:illumina\\tPU:illumina\\tLB:$name\\tSM:$name' -M $ref $fastq1 $fastq2 ";
        if ($second eq "yes" && $sort eq "yes"){
            print "| samtools view -b - |samtools sort -O bam -@ $threads -T $name\.tmp -o $name\.sort.bam\n";
            next;
        }elsif ($second eq "yes" && $sort eq "no"){
            print "| samtools view -b - > $name\.bam\n";
            next;
        }elsif ($second eq "no" && $sort eq "no"){
            print "| samtools view -b -hF 256 - > $name\.bam\n";
            next;
        }
        print "| samtools view -hF 256 - |samtools sort -O bam -@ $threads -T $name\.tmp -o $name\.sort.bam\n";
    }
}
sub print_help{
   print STDERR<<USAGE;

   Usage: perl Bwa-mem2.pl --in <reads dir> --genome <path2genome>
      --in     dir contain reads file[format : xxxx_1.fq.gz xxxx_2.fq.gz]
    Options:
      --out      defalut [./]
      --threads  defalut [10]
      --second   result file contain second alignment(flag:256)?,[yes/no] defalut: no
      --sort     sort bamfile ? [yes/no],defalut: yes
      --sam      output sam format file? [yes/no],defalut: yes
      --cover    rewrite bam file if it exist already

USAGE

}
