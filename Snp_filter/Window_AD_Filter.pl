#! perl

use warnings;
use strict;
use File::Basename;
use MCE::Loop;
use Carp qw /croak/;
use List::Util qw /sum shuffle max min/;
use Statistics::Distributions qw< chisqrprob >;

print STDERR "###   USAGE : perl $0 \$compress_vcf \$window \$window_step \$max_snp_in_window \$threads \[AD\]\n";

my $vcf = shift or die "$!";
my $window = shift or die "$!";
my $step = shift or die "$!";
my $max = shift or die "$!";
my $threads = shift or die "$!";
my $ad = shift or die "1 : do ad_fiter or 2 : not";

(my $ame = basename $vcf) =~ s/vcf.gz/win.vcf.gz/;
print STDERR "###   step 1 : split vcf\n";
my $v_header = &split_vcf($vcf,"split");
#my $v_header = "#test\n";
print STDERR "###   step 1 : done!\n";
print STDERR "###   step 2 : filter vcf\n";
MCE::Loop::init {chunk_size => 1,max_workers => $threads};
my @files = grep {/vcf$/} `find ./split`;
chomp $_ for @files;
mce_loop {&run($_)} @files;
my @phase = sort{$a cmp $b}grep {/phase$/} `find ./split`;
chomp $_ for @phase;
open H,'>',"tmp.header";
print H $v_header;
my $f_u = join " ",@phase;
`cat tmp.header $f_u |gzip - > $ame`;
unlink("tmp.header");

sub run{
    my $f = shift @_;
    my %h;
    (my $name = $f) =~ s/vcf/phase/;
    print STDERR "###   phase $f\n";
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
    &window_filter(\%h,$name);
    close $f_h;
}

sub window_filter{
    my $ref = shift @_;
    my $name = shift @_;
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

sub split_vcf{
    my $vcf = shift;
    my $out_dir = shift;
    open IN,"zcat $vcf |" or die "$!";
    my $head;
    while(<IN>){
        if(/^##/){
            $head .= $_;
        }elsif(/^#C/){
            $head .= $_;
            last;
        }
    }
    my $con;
    my $chr = "NA";
    mkdir "$out_dir" if !-e "$out_dir";
    while(<IN>){
        my @line = split/\t/;
        if($chr ne "NA" && $chr ne $line[0]){
            open O,'>',"$out_dir/$chr.vcf";
            #print O $head;
            print O $con;
            close O;
            $chr = $line[0];
            $con = $_;
        }else{
            if($chr eq "NA"){
	$chr = $line[0];
            }
            $con .= $_;
        }
    }
    open O,'>',"$out_dir/$chr.vcf";
    print O $con;
    close O;
    return $head;
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
