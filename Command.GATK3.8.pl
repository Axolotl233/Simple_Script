#! perl

use warnings;
use strict;
use File::Basename;
use Cwd qw(abs_path getcwd);
use Getopt::Long;

if(!$ARGV[0]){
    print STDERR "USAGE : perl $0 [realign|snpcall|fixsnp]\n";
    exit;
}
if ($ARGV[0] eq "realign"){
    &realign();
}
if ($ARGV[0] eq "snpcall"){
    &snpcall();
}
if ($ARGV[0] eq "fixsnp"){
    &fixsnp();
}

sub fixsnp{
    my $gatk = "/data/00/user/user112/software/gatk3.8-1/GenomeAnalysisTK.jar";
    my $pl = "/data/00/user/user112/code/script/GATK.remove.hdfilter.pl";
    my($ref,@in_dir,$out_dir,$threads,$cover);
    GetOptions(
               'ref=s' => \$ref,
               'in=s' => \@in_dir,
               'out=s' => \$out_dir,
               'cover' => \$cover,
              );
    if ((! $ref) || (scalar @in_dir == 0)){
        &print_help2;
        exit;
    }
    $out_dir //= ".";
    mkdir $out_dir if !-e $out_dir;
    open O,'>',"0.downstream.sh";
    my @files;
    for my $dir (@in_dir){
        my @t_file = sort{$a cmp $b} grep {/.*gvcf.gz$/} `find $dir`;
        push @files , @t_file;
    }
    print O "java -jar $gatk -T GenotypeGVCFs -R $ref";
    map{chomp($_);print O " -V ./$_"} @files;
    print O " -o $out_dir/Pop.vcf.gz\n";
    print O "java -jar $gatk -T SelectVariants -R $ref -V $out_dir/Pop.vcf.gz -selectType SNP -o $out_dir/Pop.SNP.vcf.gz\n";
    print O "java -jar $gatk -T SelectVariants -R $ref -V $out_dir/Pop.vcf.gz -selectType INDEL -o $out_dir/Pop.INDEL.vcf.gz\n";
    print O "java -jar $gatk -T VariantFiltration -R $ref -V $out_dir/Pop.SNP.vcf.gz  --filterExpression \"QD < 2.0 || FS > 60.0 || MQ < 40.0 || MQRankSum < -12.5 || ReadPosRankSum < -8.0\"  --filterName \"my_snp_filter\" -o $out_dir/Pop.HDflt.SNP.vcf.gz
java -jar $gatk -T VariantFiltration -R $ref -V $out_dir/Pop.INDEL.vcf.gz --filterExpression \"QD < 2.0 || FS > 200.0 || ReadPosRankSum < -20.0\" --filterName \"my_indel_filter\" -o $out_dir/Pop.HDflt.INDEL.vcf.gz
perl $pl --input $out_dir/Pop.HDflt.SNP.vcf.gz --out $out_dir/Pop.HDflted.SNP.vcf.gz --type SNP --marker my_snp_filter --multi
perl $pl --input $out_dir/Pop.HDflt.INDEL.vcf.gz --out $out_dir/Pop.HDflted.INDEL.vcf.gz --type INDEL --marker my_indel_filter\n"
}

sub snpcall{
    my $gatk = "/data/00/user/user112/software/gatk3.8-1/GenomeAnalysisTK.jar";
    my($ref,@in_dir,$out_dir,$threads,$cover);
    GetOptions(
               'ref=s' => \$ref,
               'in=s' => \@in_dir,
               'out=s' => \$out_dir,
               'threads=s' => \$threads,
               'cover' => \$cover,
              );
    if ((! $ref) || (scalar @in_dir == 0)){
        &print_help1;
        exit;
    }
    $out_dir //= ".";
    $threads //= 10;
    mkdir $out_dir if !-e $out_dir;
    my @check = grep{/tbi$/}`find $out_dir`;
    my %c;
    for(@check){
        chomp;
        (my $n = basename $_) =~ s/.gvcf.gz.tbi.*//;
        $c{$n} = 1;
    }
    my @files;
    for my $dir (@in_dir){
        my @t_file = sort{$a cmp $b} grep {/.*bam$/} `find $dir`;
        push @files , @t_file;
    }
    open O,'>',"0.HaploteCaller.sh";
    foreach (@files) {
        chomp;
        my $dir = dirname $_;
        (my $o_name = basename $_) =~ s/(.*?)\..*/$1/;
        (my $bam_index = basename $_) =~ s/\.bam$/\.bai/;
        next if !-e "$dir/$bam_index";
        if(!$cover){
            next if exists $c{$o_name};
        }
        print O "java -jar $gatk -T HaplotypeCaller -R $ref -I $_ -nct $threads -ERC GVCF -o $out_dir/$o_name.gvcf.gz -variant_index_type LINEAR -variant_index_parameter 128000 --min_mapping_quality_score 20 2>>$out_dir/$o_name.log\n";
        #print "gatk --java-options \"-Xmx20g\"  -R $ref -I $_ -O $o_name.g.vcf.gz --emit-ref-confidence GVCF\n";
    }
    close O;
}

sub realign{
    my $gatk = "/data/00/user/user112/software/gatk3.8-1/GenomeAnalysisTK.jar";
    my($ref,@in_dir,$out_dir,$threads,$cover);
    GetOptions(
               'ref=s' => \$ref,
               'in=s' => \@in_dir,
               'out=s' => \$out_dir,
               'threads=s' => \$threads,
               'cover' => \$cover,
              );
    if ((! $ref) || (scalar @in_dir == 0)){
        &print_help1;
        exit;
    }
    $out_dir //= ".";
    $threads //= 10;
    mkdir $out_dir if !-e $out_dir;
    my @files;
    for my $dir (@in_dir){
        my @t_file = sort{$a cmp $b} grep {/.*nodup.bam$/} `find $dir`;
        push @files , @t_file;
    }
    open O1,'>',"0.Realigner1.sh";
    open O2,'>',"0.Realigner2.sh";
    foreach (@files) {
        chomp;
        (my $o_name = basename $_) =~ s/(.*?)\..*/$1/;
        next if -s "$out_dir/$o_name.realn.bam";
        print O2 "java -jar $gatk -T IndelRealigner -R $ref -targetIntervals $out_dir/$o_name.realn.intervals -o $out_dir/$o_name.realn.bam -I $_ 2>$out_dir/$o_name.realn.bam.log\n";
        next if -s "$out_dir/$o_name.realn.intervals";
        print O1 "java -jar $gatk -T RealignerTargetCreator -nt $threads -R $ref -I $_ -o $out_dir/$o_name.realn.intervals 2>$out_dir/$o_name.TC.bam.log\n";
    }
    close O1;
    close O2;
}

sub print_help1{
    print STDERR"

  Usage: perl GATK3.8.pl realign|snpcall --in <bam dir> --ref <path2genome>
      --ref    genome ref_file , with samtools fai and picard dict file
      --in     dir contain bam file
    Options:
      --out      defalut [./]
      --threads  defalut [10]
      --cover

";
}
sub print_help2{
      print STDERR"

  Usage: perl GATK3.8.pl realign|snpcall --in <bam dir> --ref <path2genome>
      --ref    genome ref_file , with samtools fai and picard dict file
      --in     dir contain g.vcf file
    Options:
      --out      defalut [./]
      --threads  defalut [10]

";
}
    
