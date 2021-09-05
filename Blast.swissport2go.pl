#! perl

use warnings;
use strict;
use Getopt::Long;
use File::Basename;

(my $blast,my $idmapping,my $max,my $out);
GetOptions(
           'blast=s' => \$blast,
           'idmapping=s' => \$idmapping,
           'max=s' => \$max,
           'out=s' => \$out
          );
$idmapping //= "/data/01/user112/database/nr/idmapping.tb";
$max //= 5;
exit if (! $blast);
my $name = basename $blast;
$out = $name."go.out";
my %blast = %{&blast_load($blast)};
my %o;

open IN,'<',$idmapping or die "$!";
while(<IN>){
    chomp;
    my @l = split/\t/;
    if($l[0] ne ""){
        next if $l[7] eq "";
        if(exists $blast{$l[0]}){
            (my $go = $l[7]) =~ s/\s+//;
            my @gos = split/;/,$go;
            for my $g (@{$blast{$l[0]}}){
	push @{$o{$g}} , @gos;
            }
        }
    }
}

close IN;
open O,'>',"$out" or die "$!";
for my $k(sort {$a cmp $b} keys %o){
    my $p = join"\t",@{$o{$k}};
    print O "$k\t$p\n";
}
close O;

sub blast_load{
    my $f = shift @_;
    my %h;
    open IN,'<', $f or die "$!";
    while(<IN>){
        chomp;
        my @l = split/\t/;
        $l[1] =~ s/(.*?)\..*/$1/;
        #print $l[1];exit;
        push @{$h{$l[0]}} , [$l[1],$l[-1]];
    }
    close IN;
    %h = &blast_filter(\%h,$max);
    return \%h
}

sub blast_filter{
    my $ref = shift @_;
    my %h = %{$ref};
    my %p;
    for my $k (keys %h){
        my @a = @{$h{$k}};
        @a = sort{${$b}[1] <=> ${$a}[1]} @a;
        my $num = scalar @a;
        if($num >= $max){
            for(my $i = 0;$i < ($max-1);$i++){
                my $n = @{$a[$i]}[0];
                push @{$p{$n}} , $k;
            }
        }else{
            for(my $i = 0;$i < ($num-1);$i++){
                my $n = @{$a[$i]}[0];
                push @{$p{$n}} , $k;
            }
        }
    }
    return %p;
}
