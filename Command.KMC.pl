#! perl

use warnings;
use strict;
use Getopt::Long;
use Cwd qw(abs_path getcwd);
use File::Basename;

my (@in_dir);
GetOptions(
           'in=s' => \@in_dir,
          );
if (scalar @in_dir == 0){
    &print_help;
    exit;
}
my @files;
for my $dir (@in_dir){
    my @t_file = sort{$a cmp $b} grep {/_1(\.|\_)(fq|fastq)(\.[gz]?)/} `ls $dir`;
    $_ = "$dir/$_" for @t_file;
    push @files , @t_file;
}

foreach my $fastq1 (@files){
    chomp $fastq1;
    #$fastq1 = abs_path($fastq1);
    my $r_dir = dirname $fastq1;
    (my $name = basename $fastq1) =~ s/(.*?)\_(.*)/$1/;
    next if (-e "$name\.kmcdb_k21.hist");
    #next if exists $b{$name};
    (my $fastq2 = basename $fastq1) =~ s/\_1(\.|\_)/_2$1/;
    $fastq2 = "$r_dir/$fastq2";
    print "mkdir $name\.tmp;ls $fastq1 $fastq2 > $name\.read.lst;kmc -k21 -t30 -m128 -ci1 -cs10000 \@$name.read.lst $name.kmcdb ./$name\.tmp;kmc_tools transform $name.kmcdb histogram $name\.kmcdb_k21.hist -cx10000;rm -fr $name\.tmp\n";
}

sub print_help{
   print STDERR<<USAGE;

   Usage: perl $0 --in <reads dir> 
      
USAGE
}
