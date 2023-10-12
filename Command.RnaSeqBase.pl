#! perl

use warnings;
use strict;
use File::Basename;
use Cwd qw(abs_path getcwd);
use Getopt::Long;

if(!$ARGV[0]){
    print STDERR "USAGE : perl $0 [hisat2|stringtie]\n";
    exit;
}
if ($ARGV[0] eq "hisat2"){
    &hisat2();
}
if ($ARGV[0] eq "stringtie"){
    &stringtie();
}

sub hisat2{
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
        $dir =  abs_path($dir);
        my @t_file = sort{$a cmp $b} grep {/_1(\.|\_).*?(fq|fastq)(\.gz?)$/} `ls $dir`;
        for my $t (@t_file){
            $t = "$dir/$t";
        }
        push @files , @t_file;
    }
    if(scalar @files == 0){
        &print_help1;
        exit;
    }
    my $out1 = "$out_dir/01.hisat2";
    mkdir "$out1" if ! -e "$out1";
    open O1,'>',"0.hisat2.sh";
    foreach my $fastq1 (@files){
        chomp $fastq1;
        #$fastq1 = abs_path($fastq1);
        my $r_dir = dirname $fastq1;
        (my $name = basename $fastq1) =~ s/(.*?)\_(.*)/$1/;
        (my $fastq2 = basename $fastq1) =~ s/\_1(\.|\_)/_2$1/;
        $fastq2 = "$r_dir/$fastq2";
        if(! $cover){
            next if -s "$out1/$name.sort.bam";
        }
        print O1 "hisat2 -x $ref -p $threads -X 500 --fr --min-intronlen 20 --max-intronlen 500000 --dta -1 $fastq1 -2 $fastq2 2>>$out1/0.$name.txt |samtools view -bS - | samtools sort -@ $threads -o $out1/$name.sort.bam\n" ;
    }
    close O1;
}

sub stringtie{
    my $h_dir = getcwd();
    my(@in_dir,$out_dir,$threads,$cover,$gff,$e);
    GetOptions(
               'in=s' => \@in_dir,
               'out=s' => \$out_dir,
               'threads=s' => \$threads,
               'cover' => \$cover,
               'gff=s' => \$gff,
               'e' => \$e
              );
    if (scalar @in_dir == 0){
        &print_help2;
        exit;
    }
    if($gff){
        $gff = abs_path($gff);
    }
    $out_dir //= ".";
    $threads //= 10;
    mkdir $out_dir if !-e $out_dir;
    my @files;
    for my $dir (@in_dir){
        my @t_file = sort{$a cmp $b} grep {/bam$/} `find $dir`;
        push @files , @t_file;
    }
    if(scalar @files == 0){
        &print_help2;
        exit;
    }
    my $out2 = "$out_dir/02.stringtie";
    mkdir "$out2" if ! -e "$out2";
    open O2,'>',"1.stringtie1.sh";
    my @gtf;
    for my $file (@files){
        chomp $file;
        (my $name = basename $file) =~ s/(.*?)\..*/$1/;
        if(! $cover){
            next if -s "$out2/$name.gtf";
        }
        if ($e){
            if($gff){
	print O2 "stringtie -e -G $gff -p $threads -o $out2/$name.gtf $file\n";
            }
        }else{
            if($gff){
	print O2 "stringtie -G $gff -p $threads -o $out2/$name.gtf $file\n";
            }else{
	print O2 "stringtie -p $threads -o $out2/$name.gtf $file\n";
            }
        }
        push @gtf, "$name.gtf";
    }
    close O1;
    open O2,'>',"1.stringtie2.sh";
    if($gff){
        print O2 "cd $out2;stringtie --merge -G $gff -o stringtie.merge.gtf ";
    }else{
        print O2 "cd $out2;stringtie --merge -o stringtie.merge.gtf ";
    }
    map{print O2 $_." "} @gtf;
    print O2 ";cd $h_dir\n";
    close O2;
    open O3 ,'>',"1.stringtie3.sh";
    my $m_gtf = "$out2/stringtie.merge.gtf";
    for my $file (@files){
        chomp $file;
        (my $name = basename $file) =~ s/(.*?)\..*/$1/;
        my $dir = "$out2/ballgown";
        print O3 "stringtie -e -B -G $m_gtf -p $threads -o ./$dir/$name/$name.gtf $file\n";
    }
    close O3;
}

sub print_help1{
    print STDERR"

  Usage: perl Rna_Seq_base.pl hista2 --in <reads dir> --ref <path2genome>
      --ref    hisat2 ref_file
      --in     dir contain reads file[format : xxxx_1.fq.gz xxxx_2.fq.gz]
    Options:
      --out      defalut [./]
      --threads  defalut [10]
      --cover    rewrite bam file if it exist already

";
}

sub print_help2{
    print STDERR "

  Usage: perl Rna_Seq_base.pl stringtie --in <bam dir> [--gff <path2gff>]
      --in     dir contain bam file
    Options:
      --out      defalut [./]
      --threads  defalut [10]
      --cover    rewrite gtf file if it exist already
      --gff      gff file for step 1
      --e        open or close 'e' Options:

";
}
