#! perl

use warnings;
use strict;

die "perl $0 BlastpOut Bed" if (@ARGV != 2);

my %ref;
my %t;
open R,'<',shift;
while(<R>){
    (my $chr,my $gene) = (split/\t/,$_)[0,3];
    next if $chr =~ /^C/;
    $ref{$gene} = $chr;
    $t{$chr} = 1;
}
close R;

open IN,'<',shift;
my %h;
my @name = sort {$a cmp $b} keys %t;
unshift @name ,"gene_id";
undef %t;
#map{print $_."\n"}@name;
while (<IN>){
    chomp;
    my @line = split/\t/;
    next if (! exists $ref{$line[1]});
    my $chr2 = $ref{$line[1]};
    if(! exists $h{$line[0]}{$chr2}){
        $h{$line[0]}{$chr2} = $line[1];
        $t{$line[0]} = $chr2;
    }else{
        next;
    }
}
print join"\t",@name;
print "\n";
close IN;
for my $k(sort { $a cmp $b } keys %ref){
    print "$k\t";
    my @out;
    for (my $i = 1; $i < @name;$i ++){
        if (exists $h{$k}{$name[$i]}){
            push @out, $h{$k}{$name[$i]};
        }else{
            push @out,"NA";
        }
    }
    print join"\t",@out;
    print "\n";
}
