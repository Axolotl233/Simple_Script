#! perl

use strict;
use warnings;
use List::Util qw /sum/;

my $file = shift;
open (IN,"< $file");
open (OUT,"> $file.stat.txt");
my (%h,$sample,@sample);
my %g;
my $line1 = readline IN;
@sample = (split/\t/,$line1);
shift @sample;
my $n = scalar(@sample);
chomp($sample[-1]);
while(<IN>){
    chomp;
    my @fpkm =(split/\t/ ,$_)[1..$n];
    my $n = (split/\t/ ,$_)[0];
    foreach $sample (@sample){
        my $t = shift @fpkm;
        push @{$h{$sample}} , $t;
        $g{$n} = 1 if $t > 1;
    }
}
close IN;

print OUT "sample\tfpkm=0\t0<fpkm<=1\t1<fpkm<=10\t10<fpkm<=100\tfpkm>100\n";
my ($cl_1,$cl_2,$cl_3,$cl_4,$cl_5);
foreach $sample (sort keys %h){
    $cl_1 =0; $cl_2 =0; $cl_3 =0; $cl_4 =0;$cl_5=0;
    my @fpkm = @{$h{$sample}};
    foreach my $fpkm (@fpkm){
        $cl_5 += 1 if($fpkm == 0);
        $cl_1 += 1 if($fpkm <=1 && $fpkm > 0);
        $cl_2 += 1 if($fpkm <=10 && $fpkm > 1);
        $cl_3 += 1 if($fpkm <=100 && $fpkm >10);
        $cl_4 += 1 if($fpkm >100);
    }
    #my $sum = $cl_1 + $cl_2 + $cl_3 + $cl_4;
    print OUT "$sample\t$cl_5\t$cl_1\t$cl_2\t$cl_3\t$cl_4\n";
}
close OUT;
print STDERR scalar (keys %g);
