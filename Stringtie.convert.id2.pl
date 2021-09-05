#! perl

use warnings;
use strict;

my %h;my %c;
open IN ,'<', shift;
while(<IN>){
    next if /^#/;
    my $jud = (split/\t/,$_)[2];
    #gene_id "MSTRG.6"; transcript_id "Bsta29688.t1";
    next unless $jud eq "transcript";
    $_ =~ /gene_id "(.*?)";/;
    my $mstrg = $1;
    $_ =~ /transcript_id "(.*?)";/;
    my $gene_id = $1;
    $h{$mstrg} = $gene_id;
    $c{$gene_id} += 1;
}
close IN;

for my $key (keys %c){
    if($c{$key} > 1){
        print STDERR "$key duplicate !";
        exit;
    }
}
my %h2;
open IN2,'<',shift;
my $head = readline IN2;
print $head;
while(<IN2>){
    my @l = (split/,/,$_);
    if(exists $h{$l[0]}){
        $l[0] = $h{$l[0]};
    }
    print join",",@l;
}
close IN2;
