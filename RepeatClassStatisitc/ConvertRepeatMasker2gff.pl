#!/usr/bin/perl
use strict;
use warnings;

my $in=shift;
my $out=shift;
my $type=shift;
die "Usage:\nperl $0 <inputfile> <outputfile> <TE|TP|Denovo>\nTE for RepeatMasker, TP for RepeatProteinMask, Denovo for RepeatModeler\n" if (! $type);

open (IN,"$in")||die"$!";
open (OUT,">$out")||die"$!";

print OUT "##gff-version 3\n";
my $line=0;
while (<IN>) {
    chomp;
    s/^\s+//;
    next if (/^(SW|score|pValue)\s+/);
    next if /^\s*$/;
    my @a=split(/\s+/,$_);
    $line++;
    my $outline=sprintf("%05d",$line);
    if ($type eq 'TE'){
        print OUT "$a[4]\tRepeatMasker\tTransposon\t$a[5]\t$a[6]\t$a[0]\t$a[8]\t.\tID=$type$outline;Target=lcl|$a[9] $a[11] $a[12];Class=$a[10];PercDiv=$a[1];PercDel=$a[2];PercIns=$a[3]\n";
    }elsif($type eq 'TP'){
        if (scalar(@a) == 10){
            next;
            ($a[9],$a[10])=($a[8],$a[9]);
            $a[8]="Unkown";
        }
        print OUT "$a[3]\tRepeatProteinMask\tTEprotein\t$a[4]\t$a[5]\t$a[1]\t$a[6]\t.\tID=TP$outline;Target=$a[7] $a[9] $a[10];Class=$a[8];pValue=$a[0];\n";
    }elsif($type eq 'Denovo'){
        print OUT "$a[4]\tRepeatModeler\tTransposon\t$a[5]\t$a[6]\t$a[0]\t$a[8]\t.\tID=Denovo_TE$outline;Target=$a[9] $a[11] $a[12];Class=$a[10];PercDiv=$a[1];PercDel=$a[2];PercIns=$a[3]\n";
    }else{
        die "wrong type:  $_\n";
    }
}
close IN;
close OUT;
