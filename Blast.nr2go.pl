#! perl

use warnings;
use strict;
use Getopt::Long;
use File::Basename;
use Bio::SeqIO;

(my $blast,my $idmapping,my $max,my $out,my $i,my $c,my $pep,my $type);
GetOptions(
           'blast=s' => \$blast,
           'idmapping=s' => \$idmapping,
           'max=s' => \$max,
           'out=s' => \$out,
           'ident=s' => \$i,
           'cov=s' => \$c,
           'pep=s' => \$pep,
           'type=s' => \$type
          );
$idmapping //= "/data/01/user112/database/nr/idmapping.tb";
$max //= 5;
$i //= 0.6;
$c //= 0.6;
$type //= "nr";
exit if (! $blast || ! $pep);
my %len = &load_fasta($pep);
my $name = basename $blast;
$out = $name.".$type.go.out";
my %blast = %{&blast_load($blast)};
die "zero blast\n" if scalar keys %blast == 0;
my %o;

open IN,'<',$idmapping or die "$!";
while(<IN>){
    chomp;
    my @l = split/\t/;
    if($type eq "nr"){
        if($l[3] ne ""){
            next if $l[7] eq "";
            if(exists $blast{$l[3]}){
	(my $go = $l[7]) =~ s/\s+//;
	my @gos = split/;/,$go;
	for my $g (@{$blast{$l[3]}}){
	    push @{$o{$g}} , @gos;
	}
            }        
        }
        if($l[-1] ne ""){
            next if $l[7] eq "";
            if(exists $blast{$l[-1]}){
	(my $go = $l[7]) =~ s/\s+//;
	my @gos = split/;/,$go;
	for my $g (@{$blast{$l[-1]}}){
	    push @{$o{$g}} , @gos;
	}
            }
        }
    }elsif($type eq "swissprot"){
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
        if(exists $len{$l[0]}){
            my $q_len = $len{$l[0]};
            my $blst_i  = $l[2]/100;
            my $blst_c  = ($l[7]-$l[6])/$q_len;
            if($blst_i>=$i and $blst_c>=$c){
	if($type eq "swissprot"){
	    $l[1] =~ s/(.*?)\..*/$1/;
	}
	push @{$h{$l[0]}} , [$l[1],$l[-1]];
            }
        }
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
            for(my $i = 0;$i <= ($max-1);$i++){
                my $n = @{$a[$i]}[0];
                push @{$p{$n}} , $k;
            }
        }else{
            for(my $i = 0;$i <= ($num-1);$i++){
                my $n = @{$a[$i]}[0];
                push @{$p{$n}} , $k;
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
