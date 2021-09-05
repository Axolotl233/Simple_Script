#! perl

use warnings;
use strict;
use File::Basename;

print STDERR "USAGE : perl $0 \$vcf\n";

my $king = "/data/00/user/user112/software/king_1.4/king";
my $script_dir = "/data/00/user/user112/code/script/z.Util";
my $vcf = shift;
$vcf //= "Pop.final.SNP.vcf.gz";

(my $n = basename $vcf) =~ s/(.*?)\..*/$1/;
open O,'>',"0.king.sh";
print O "vcftools --gzvcf $vcf --plink --out $n
plink --file $n --make-bed --out $n
$king -b $n\.bed --kinship
perl $script_dir/king.filter_ind.pl
perl $script_dir/king.auto_remove_ind.pl
perl $script_dir/king.display.pl > king.kin0.stat
perl $script_dir/king.plot.pl king.kin0
Rscript king.kin0.plot.R
";
