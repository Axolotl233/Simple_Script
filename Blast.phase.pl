#! perl

use warnings;
use strict;
use Getopt::Long;
use File::Basename;
use Bio::SeqIO;

(my $blast,my $max,my $out,my $i,my $c,my $pep);
GetOptions(
           'blast=s' => \$blast,
           'max=s' => \$max,
           'out=s' => \$out,
           'ident=s' => \$i,
           'cov=s' => \$c,
           'pep=s' => \$pep,
          );
$max //= 1;
$i //= 0.6;
$c //= 0.6;
exit if (! $blast || ! $pep);
my %len = &load_fasta($pep);
my $name = basename $blast;
$out = $name.".phase";
my %blast = %{&blast_load($blast)};
open O,'>',$out;
for my $k (sort {$a cmp $b} keys %blast){
    print O @{$blast{$k}};
}
close O;


sub blast_load{
    my $f = shift @_;
    my %h;
    open IN,'<', $f or die "$!";
    while(<IN>){
        my @l = split/\t/;
        chomp $l[-1];
        if(exists $len{$l[0]}){
            my $q_len = $len{$l[0]};
            my $blst_i  = $l[2]/100;
            my $blst_c  = ($l[7]-$l[6])/$q_len;
            if($blst_i>=$i and $blst_c>=$c){
	push @{$h{$l[0]}} , [$l[-1],$_];
            }
        }
    }
    close IN;
    my %h2 = &blast_filter(\%h,$max);
    return \%h2
}

sub blast_filter{
    my $ref = shift @_;
    my %h = %{$ref};
    my %p;
    for my $k (keys %h){
        my @a = @{$h{$k}};
        @a = sort{${$b}[0] <=> ${$a}[0]} @a;
        my $num = scalar @a;
        if($num >= $max){
            for(my $i = 0;$i <= ($max-1);$i++){
                my $n = @{$a[$i]}[1];
                push @{$p{$a[$i]}} , $n;
            }
        }else{
            for(my $i = 0;$i <= ($num-1);$i++){
                my $n = @{$a[$i]}[1];
                push @{$p{$a[$i]}} , $n;
            }
        }
    }
    return %p;
}

sub load_fasta{
    my $pep = shift @_;
    my %h;
    my $s_obj = Bio::SeqIO -> new(-file => $pep);
    while(my $s_io = $s_obj -> next_seq){
        my $id =$s_io -> display_id;
        my $len = $s_io -> length;
        $h{$id} = $len;
    }
    return %h;
}
