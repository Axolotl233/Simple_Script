#! perl

use warnings;
use strict;
use File::Basename;


my $gff = shift or die "USAGE : perl $0 unsort.gff";
(my $name = basename $gff) =~ s/gff3?//;

print STDERR "WARN : this script is not used for sort gff which contain \"alternative splicing\"";

open R,'<',$gff;
my @line;
my %h;
my $head;
my $first_line;

H:while(<R>){
    if (/^#/){
        $head .= $_;
    }else{
        chomp;
        $first_line = $_;
        last H;
    }
}

J:while(1){
    @line = split/\t/,$first_line;
    if($line[2] ne "gene"){
        print STDERR "$. : maybe format error";
        $head .= $first_line;
    }else{
        last J;
    }
}

(my $last_gene = $line[8]) =~ s/ID=//;
$h{$line[0]}{$last_gene} .= $first_line."\n";

while(<R>){
    chomp;
    @line =split/\t/;
    if ($line[2] =~ /gene/){
        (my $gene = $line[8]) =~ s/ID=//;
        if($gene ne $last_gene){
            $h{$line[0]}{$gene} .= $_."\n";
            $last_gene = $gene;
        }else{
            die "$. : duplicate gene exists\n";
        }
    }else{
        $h{$line[0]}{$last_gene} .= $_."\n";
    }
}

my %out;

for my $chr (sort {$a cmp $b} keys %h){
    for my $g (sort {$a cmp $b} keys %{$h{$chr}}){
        my @tmp = &gene_sort($h{$chr}{$g});
        $out{$tmp[0]}{$tmp[1]} = $tmp[2];
    }
}

open OUT,'>',$name."sort.gff";
for my $k1(sort {$a cmp $b} keys %out){
    for my $k2 (sort{$a <=> $b}keys %{$out{$k1}}){
        print OUT "$out{$k1}{$k2}";
    }
}

sub gene_sort{
    my $da = shift @_;
    my @part = split/\n/,$da;

    my @s;
    my @e;
    my @row;

    my @o;
    my $x = "NA";

    my $re;

    for (@part){
        my @l = split/\t/;
        push @row ,$_;
        push @s,$l[3];
        push @e,$l[4];
        if($x eq "NA"){
            $x = $l[0];
        }else{
            if($x ne $l[0]){
	die "Error Chr name :\n\n$da";
            }
        }
        push @o, $l[3];
    }

    for my $i(sort {$s[$a] <=> $s[$b] or $e[$b] <=> $e[$a] } 0..$#row){
        $re .= $row[$i]."\n";
    }
    my $min_loc = (sort{$a <=> $b} @o)[0];
    return ($x,$min_loc,$re);
}
