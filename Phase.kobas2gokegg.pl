#! perl

use warnings;
use strict;
use Getopt::Long;

my (@fs,$prefix,$out);
GetOptions(

           'in=s' => \@fs,
           'out=s' => \$out,
           'prefix=s' => \$prefix
          );
if(scalar @fs == 0){
    print STDERR "USAGE : perl $0 --in kobas.res1 --in kobas.res2 [--out]\n";
    exit;
}
$out //= "kobas";
my $go_out = "$out.go.tsv";
my $kegg_out = "$out.kegg.tsv";
my @kegg;
my %go;

for my $f (@fs){
    open IN,'<',$f or die "$!";
    Kegg:while(<IN>){
        next if /^#/;
        next unless length;
        if(/^-/){
            last Kegg;
        }else{
            push @kegg,$_;
        }
    }
    #my $c = "////";
    $/="////";
    while(<IN>){
        my @info = split/\n/;
        my $gene;
        for my $e (@info){
            next if /\/^/;
            next if /\s^/;
            if($e =~ /Query:/){
	$gene = (split/\t/,$e)[1];
            }elsif($e =~ /(GO:\d+)/){
	push @{$go{$gene}} , $1;
            }
        }
    }
    $/="\n";
}
open O,'>',$kegg_out;
print O @kegg;
close O;
open O,'>',$go_out;
for my $k (sort {$a cmp $b} keys %go){
    print O "$k\t";
    print O join"\t",@{$go{$k}};
    print O "\n";
}
close O;
