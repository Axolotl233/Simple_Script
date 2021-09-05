#! perl

use warnings;
use strict;
use Getopt::Long;

my ($fst,$cds,$out,$v,$filter);
GetOptions(
           'fst=s' => \$fst,
           'cds=s' => \$cds,
           'out=s' => \$out,
           'v=s' => \$v,
           'filter=s' => \$filter
          );
my %j;my $r = 0;
$out //= "Cds.fixsite.stat.txt";
$v //= 0.95;
$filter //=0;
my $n_fix = 0;
my $fix = 0;
if(!$fst||!$cds){
    &print_help();
    exit;
}
my %s;
open IN,'<',$fst or die "$!";
readline IN;
while(<IN>){
    my @l = split/\s+/;
    next if $l[2] =~ /nan/;
    next if $l[2] < 0;
    if($l[2] >= $v){
        $s{$l[0]}{$l[1]} = "fix";
        $j{$l[0]}{$l[1]} = 1 if $l[2] == 1;
    }else{
        $s{$l[0]}{$l[1]} = "n_fix";
    }
}
close IN;
my %cds;
my %o;
open IN,'<',$cds or die "$!";
while(<IN>){
    chomp;
    my @l = split/\t/;
    my @t = split/;/,$l[3];
    my $g_fix = 0;my $g_nfix = 0;
    my @f_s;my @uf_s;
    for my $e (@t){
        my ($s,$e) = split/\-/,$e;
        for(my $i = $s;$i<=$e;$i+=1){
            if(exists $s{$l[0]}{$i}){
	if($s{$l[0]}{$i} eq "fix"){
	    #$r += 1 if exists $j{$l[0]}{$i};
	    $g_fix += 1;
	    $fix += 1;
	    push @f_s,$i;
	}elsif($s{$l[0]}{$i} eq "n_fix"){
	    $g_nfix += 1;
	    $n_fix += 1;
	    push @uf_s,$i;
	}
            }
        }
    }
    my $a = $g_nfix + $g_fix;
    @f_s = ("na") if scalar @f_s == 0;
    @uf_s = ("na") if scalar @uf_s == 0;
    my $f_site = join",",@f_s;
    my $uf_site = join",",@uf_s;
    my @p = ($l[0],$l[1],"$g_fix,$g_nfix",$f_site,$uf_site);
    if($filter =~ /\d+/){
        if($g_fix > $filter){
            @{$o{$l[1]}} = @p;
        }
    }else{
        @{$o{$l[1]}} = @p;
    }
}
close IN;
open O,'>',$out;
for my $k(sort {$a cmp $b} keys %o){
    my @t = @{$o{$k}};
    $t[2] .= ",$fix,$n_fix";
    my $c = join"\t",@t;
    print O $c;
    print O "\n";
}
#print STDERR $r;
close O;
sub print_help{
    print STDERR"
  Usage: perl $0 --fst site_fst_file --cds cds.bed
      --fst    fst 
      --cds    bed [chr gene mrna cds1_start-cds1_end;cds2_start-cds2_end;..] 
    Options:
      --out    defalut [Cds.fixsite.stat.txt]
      --v      fst threshold [0.9]
      --filter min fix sites [0]
";
}
