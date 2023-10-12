#! perl

use warnings;
use strict;

my ($f,$block,$min,$max) = @ARGV;
print STDERR "USAGE : perl $0 \$block_info \$block_length \$min_ks \$max_ks\n";

$block//= 30;
$min //= -1;
$max //= 0.4;

open IN,'<',$f or die "$!";
my $first = readline IN;
print $first;
while(<IN>){
    chomp;
    my @l = split/,/;
    next if $l[8] < $block;
    next unless ($l[9] < $max && $l[9] > $min);
    $l[-1] = 1;
    print join",",@l;
    print "\n";
}
