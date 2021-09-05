#!/usr/bin/perl
use strict;
use warnings;
use Bio::SeqIO;

my $in=shift or die "perl $0 infile.fa outfile.paml\n";
my $out=shift or die "perl $0 infile.fa outfile.paml\n";

my %h;
my $Len=0;
my $check=0;
my $fa=Bio::SeqIO->new(-format=>"fasta",-file=>$in);
while (my $seq=$fa->next_seq) {
    my $id=$seq->id;
    my $seq=$seq->seq;
    next if $id eq "Cde";
    my $len=length($seq);
    $Len=$len if $Len==0;
    die "wrong length: $in\n" if $Len != $len;
    $h{$id}{seq}=uc$seq;
    $h{$id}{len}=$len;
    my @seq=split(//,uc($seq));
    my $codon="$seq[-3]$seq[-2]$seq[-1]";
    #print $codon,"\n";
    #$check++ if $codon=~/TAG|TAA|TGA/;
}
$Len=$Len-3 if $check>0;
open (O,">$out")||die"$!";
print O "\t",scalar(keys %h),"\t$Len\n";
for my $k1 (sort keys %h){
    print O "$k1\n";
    my @seq=split(//,$h{$k1}{seq});
    my $end=@seq;
    $end=$end-3 if $check > 0;
    for (my $i=0;$i<$end;$i++){
        print O "$seq[$i]";
        if (($i+1) % 60 ==0){
            print O "\n";
        }
    }

    if ($Len % 60 != 0){
        print O "\n";
    }
}
close O;
