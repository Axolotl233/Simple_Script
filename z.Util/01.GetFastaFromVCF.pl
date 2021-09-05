#! perl

use warnings;
use strict;
use File::Basename;
open R,'<',"./00.GetlocifromVCF.pl.loci.txt" or die "$!";
my %ref;
while(<R>){
    chomp;
    (my $chr,my $loc)=(split/\t/,$_)[0,1];
    $ref{$chr}{$loc} = 1;
}
close R;
my $vcf = shift;
open IN,"zcat $vcf |" or die "$!";
my @head;push @head, 0..8;
my %fa;
srand(time());

while(<IN>){
    next if /^##/;
    chomp;
    if(/^#C/){
        my @line = (split/\t/,$_);
        for(my $i = 9;$i< @line;$i += 1){
            push @head, $line[$i];
        }
    }else{
        my @line = split/\t/,$_;
        my $p;
        next if (!exists $ref{$line[0]}{$line[1]});
        my $tmp_base = $line[3].",".$line[4];
        my @base = split/,/,$tmp_base; # 0 for ref, 1.. for ale
        if($line[8] =~ /AD/){
            for(my $i = 9;$i< @line;$i += 1){
	if ($line[$i] =~/\.\/\./){
	    $p = "-";
	    push @{$fa{$head[$i]}}, $p;
	}else{
	    my @info = split/:/,$line[$i];
	    $info[0] =~ /(\d+)\/(\d+)/;
	    (my $GT1,my $GT2) = ($1,$2);
	    (my $dep_ref,my $dep_alt) = (split/,/,$info[1])[0,1];
	    if($dep_ref == $dep_alt){
	        if ($dep_ref == 0){
	            $p="-";
	            push @{$fa{$head[$i]}}, $p;
	        }else{
	            my $jud = int(rand(100));
	            $p = ($jud < 50)? $base[$GT1]:$base[$GT2];
	            push @{$fa{$head[$i]}}, $p;
	        }
	    }else{
	        $p = ($dep_ref > $dep_alt)? $base[$GT1]:$base[$GT2];
	        push @{$fa{$head[$i]}}, $p;
	    }
	}
            }
        }else{
            for(my $i = 9;$i< @line;$i += 1){
	if ($line[$i] =~/\.\/\./){
	    $p = "--";
	    push @{$fa{$head[$i]}}, $p;
	}else{
	    my @info = split/:/,$line[$i];
	    $info[0] =~ /(\d+)\/(\d+)/;
	    (my $GT1,my $GT2) = ($1,$2);
	    $p = "$base[$GT1]$base[$GT2]";
	    push @{$fa{$head[$i]}}, $p;
	}
            }
        }
    }
}
my $n = basename $0;
open O,'>',"$n.SNPtandem.fa";
for my $sam (sort keys %fa){
    my $a = join"",@{$fa{$sam}};
    print O "\>$sam\n"."$a\n";
}
