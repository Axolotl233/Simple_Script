#! perl

use warnings;
use strict;
use File::Basename;
use Getopt::Long;

(my $convert,my $kaks,my $out,my $alignment);
GetOptions(
           'convert=s' => \$convert,
           'kaks=s' => \$kaks,
           'out=s' => \$out,
           'alignment=s' => \$alignment
           );
if(!$ARGV[0]){
    print STDERR "1:USAGE : perl $0 [orth|para] --convert convert_file1,convert_file2 --alignment alignment_file --kaks kaks_file [--out outfile] \n";
    exit;
}
unless($ARGV[0] ne "orth" || $ARGV[0] ne "para"){
    print STDERR "2:USAGE : perl $0 [orth|para] --convert convert_file1,convert_file2 --alignment alignment_file --kaks kaks_file [--out outfile] \n";
    exit;
}
if(! $convert || ! $kaks){
    print STDERR "3:USAGE : perl $0 [orth|para] --convert convert_file1,convert_file2 --alignment alignment_file --kaks kaks_file [--out outfile] \n";
    exit;
}
(my $n = basename $kaks) =~ s/\.txt//;
$out //= $n.".phase.txt";

my %con = read_info($convert);
my %ali = read_ali($alignment);

open IN,'<',$kaks or die "$!";
open O,'>',$out;
my $p1 =readline IN;
print O $p1;
while(<IN>){
    my @l = split/\t/,$_;
    next if scalar @l < 6;
    $l[0] = $con{$l[0]};
    $l[1] = $con{$l[1]};
    if ($ARGV[0] eq "orth"){
        next if ! exists $ali{"$l[0]-$l[1]"};
        print O join"\t",@l;
    }
    if ($ARGV[0] eq "para"){
        next if exists $ali{"$l[0]-$l[1]"};
        print O join"\t",@l;
    }
}
close IN;
close O;

sub read_ali{
    my $f = shift @_;
    my %h;
    open IN,'<',$f or die "$!";
    while(<IN>){
        chomp;
        my @l = split/,/;
        next if scalar @l == 1;
        next if ($l[1] eq '.');
        $l[0] = $con{$l[0]};
        $l[1] = $con{$l[1]};
        $h{"$l[0]-$l[1]"} = 1;
        $h{"$l[1]-$l[0]"} = 1;
    }
    close IN;
    return %h;
}

sub read_info{
    my $t = shift @_;
    my @fs = split/,/,$t;
    my %h;
    for my $f(@fs){
        open IN,'<',$f or die "$!";
        while(<IN>){
            chomp;
            my @l = split/\t/;
            $h{$l[0]} = $l[1];
        }
        close IN;
    }
    close IN;
    return %h;
}
