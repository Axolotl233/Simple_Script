#! perl

use Cwd qw(getcwd abs_path);
use strict;
use warnings;


#my @sps=("Aco-Aco","Tar-Tar","Tsi-Tsi","Vvi-Vvi","Aco-Tar","Aco-Tsi","Aco-Vvi","Tar-Tsi","Tar-Vvi","Tsi-Vvi");
#my @sps=("Aco-Aco","Aco-Tar","Aco-Tsi","Aco-Vvi");
#my @sps=("Nnu-Nnu","Aco-Nnu","Nnu-Tar","Nnu-Tsi","Nnu-Vvi");
#my @sps=("Nnu-Tsi","Aco-Tsi","Tar-Tsi","Tsi-Vvi","Tsi-Tsi");
#my @sps=("Rlu-Aar");
my @sps=("BhD-BhS");
my $dir = shift;
my $h_dir =getcwd();
$dir //= "/data/01/user112/project/Brachypodium/07.pre_evo/01.wgdi/data";
$dir = abs_path($dir);
my $config = "/data/00/user/user112/code/script/wgdi.pl.total.conf.fix.temp";
#my $dir="/data/01/user112/project/Brachypodium/07.pre_evo/01.wgdi/data";
for my $sps (@sps){
    open (SH,">$h_dir/$sps.run.sh");
    `rm -r $sps` if (-e "$sps");
    `mkdir $sps` if (! -e "$sps");
    $sps=~/^(\w+)-(\w+)$/ or die "$sps";
    my ($sp1,$sp2)=($1,$2);
    if ($sp1 eq $sp2){
        `cd $sps ; ln -s $dir/$sp1.wgdi.* . ;  cd ../` if (! -e "$sps/$sp1.wgdi.gff");
        `cd $sps ; ln -s $sp1.wgdi.cds All.cds ; cd ../` if (! -e "$sps/All.cds");
        `cd $sps ; ln -s $sp1.wgdi.pep All.pep ; cd ../` if (! -e "$sps/All.pep");
    }else{
        `cd $sps ; ln -s $dir/$sp1.wgdi.* . ;  cd ../` if (! -e "$sps/$sp1.wgdi.gff");
        `cd $sps ; ln -s $dir/$sp2.wgdi.* . ;  cd ../` if (! -e "$sps/$sp2.wgdi.gff");
        `cd $sps ; cat $sp1.wgdi.cds $sp2.wgdi.cds > All.cds ; cd ../` if (! -e "$sps/All.cds");
        `cd $sps ; cat $sp1.wgdi.pep $sp2.wgdi.pep > All.pep ; cd ../` if (! -e "$sps/All.pep");
    }
    open (O,">$sps/total.conf")||die"$!";
    open (F,$config)||die"$!";
    while (<F>){
        s/species_first/$sp1/;
        s/species_second/$sp2/;
        print O "$_";
    }
    close F;
    close O;
    print SH "cd $sps;
diamond_blastp.pl All.pep All.pep 200 | sh;
wgdi -d total.conf;
wgdi -icl total.conf
wgdi -ks total.conf;
wgdi -bi total.conf;
wgdi -c total.conf;
wgdi -bk total.conf;
wgdi -kp total.conf;
wgdi -pf total.conf;
wgdi -a total.conf;
cd ../;\n";
    close SH;
}
