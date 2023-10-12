#! perl

use warnings;
use strict;

my $f = shift or die "need file\n";
my $w = shift;
my $length = shift;
$w //= 0;
#$length //= 243560759;
$length //= 86145070;
#$length //= 256704079;
#$length //= 83355272;
my $mu = shift;
my $gen_time = shift;
$mu //= 6e-9;
$gen_time = 1;
open IN,'<',$f;
my @head = split/\t/,(readline IN);
$head[-1] =~ s/.*\((.*)\)/$1/;
$head[-1] =~ s/\s//g;
my %o;
my $c = 0;
while(<IN>){
    next if /^Model/;
    my @l = split/\s+/;
    $o{$c} = [$l[2],$l[3],$l[5],$l[6]];
    $c += 1;
}
my @type = split/,/,$head[-1];
print "$head[2]\t$head[3]\t$head[5]\tn_theta\tn_ref\t$head[6]\n";
for my $k (sort {${$o{$a}}[1] <=> ${$o{$b}}[1]}keys %o){
    my @a = @{$o{$k}};
    my @p = split/,/,$a[-1];
    die "error format\n" if scalar @p ne scalar @type;
    my $ntheta=$a[2]/$length;
    my $nref=$ntheta/(4*$mu);
    print "$a[0]\t$a[1]\t$a[2]\t$ntheta\t$nref\t";
    for(my $i = 0;$i < @type;$i += 1){
        if($type[$i] =~ /^n/i){
            $p[$i] = $p[$i] * $nref;
        }elsif($type[$i] =~ /^t/i){
            $p[$i] = $p[$i] * 2 * $gen_time* $nref;
        }elsif($type[$i] =~ /^m/i){
            $p[$i] = $p[$i] / (2 * $nref);
        }
    }
    print join",",@p;
    print "\n";
    if($w == 0){
        last;
    }
}
