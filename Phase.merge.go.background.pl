#! perl

use warnings;
use strict;
use Getopt::Long;

(my @type1,my@type2,my $out);
GetOptions(
           'type1=s' => \@type1,
           'type2=s' => \@type2,
           'out' => \$out
          );
$out //= "merge.go.out";
my $c = 0;
for my $s (\@type1,\@type2){
    $c += scalar @{$s}
}
if($c == 0){
    print STDERR "perl $0 --type1 xxxx --type1 xxx --type2 xxx --type2 xxx\n";
    exit;
} 
my %h;
%h = (%h , &type1(\@type1));
%h = (%h, &type2(\@type2));
%h = (%h, filter(\%h));
open O,'>',$out;
for my $k(sort{$a cmp $b} keys %h){
    print O "$k\t";
    print O join "\t",@{$h{$k}};
    print O "\n";
}
close O;

sub type1{
    my $ref_a = shift @_;
    my %t;
    my @f = @{$ref_a};
    for my $e (@f){
        open IN ,'<',$e;
        while(<IN>){
            next if /^#/;
            next if /^$/;
            chomp;
            my @l = split/\s+/;
           push @{$t{$l[0]}} ,$l[1];
        }
        close IN;
    }
    return %t;
}

sub type2{
    my $ref_a = shift @_;
    my %t;
    my @f = @{$ref_a};
    for my $e (@f){
        open IN ,'<',$e or die "$!";
        while(<IN>){
            next if /^#/;
            next if /^$/;
            chomp;
            my @l = split/\s+/;
            my $n = shift @l;
            push @{$t{$n}} ,@l;
        }
        close IN;
    }
    return %t;
}

sub filter{
    my $ref_h = shift @_;
    my %b = %{$ref_h};
    for my $k(keys %b){
        my @a = @{$b{$k}};
        my %t;
        $t{$_} = 1 for @a;
        @{$b{$k}} = (sort{$a cmp $b} keys %t); 
    }
    return %b;
}
