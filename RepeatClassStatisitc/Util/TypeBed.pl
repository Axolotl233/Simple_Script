use warnings;
use strict;

my @gff=<.\/*.gff>;
foreach my $gff (@gff){
    open (I,"$gff")||die "$!\n";
    while(<I>){
	next if /^#/;
	my @l=split/\s+/,$_;
	print "$l[0]\t$l[3]\t$l[4]\t$l[1]\n";
    }
    close I;
}
