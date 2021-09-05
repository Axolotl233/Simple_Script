#! perl

use warnings;
use strict;

my $vcf = shift;
my $out_dir = shift;
$out_dir //= "0.split_vcf.out";
open IN,"zcat $vcf |" or die "$!";
my $head;
while(<IN>){
    if(/^##/){
        $head .= $_;
    }elsif(/^#C/){
        $head .= $_;
        last;
    }
}

my $con;
my $chr = "NA";
mkdir "$out_dir" if !-e "$out_dir";
while(<IN>){
    my @line = split/\t/;
    if($chr ne "NA" && $chr ne $line[0]){
		#mkdir "$out_dir/$chr" if ! -e "$out_dir/$chr";
        open O,'>',"$out_dir/$chr.vcf";
        print O $head;
        print O $con;
        close O;
        $chr = $line[0];
        $con = $_;
    }else{
        if($chr eq "NA"){
            $chr = $line[0];
        }
        $con .= $_;
    }
}
open O,'>',"$out_dir/$chr.vcf";
print O $head;
print O $con;
close O;
