#! perl

use warnings;
use strict;
use MCE::Loop;
use File::Basename;
use List::Util qw(sum);
use Getopt::Long;

(my $dir,my $chr,my $window,my $step,my $threads,my $abs);
GetOptions(
           'dir=s' => \$dir,
           'chr=s' => \$chr,
           'window=s' => \$window,
           'step=s' => \$step,
           'threads=s' => \$threads,
           'abs' => \$abs
          );
for my $s ($dir,$chr){
    if(!$s){
        print STDERR 
        "###   USAGE : perl $0 --chr chr_file\[chr length\] --dir \$dir [--window 10000 --step 2500 --threads 10 --abs]\n";
        exit;
    }
}
$window //= 10000;
$step //= 2500;
$threads //= 10;

open IN,'<',$chr or die "$!";
my %r;
while(<IN>){
    next if /^#/;
    my @line = split/\s+/;
    $r{$line[0]} = $line[1];
}
close IN;

my @files = sort {$a cmp $b} grep {/.out.xpnsl.out.norm$/} `find $dir`;
chomp $_ for @files;

MCE::Loop::init {chunk_size => 1,max_workers => $threads};
mce_loop {&run($_)} @files;

my @phase = sort{$a cmp $b}grep {/stat.txt$/} `find $dir`;
chomp $_ for @phase;
my $f_u = join " ",@phase;
(my $w_name = ($window/1000)."K");
my $s_name = ($step/1000)."K";
`cat $f_u > Xpnsl.$w_name.$s_name.txt`;

sub run{
    my $f = shift @_;
    (my %h,my %s);
    (my $name = basename $f) =~ s/\.out.xpnsl.out.norm//;
    my $d = dirname $f;
    open my $f_h,'<',$f;
    readline $f_h;
    while(<$f_h>){
        chomp;
        my @line = split/\t/;
        $h{$line[1]} = $line[7];
    }
    close $f_h;
    my $last = $r{$name};
  DO:for(my $start = 0;$start < $last;$start += $step){
        my $jud = 0;
        my $c2 = 0;
        my $end = $start + $window;
        if($end > $last){
            $jud = 1;
            $end = $last;
        }
        my @tmp;
        my $num = 0;
        for (my $i = $start;$i <= $end;$i++){
            if (exists $h{$i}){
	$num += 1;
	push @tmp , ($h{$i});
            }
        }
        unless(scalar(@tmp) == 0){
            my $mean = (sum(@tmp)/scalar(@tmp));
            $s{$start} = [$name,$start,$end,$num,$mean];
        }
        last DO if $jud == 1;
    }
    open my $o_h,'>',"$d/$name.stat.txt";
    for my $k (sort {$a <=> $b} keys %s){
        my $p = join"\t",@{$s{$k}};
        print $o_h $p."\n";
    }
    close $o_h;
}
