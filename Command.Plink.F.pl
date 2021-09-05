#! perl
#This script is used to calculate fixation index(F^)

use warnings;
use strict;
use File::Basename;

my $vcf = shift;
if(!$vcf){
    print STDERR "USAGE  :  perl $0 vcf [out_name maf geno mind hwe]\n";
    exit;
}

my $out = shift;
(my $name = basename $vcf) =~ s/(.*?)\..*/$1/;
$out //= $name;
my $maf = shift;
my $geno = shift;
my $mind = shift;
my $hwe = shift;
$maf //= 0.01;
$geno //= 0.05;
$mind //= 0.05;
$hwe //= 0.001;

print "vcftools --gzvcf $vcf --plink --out $out
plink --file $out --make-bed --out $out
plink --bfile $out --maf $maf --geno $geno --mind $mind --hwe $hwe --make-bed --out $out.filter
plink --noweb --bfile $out.filter --het --out $out
mv $out.het 0.result.$out.het
perl -i -ple 's/\\s+//' 0.result.$out.het";
