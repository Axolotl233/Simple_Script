#! perl

use warnings;
use strict;
use File::Basename;

print STDERR "USAGE : perl $0 gff [0,1,2][0:all 1:mcscanx 2:mcscanx-python]\n";

my $gff = shift or die "need gff\n";
my $jud = shift;
$jud //= 0;

open IN,'<',$gff;
my $m;
my $mp;
while(<IN>){
    chomp;
    next if /^#/;
    my @l = split/\t/;
    next unless $l[2] eq "mRNA";
    if($l[8] =~ /;/){
        $l[8] =~ s/.*ID=(.*?);.*/$1/;
    }else{
        $l[8] =~ s/ID=//;
    }
    $m .= "$l[0]\t$l[8]\t$l[3]\t$l[4]\n";
    $mp .= "$l[0]\t$l[3]\t$l[4]\t$l[8]\t$l[6]\t$l[7]\n";
}
(my $base = basename $gff) =~ s/(.*)\..*/$1/;
my $mp_o = "$base.python_mcscanx.gff";
my $m_o = "$base.mcscanx.gff";
if($jud == 0){
    open MP ,'>',$mp_o;
    print MP $mp;
    open M ,'>',$m_o;
    print M $m;
}elsif($jud == 1){
    open M ,'>',$m_o;
    print M $m;
}elsif($jud == 2){
    open MP ,'>',$mp_o;
    print MP $mp;
}
close MP;
close M;
