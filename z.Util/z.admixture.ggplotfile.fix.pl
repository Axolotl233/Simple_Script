use warnings;
use strict;

my $indir=shift;
my $info="Sample_location_info.txt";
open (L,"$info");
my %h;
while(<L>){
    chomp;
    my @l=split/\s+/,$_;
    $h{$l[0]}=$l[2];
}
close L;

my @species=("C_ferox","C_thibetica","C_sieboidiana","C_fargesii","C_colurna","C_chinensis","C_latifolia","C_potaninii","C_americana","C_avellana","C_maxima","C_heterophylla","C_wulingensis","C_suchuenensis","C_yunnanensis");
my $a="a";
my %g;
foreach my $s (@species){
    $g{$s}=$a;
    $a++;
}

my @file=<$indir\/*.ggplot>;
foreach my $f (@file){#print "$f";
    open (I,$f);
    open (O,">$f.fix");
    while(<I>){
	chomp;
	if ($_=~/^id/){
	    print O "$_\n";
	}else{
	    my @l=split/\s+/,$_;
	    $h{$l[0]}=~/(.*)_\d/;#print "1:$1 ";#exit;
	    my $b=$g{$1};#print "2:$b\n";#exit;
	    print O "$b\.$h{$l[0]}\t$l[1]\t$l[2]\n";
	}
    }
    close I;
    close O;
}
