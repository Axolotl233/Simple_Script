#! perl

use warnings;
use strict;

my $vcf_dir = shift or die "USAGE : perl $0 \$vcf_dir \$out \n";
my $out = shift;
my @vcf = sort{$a cmp $b} grep {/\.vcf$/} `find $vcf_dir`;
chomp $_ for @vcf;
my $head = &get_head($vcf[0]);
open O,'>',"$out";
print O $head;
for my $f(@vcf){
    open IN,'<',$f;
    while(<IN>){
        next if /^#/;
        print O $_;
    }
}

sub get_head{
    my $f = shift @_;
    (my $h);
    open IN,'<',$f or die "$!";
    while(<IN>){
        if(/^##/){
            $h .= $_;
        }elsif(/^#C/){
            s/\.\d+//g; 
            $h .= $_;
            last;
        }
    }
    close IN;
    return($h)
}
