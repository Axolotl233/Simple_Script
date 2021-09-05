use warnings;
use strict;

my $ind=shift;
my $gg=shift;
my $info="Sample_location_info.txt";

open (I,"$info") or die "$!";
my %h;
while(<I>){
    chomp;
    my @l=split/\s+/,$_;
    $h{$l[0]}=$l[1];
}
close I;

open (I,"$ind");
my %i;
while(<I>){
    chomp;
    my @l=split/\s+/,$_;
    $i{$l[0]}=$l[1];
    
}
close I;

open (I,"$gg");
while(<I>){
    if (/FID/){
	print "$_";
	next;
    }
    chomp;
    my @l=split/\s+/,$_;
    $l[11]=$h{$i{$l[0]}};
    foreach my $i (@l){
        print "$i\t";
    }   
    print "\n";
}
close I;
