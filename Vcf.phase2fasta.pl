#! perl

use warnings;
use strict;

my $vcf = shift;
my $ref = shift;

my %r;
%r = &read_ref($ref) if ($ref);

my %fa;
my %fa2;

open IN,'<',$vcf or die "$!";
my @head;
push @head, 0..8;

D:while(<IN>){
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
        if($ref){
            next D if (!exists $r{$line[0]}{$line[1]});
        }
        
        my @base = ($line[3] , $line[4]); # 0 for ref, 1.. for ale
        for(my $i = 9;$i< @line;$i += 1){    
            if ($line[$i] =~ /^\.\/\./){
	$p = "--";
	$fa2{$head[$i]}{$line[0]}{$line[1]} = $p;
	#push @{$fa{$head[$i]}}, $p;
            }else{
	my @info = split/:/,$line[$i];
	$info[0] =~ /(\d+)\/(\d+)/;
	(my $GT1,my $GT2) = ($1,$2);
	$p = "$base[$GT1]$base[$GT2]";
	$fa2{$head[$i]}{$line[0]}{$line[1]} = $p;
            }
        }
    }
}

for my $sam (sort {$a cmp $b} keys %fa2){
    print ">$sam\n";
    for my $chr (sort {$a cmp $b} keys %{$fa2{$sam}}){
        for my $loc (sort {$a <=> $b} keys %{$fa2{$sam}{$chr}}){
            print "$fa2{$sam}{$chr}{$loc}";
        }
    }
    print "\n";
}

sub read_ref{
    my $f = shift @_;
    open R,'<', $f or die "$!";
    my %h;
    while(<R>){
        chomp;
        my @l=split /\s+/,$_;
        #(my $chr,my $loc)=(split /\t/,$_ )[0,1];
        my $chr=$l[0];
        my $loc=$l[1];
        $h{$chr}{$loc} = 1;
    }
    close R;
    return %h;
}
