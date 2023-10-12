#! perl

use warnings;
use strict;
use File::Basename;
use Cwd qw(abs_path getcwd);
use Getopt::Long;

if(!$ARGV[0]){
    print STDERR "USAGE : perl $0 [snpcall|fixsnp]\n";
    exit;
}
if ($ARGV[0] eq "snpcall"){
    &snpcall();
}
if ($ARGV[0] eq "fixsnp"){
    &fixsnp();
}
my $gatk = "/data/00/software/gatk/gatk-4.2.3.0/gatk";

sub fixsnp{
    #my $gatk = "gatk";
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
        my @t_file = sort{$a cmp $b} grep {/.*g.vcf.gz$/} `find $dir`;
        push @files , @t_file;
    }
    print O "$gatk --java-options \"-Xmx40g -Xms40g\" CombineGVCFs -R $ref";
    map{chomp($_);print O " -V ./$_"} @files;
    print O " -O $out_dir/Pop.combined.g.vcf.gz\n";
    print O "$gatk --java-options \"-Xmx40g -Xms40g\" GenotypeGVCFs -R $ref -V $out_dir/Pop.combined.g.vcf.gz -O $out_dir/Pop.vcf.gz\n";
    print O "$gatk --java-options \"-Xmx40g -Xms40g\" SelectVariants -R $ref -V $out_dir/Pop.vcf.gz -select-type SNP -O $out_dir/Pop.SNP.vcf.gz\n";
    print O "$gatk --java-options \"-Xmx40g -Xms40g\" SelectVariants -R $ref -V $out_dir/Pop.vcf.gz -select-type INDEL -O $out_dir/Pop.INDEL.vcf.gz\n";
    print O "$gatk --java-options \"-Xmx40g -Xms40g\" VariantFiltration -R $ref -V $out_dir/Pop.SNP.vcf.gz  --filter-expression \"QD < 2.0 || FS > 60.0 || MQ < 40.0 || MQRankSum < -12.5 || ReadPosRankSum < -8.0\"  --filter-name \"my_snp_filter\" -O $out_dir/Pop.HDflt.SNP.vcf.gz
gatk --java-options \"-Xmx40g -Xms40g\" VariantFiltration -R $ref -V $out_dir/Pop.INDEL.vcf.gz --filter-expression \"QD < 2.0 || FS > 200.0 || ReadPosRankSum < -20.0\" --filter-name \"my_indel_filter\" -O $out_dir/Pop.HDflt.INDEL.vcf.gz
perl $pl --input $out_dir/Pop.HDflt.SNP.vcf.gz --out $out_dir/Pop.HDflted.SNP.vcf.gz --type SNP --marker my_snp_filter --multi
perl $pl --input $out_dir/Pop.HDflt.INDEL.vcf.gz --out $out_dir/Pop.HDflted.INDEL.vcf.gz --type INDEL --marker my_indel_filter\n"
}

sub snpcall{
    #my $gatk = "gatk";
    my($ref,@in_dir,$out_dir,$threads,$cover,$method);
    GetOptions(
               'ref=s' => \$ref,
               'in=s' => \@in_dir,
               'out=s' => \$out_dir,
               'threads=s' => \$threads,
               'cover' => \$cover,
               'method=s' => \$method
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
        (my $n = basename $_) =~ s/.g.vcf.gz.tbi.*//;
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
        (my $o_name = basename $_) =~ s/(.*?)\..*/$1/;
        if(!$cover){
            next if exists $c{$o_name};
        }
        #print O "java -jar $gatk -T HaplotypeCaller -R $ref -I $_ -nct $threads -ERC GVCF -o $out_dir/$o_name.gvcf.gz -variant_index_type LINEAR -variant_index_parameter 128000 --min_mapping_quality_score 20 2>>$out_dir/$o_name.log\n";
        print O "$gatk HaplotypeCaller --java-options \"-Xmx40g -Xms40g\"  -R $ref -I $_ -O $o_name.g.vcf.gz --emit-ref-confidence GVCF --native-pair-hmm-threads $threads\n";
    }
    close O;
}


sub print_help1{
    print STDERR"

  Usage: perl $0 snpcall --in <bam dir> --ref <path2genome>
      --ref    genome ref_file , with samtools fai and picard dict file
      --in     dir contain bam file
    Options:
      --out      defalut [./]
      --threads  defalut [10]
      --cover    re-run if exists result

";
}
sub print_help2{
      print STDERR"

  Usage: perl $0 fixsnp --in <gvcf dir> --ref <path2genome>
      --ref    genome ref_file , with samtools fai and picard dict file
      --in     dir contain g.vcf file
    Options:
      --out      defalut [./]
";
}
    
