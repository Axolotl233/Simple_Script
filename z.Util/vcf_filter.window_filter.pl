#! perl

use warnings;
use strict;
use File::Basename;
use MCE::Loop;
use Carp qw /croak/;
use List::Util qw /sum shuffle max min/;
use Statistics::Distributions qw< chisqrprob >;

my $vcf_dir = shift or die "USAGE : perl $0 \$vcf_dir \$window \$window_step \$max_snp_in_window \$threads \[AD\]";
my @vcfs = sort{$a cmp $b} grep{/vcf$/} `find $vcf_dir`;
my %h;

my $vcf = shift or die "$!";
my $window = shift or die "$!";
my $step = shift or die "$!";
my $max = shift or die "$!";
my $threads = shift or die "$!";
my $ad = shift or die "1 : do ad_fiter or 2 : not";

MCE::Loop::init {chunk_size => 1,max_workers => $threads};
mce_loop {&run($_)} @vcfs;

sub run{
    my $f = shift @_;
    my %h;
    (my $head,my $heads_ref) = &get_head($f);
    my @heads = @{$heads_ref};
    my $c = scalar(@heads);
    (my $chr = basename $f) =~ s/(.*?)\..*/$1/;
    my $new = "$chr.window_filter.vcf";
    open my $f_h,'<',$f;
    while(<$f_h>){
        chomp;
        my $l = $_;
        if($ad == 1){
            $l = &ADfilter($_);
        }
        my @line = split/\t/,$l;
        $h{$line[1]} = $l;
    }
    &window_filter(\%h,$new,$head);
    close $f_h;
    unlink $f;
}

sub window_filter{
    my $ref = shift @_;
    my $name = shift @_;
    my $h = shift @_;
    my %t = %{$ref};
    my %t2;
    my @loc = sort {$a <=> $b} keys %t;
    my $last = $loc[-1];
  DO:for(my $start = 0;$start < $last;$start += $step){
        my $jud = 0;
        my $c2 = 0;
        my $end = $start + $window;
        if($end > $last){
            $jud = 1;
            $end = $last;
        }
        my @e;
        for (my $i = $start;$i < $end;$i++){
            if (exists $t{$i}){
	push @e , $i;
            }
        }
        while(scalar(@e) > 2){
            @e = shuffle @e;
            $t2{$e[0]} = 1;
            shift @e;
        }
        last DO if $jud == 1;
    }
    open my $o_h,'>',$name;
    print $o_h,'>',$h;
    for my $k(sort {$a <=> $b} keys %t){
        print $o_h $t{$k}."\n" if ! exists $t2{$k};
    }
    close $o_h;
}

sub ADfilter{
    my $line_ad = shift @_;
    my @a = split /\t/, $line_ad;
    my @b;
    my @c = &Format_check($a[8]);
  D:for(my $i = 9;$i < @a;$i ++){
        unless($a[$i] =~ /\.\/\./){
            @b = split ":", $a[$i];
            if($b[0] eq "0/1"){
	my @ad = (split/,/,$b[1]);
	my $mean = sum(@ad)/2;
	my @m = ($mean,$mean);
	if($mean == 0){
	    $a[$i] = $c[1];
	    next D;
	}
	my $chis = &chi_squared_test(\@ad,\@m);
	if($chis < 0.01){
	    if($ad[0] > $ad[1]){
	        $b[0] = "0/0";
	        $ad[1] = 0;
	        $b[1] = join",",@ad;
	        $a[$i] = join":",@b;
	    }else{
	        $b[0] = "1/1";
	        $ad[0] = 0;
	        $b[1] = join",",@ad;
	        $a[$i] = join":",@b;
	    }
	}
            }
        }
    }
    my $out_ad = join "\t", @a;
    return $out_ad;
}

sub chi_squared_test {
    my $o = shift @_;
    my $e = shift @_;
    my @observed = @{$o};
    my @expected = @{$e};
    my $chi_squared = sum map {
        ($observed[$_] - $expected[$_])**2 / $expected[$_];
    } 0 .. $#observed;
    my $degrees_of_freedom = (scalar@observed) - 1;
    my $probability = chisqrprob($degrees_of_freedom,$chi_squared);
    return $probability;
}

sub Format_check{
    my $ar = shift @_;
    my @fo = split":",$ar;
    my @re;
    if (@fo == 5){
        @re = ("5",".\/.:0,0:0:.:0,0,0");
        return @re;
    }elsif(@fo == 7){
        @re=  ("7",".\/.:0,0:0:.:.:.:0,0,0");
        return @re;
    }
}
sub get_head{
    my $f = shift @_;
    (my $h, my @hs);
    open IN,'<',$f or die "$!";
    while(<IN>){
        if(/^##/){
            $h .= $_;
        }elsif(/^#C/){
            $h .= $_;
            @hs = split/\t/,$_;
            chomp $_ for @hs;
            last;
        }
    }
    close IN;
    return($h,\@hs)
}