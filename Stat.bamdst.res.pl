#! perl

use warnings;
use strict;

my $dir = shift;
$dir //= "./";

my @file = sort{$a cmp $b} grep{/coverage.report/} `find $dir`;
#map {print $_} @file;exit;

my %h;
foreach my $file (@file){
    #print $file;exit;
    chomp $file;
    (open IN,"< $file") or die "$!";
    my $name;
    my $dp;
    my $coverage;
    my $map_rate;
    my $proper_map_rate;
    while(<IN>){
	chomp;
	if(/^## Files/){
	    /\/(.*?)\..*/;
	    $name = $1;
	}
	if(/\[Total\] Fraction of Mapped Reads\s+/){
	    s/.*\t//;
	    $map_rate = $_;
	    $h{$name} = "$map_rate";
	}
	if(/\[Total\] Fraction of Properly paired\s+/){
	    s/.*\t//;
	    $proper_map_rate = $_;
	    $h{$name} .= "\t$proper_map_rate";
	}
	if(/\[Target\] Average depth\s+/){
	    s/.*\t//;
	    $dp = $_;
	    $h{$name} .= "\t$dp";
	}
	if(/\[Target\] Coverage \(>0x\)\s+/){
	    s/.*\t//;
	    $coverage = $_;
	    $h{$name} .= "\t$coverage";
	}
    }
    close IN;
}
print "Sample\tMapRate\tProperlyMapRate\tAverageDepth\tCoverage\n";
map{print "$_\t$h{$_}\n"} sort{$a cmp $b} keys %h;
