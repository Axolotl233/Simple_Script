#! perl

use warnings;
use strict;
use File::Basename;
use Getopt::Long;
use Cwd;
use FindBin qw($Bin);

my $h_dir = getcwd();
my $script_dir = "$Bin/z.Util";
(my $pop1,my $pop2,my $run,my $vcf,my $chr,my $color,my $w_s,my $arg_d,my $zsorce,my $plot_windth,my $plot_height);
GetOptions(
           'pop1=s' => \$pop1,
           'pop2=s' => \$pop2,
           'vcf=s' => \$vcf,
           'chr=s' => \$chr,
           'window=s' => \$w_s,
           'run' => \$run,
           'color=s' => \$color,
           'argd=s' => \$arg_d,
           'zscore' => \$zsorce,
           'windth=s' => \$plot_windth,
           'height=s' => \$plot_height
          );
$color //= "$script_dir/color.txt";
$plot_windth //= 8;
$plot_height //= 2.5;
for my $s ($pop1,$pop2,$vcf,$chr){
    if(!$s){
        &print_help();
        exit;
    }
}
(my $p1_n = basename $pop1) =~ s/(.*)\..*/$1/;
(my $p2_n = basename $pop2) =~ s/(.*)\..*/$1/;
my @window_step;
if($w_s){
    @window_step = &get_window($w_s);
}else{
    @window_step = ([10000,2500]);
}

for my $e (@window_step){
    my @l = @{$e};
    (my $w_name = ($l[0]/1000)."K");
    my $s_name = ($l[1]/1000)."K";
    $arg_d //= int($l[0]/50);
    my $o1 = "Fst.$p1_n\-$p2_n.$w_name.$s_name";
    open O,'>',"0.$o1.sh";
    print O "vcftools --gzvcf $vcf --weir-fst-pop $pop1 --weir-fst-pop $pop2 --fst-window-size $l[0] --fst-window-step $l[1] --out $o1\n";
    my $f1 = "$o1.windowed.weir.fst";
    print O "grep -v 'CHROM' $f1 | sort -V -k1,1 -k2,2n -k3,3n > $f1.sort; rm -fr $f1; mv $f1.sort $f1\n";
    print O "echo \"### Plot Density\"
perl $script_dir/fst.plot.density.pl $f1 $arg_d $plot_windth $plot_height\n";
    my $f2 = "$o1.windowed.weir.phase.fst";
    print O "echo \"### Phase and Plot Point\"
perl $script_dir/fst.plot.point.pl $f1 10 $chr $color $f2 $plot_windth $plot_height\n";
    if($zsorce){
        my $f3 = "$o1.windowed.weir.zscore.fst";
        my $ch = "$f2.chr_coord.txt";
        print O "echo \"### Z-normalize and plot\"
perl $script_dir/fst.zscore.pl $f2 $f3 $f2.stat $color $ch $plot_windth $plot_height\n";
    }
    close O;
    if($run){
    `sh 0.$o1.sh`;
    }
}

sub print_help{
print STDERR<<USAGE;
  
  Usage: perl $0 --pop1 <pop1_lst> --pop2 <pop2_lst> --vcf <vcf_file> [--chr <chr_file> --color <color file> --run --window_step]
    
      Options:
      --pop1   A list[one sample one line] contain pop A samples
      --pop2   A list[one sample one line] contain pop B samples
      --vcf    vcf file
      --chr    include chr you want to analysis [chr info in first col space separate file]
      --color  [colorname \"16-bit code\(start by #\)\"]
      --run    run script
      --window a space separate "window\\s+step" file [10000,2500]
      --zscore z-normalize fst data [no use at all] 
USAGE
}

sub get_window{
    my $f = shift @_;
    my @a;
    if(-e $f){
        open IN,'<',$f or die "$!\n";
        while(<IN>){
            chomp;
            my @l = split/,/;
            push @a,[$l[0],$l[1]];
        }
        close IN;
    }else{
        my @t = split/,/,$f;
        @a = [$t[0],$t[1]];
    }
    return @a;
}
