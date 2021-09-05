#! perl

use warnings;
use strict;
use Bio::SeqIO;

my $file = shift;
my $o = shift;
$o //= ".";
mkdir $o if ! -e $o;
my $seqio_obj = Bio::SeqIO -> new (-file => $file, -format => "fasta", -alphabet => "dna");

while(my $seq_obj = $seqio_obj -> next_seq){
    my $s = 0;
    my $e = 0;
    my $id = $seq_obj -> display_id;
    my $seq = $seq_obj -> seq;
    $seq = uc($seq);
    my @seq2;
    if($seq =~ /^[Nn]/){
        while($seq =~ /[Nn]/){
            $seq =~ s/([Nn]+)//;
            push @seq2,$1;
            if($seq =~ s/([ATCG]+)//){
	push @seq2 ,$1;
            }
        }
        if(length $seq > 0){
            push @seq2,$seq;
        }
    }else{
        while($seq =~ /[Nn]/){
            $seq =~ s/([ATCGatcg]+)//;
            push @seq2,$1;
            if($seq =~ s/([Nn]+)//){
	push @seq2,$1;
            }
        }
        if(length $seq > 0){
            push @seq2,$seq;
        }
    }       
    #my @seq = split//,$seq;
    #@seq = map{uc($_)} @seq;
    #next if (scalar @seq == 0);
    #my $start_base = $seq[0];
    my $c = 0;
    #my @seq2 = &array_creat(\@seq,$start_base);
    #map{print $_;print "\n";exit;} @seq2;exit;
    for my $se (@seq2){
        if($se =~ /[nN]/){
            $s = $e;
            $e = $s + length($se);
        }else{
            $s = $e;
            $e = $s + length($se);
            open O,'>',"$o/$id-$c.fa";
            print O ">$id\_$s\_$e\n$se\n";
            close O;
            print STDERR "$id$c\t".length($se)."\n";
            $c += 1;
        }
    }
}

sub array_creat{
    my $ref = shift @_;
    my $mark = (shift @_);
    my $c = 0;
    my @a = @{$ref};
    my @b;
    for(my $i = 0;$i < (scalar @a) - 1;$i ++){
        if ($mark eq "N"){
            if($a[$i] eq $mark){
	$b[$c] .= $a[$i];
            }else{
	$b[$c+1] .= $a[$i];
	if($a[$i+1] eq $mark){
	    $c += 2;
	}
            }
        }else{
            if($a[$i] ne "N"){
	$b[$c] .= $a[$i];
            }else{
	$b[$c+1] .= $a[$i];
	if($a[$i+1] ne "N"){
	    $c += 2;
	}
            }
        }
    }
    return @b;
}
