#! perl

use warnings;
use File::Basename;
use strict;

my $para_count = 0;
my $script_dir = "/data/00/user/user112/code/script/z.Util";
for my $e (qw/all prepare admixture pca nj ml/){
    if($ARGV[0]){
        $para_count += 1 if ($e eq $ARGV[0]);
    }
}
if($para_count != 1){
    print STDERR "USAGE : perl $0 [prepare|admixture|pca|nj|ml|all] \$vcf\n";
    exit;
}
my $vcf_1 = $ARGV[1];
#my $name = $ARGV[2];
(my $name //= basename $vcf_1) =~ s/(.*?)\..*/$1/;
die "not available vcf "if ! -e $vcf_1;
if($ARGV[0] eq "all"){
    &prepare($vcf_1);
    &admixture($vcf_1,4);
    &pca($vcf_1);
    &nj($vcf_1);
    &ml($vcf_1);
}else{
    &prepare($vcf_1) if ($ARGV[0]eq "prepare");
    &admixture($vcf_1,4) if($ARGV[0] eq "admixture");
    &pca($vcf_1) if($ARGV[0] eq "pca");
    &nj($vcf_1) if($ARGV[0] eq "nj");
    &ml($vcf_1) if($ARGV[0] eq "ml");
}
sub prepare{
    my $vcf = shift @_;
    open O,'>',"0.prepare.sh";
    print O "vcftools --gzvcf $vcf --plink --out $name
perl $script_dir/structure.changemap.pl $name.map\n";
    close O;
}
sub admixture{
    my $vcf = shift @_;
    my $k =shift @_;
    my $out_dir = "1.admixture.$name";
    mkdir $out_dir if ! -e $out_dir;
    open O,'>',"1.admixture.1.pre.sh";
    print O "plink --noweb --ped $name.ped --map $name.map --recode 12 --out $out_dir/$name.extract\n";
    close O;
    open O,'>',"1.admixture.2.run.sh";
    for(my $i = 2;$i<= $k;$i+=1){
        print O "admixture --cv -j30 -B100 $out_dir/$name.extract.ped $i > $out_dir/$name.extract.log$i.out\n";
    }
    close O;
    open O,'>',"1.admixture.3.plot.sh";
    print O "mv $name.extract* 1.admixture.$name
perl $script_dir/structure.plotadmixture.pl $out_dir
cd $out_dir
Rscript 0.runR.$out_dir.r\n";
    close O;
}
sub pca{
    my $vcf = shift @_;
    my $out_dir = "2.pca.$name";
    mkdir $out_dir if ! -e $out_dir;
    open O,'>',"2.pca.sh";
    print O "perl $script_dir/structure.ind.pl $name.ped
smartpca.perl -i $name.ped -a $name.map.map -b $name.ped",".ind -o $out_dir/2.$name.PCA -p $out_dir/2.$name.PCA.plot -e $out_dir/2.$name.PCA.eigenvalues -l $out_dir/2.$name.PCA.log
perl $script_dir/structure.ggplotpca.pl $out_dir/2.$name.PCA.evec $name.ped.ind
#perl $script_dir/structure.pca.ggplotfile.fix.pl $name.ped.ind $out_dir/2.$name.PCA.evec.ggplot2 > $out_dir/2.$name.PCA.evec.ggplot2.fix
perl -ple \'s/(\\w)\\-\.\*/\$1/\' $out_dir/2.$name.PCA.evec.ggplot2 > $out_dir/2.$name.PCA.evec.ggplot2.fix
ln -s  $out_dir/2.$name.PCA.evec.R ./ 
Rscript 2.$name.PCA.evec.R
perl $script_dir/structure.pca.stat.pl $out_dir/2.$name.PCA.eigenvalues\n";
    close O;
}
sub nj{
    my $vcf = shift @_;
    my $out_dir = "3.nj.$name";
    my $ped = "$name.ped";
    my $map = "$name.map.map";
    mkdir $out_dir if ! -e $out_dir;
    open O,'>',"3.nj.sh";
    print O "plink --file $name --distance-matrix --out $out_dir/$name
perl $script_dir/structure.mdist2phylip.pl $out_dir/$name.mdist $ped $out_dir/$name.out
cd $out_dir ; /data/00/software/phylip/bin/neighbor < ../3.nj.$name.control.txt
mv outfile $name.outfile
mv outtree $name.outtree
";
    close O;
    open O2,'>',"3.nj.$name.control.txt";
    print O2 "$name.out
Y\n";
    close O2;
}
sub ml{
    my $vcf = shift @_;
    open O,'>',"4.ml.$name.sh";
    print O"perl $script_dir/00.GetlocifromVCF.pl $vcf
perl $script_dir/01.GetFastaFromVCF.pl $vcf
FastTreeMP -nt -gtr <  01.GetFastaFromVCF.pl.SNPtandem.fa > 01.GetFastaFromVCF.pl.SNPtandem.tree\n";
    close O;
}
