#! perl

use warnings;
use strict;
use Cwd qw/abs_path getcwd/;
use Getopt::Long;
use FindBin qw($Bin);

my @step;(my $config,my $out_dir,my $w_ad,my $threads,my $all);
GetOptions(
           's_depth' => \$step[0],
           'gq' => \$step[1],
           'miss' => \$step[2],
           'dp' => \$step[3],
           'indel' => \$step[4],
           'repeat' => \$step[5],
           'w_ad' => \$w_ad,
           'all' => \$all,
           'out_dir=s' => \$out_dir,
           'config=s' => \$config,
           'threads=s' => \$threads
                     );
$threads //= 4;
$out_dir //= "./";
unless (($config)){
    &print_help;
    exit;
}
map{$_ = 1} @step if ($all);
my %config = &read_conf;
my $script_dir = (exists $config{Script})?$config{Script}:"$Bin/z.Util";

open O,'>',"0.Snp_filter.v2.run.sh";
print O "perl $script_dir/vcf_filter.split.vcf.pl $config{Raw_vcf} $out_dir/split_vcf\n";

if($step[0] && $step[1]){
    print O "perl $script_dir/vcf_filter.depth_gq.pl $out_dir/split_vcf -d $config{Sample_max},$config{Sample_min} -g $config{GQ_therehold} -t $threads -r $config{Bamdst}\n";
}elsif($step[0] && !$step[1]){
    print O "perl $script_dir/vcf_filter.depth_gq.pl $out_dir/split_vcf -d $config{Sample_max},$config{Sample_min} -t $threads -r $config{Bamdst}\n";
}elsif(!$step[0] && $step[1]){
    print O "perl $script_dir/vcf_filter.depth_gq.pl $out_dir/split_vcf -g $config{GQ_therehold} -t $threads\n";
}
if($step[2] && $step[3]){
    print O "perl $script_dir/vcf_filter.miss_dp.pl $out_dir/split_vcf -d $config{DP_max},$config{DP_min},$config{Qual} -m $config{Rate} -t $threads\n";
}elsif(!$step[2] && $step[3]){
    print O "perl $script_dir/vcf_filter.miss_dp.pl $out_dir/split_vcf -d $config{DP_max},$config{DP_min},$config{Qual} -t $threads\n";
}elsif($step[2] && !$step[3]){
    print O "perl $script_dir/vcf_filter.miss_dp.pl $out_dir/split_vcf -m $config{Rate} -t $threads\n";
}
if($step[4]){
    print O "perl $script_dir/vcf_filter.indel.pl $out_dir/split_vcf -i $config{Indel_vcf} -w $config{Indel_Range} -t $threads \n";
}
if($step[5]){
    print O "perl $script_dir/vcf_filter.repeat.pl $out_dir/split_vcf -i $config{Repeat_bed} -t $threads \n";
}
if($w_ad){
    print O "perl $script_dir/vcf_filter.window_filter.pl $out_dir/split_vcf $config{Window} $config{Window_step} $config{Max_Window_Snp} $threads $config{AD}\n";
}
print O "perl $script_dir/vcf_filter.merge.pl $out_dir/split_vcf $out_dir/Pop.final.vcf\n";

sub read_conf{
    my %r;
    my $term; my $c;
    $config=abs_path($config);
    open (C,"$config") || die "no such file: $config\n";
    while (<C>) {
        chomp;
        next if /^#/;
        next if /^\s*$/;
        $_=~ /^(\S+)\s*?=\s*?([^#\s]+)\s*?#*?.*/;
        $r{$1}=$2;
    }
    close C;
    return %r;
}

sub print_help{

    print STDERR<<USAGE;

  Usage: perl Snp_filter.pl -c <config file> -o <path2dir> -s -g -m -D -i -R -w [--all]

    Options:
      -c   giving the config file with all needed things.
      -o   directory of out file.
      -t   threads num.(4)

      Filter Parameter:
      -s   filter site depth out of 3 or 1/3 (default) fold of sample aveage depth
      -g   filter site GQ value < 20 (default)
      -m   filter site only called in several samples (default=0.2)
      -d   DP range (default (2 to 50)*sample_num)
      -i   SNP site in range 5 bp (default) of INDEL(need Indel.vcf.gz)
      -r   SNP site in repeat region(need bed file of repeat region)
      -w   AD filter , test function
      -a   ALL of above

  FORMAT must be GT:AD:DP:GQ:PL or GT:AD:DP:GQ:PGT:PID:PL

USAGE
}
