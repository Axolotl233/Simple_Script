#! perl

use warnings;
use strict;
use File::Basename;
use Getopt::Long;
use Cwd qw/abs_path getcwd/;

my $h_dir = getcwd();
my($ref,@in_dir,$out_dir,$bs,$black_lst,$depth,$c50);
GetOptions(
           'in=s' => \@in_dir,
           'out=s' => \$out_dir,
           'bootstrap=s' => \$bs,
           'black=s' => \$black_lst,
           'ref=s' => \$ref,
           'c50' => \$c50,
           'depth=s' => \$depth
          );
if ((! $ref) || (scalar @in_dir == 0)){
    &print_help;
    exit;
}

$ref = abs_path($ref);
$out_dir //= "psmc_run";
mkdir $out_dir if !-e $out_dir;
my %b;
if($black_lst){
    open IN,'<',"$black_lst" or die "black_lst error";
    while(<IN>){
        chomp;
        $b{$_} = 1;
    }
}
my %d;
if($depth){
    open IN,'<',"$depth" or die "depth error";
    while(<IN>){
        chomp;
        my @l = split/\s+/;
        $d{$l[0]} = 3*$l[1];
    }
}

my @files;
for my $dir (@in_dir){
    my @t_file = sort{$a cmp $b} grep {/bam$/} `find $dir`;
    push @files , @t_file;
}
if(scalar @files == 0){
    &print_help;
    exit;
}

for my $f(@files){
    chomp $f;
    $f = abs_path($f);
    next if -d $f;
    (my $name = basename $f) =~ s/(.*?)\..*/$1/;
    next if exists $b{$name};
    mkdir "$out_dir/$name";
    chdir "$out_dir/$name";
    open O_t,'>',"0.run.sh";
    print O_t "cd $out_dir/$name\n";
    if($depth){
        if($c50){
            print O_t "samtools mpileup -C50 -d $d{$name} -q 20 -Q 20 -uf $ref $f | bcftools call -c | vcfutils.pl vcf2fq | gzip - > cns.fq.gz\n";
        }else{
            print O_t "samtools mpileup -d $d{$name} -q 20 -Q 20 -uf $ref $f | bcftools call -c | vcfutils.pl vcf2fq | gzip - > cns.fq.gz\n";
        }
    }else{
        if($c50){
            print O_t "samtools mpileup -C50 -d 100 -q 20 -Q 20 -uf $ref $f | bcftools call -c | vcfutils.pl vcf2fq | gzip - > cns.fq.gz\n";
        }else{
            print O_t "samtools mpileup -d 100 -q 20 -Q 20 -uf $ref $f | bcftools call -c | vcfutils.pl vcf2fq | gzip - > cns.fq.gz\n";
        }
    }
    print O_t "fq2psmcfa -q 20 cns.fq.gz > diploid.psmcfa\n";
    print O_t "splitfa diploid.psmcfa > split.fa\n";
    print O_t "mkdir psmc_files\n";
    print O_t "psmc -N25 -t15 -r5 -p \"4+25*2+4+6\" -o psmc_files/diploid.psmc diploid.psmcfa\n";
    if($bs){
        open O_b,'>',"PSMC_bootstrap.sh";
        for(my $i=1;$i<=$bs;$i++){
	        print O_b "psmc -N25 -t15 -r5 -b -p \"4+25*2+4+6\" -o psmc_files/round-$i.psmc split.fa\n";
        }
        print O_t "parallel -j 10 < PSMC_bootstrap.sh\n";
    }
    print O_t "cd $h_dir";
    chdir($h_dir);
    print "sh $out_dir/$name/0.run.sh\n";
}

sub print_help{
   print STDERR<<USAGE;

   Usage: perl $0 --in <bam dir> --ref <genome_fa>
      --in     dir contain bam file[format : xxxx.bam]
      --ref    genome fasta

    Options:
      --out         defalut [./]
      --black       black list
      --bootstrap   [num]

USAGE
}
