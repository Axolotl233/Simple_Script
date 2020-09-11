#! perl

use warnings;
use strict;
use Bio::SeqIO;

open R,'<',"Chr.list.txt";

my %h;
my @a;

while(<R>){
    chomp;
    (my $old,my $new) = (split/\t/,$_)[0,1];
    $h{$old} = $new;
    push @a,$new;
}

my %s1;
my %s2;
my $seqio_obj = Bio::SeqIO -> new(-file => shift, -format =>"fasta");
while(my $seq_obj = $seqio_obj -> next_seq){
    my $o_id = $seq_obj -> display_id;
    my $seq = $seq_obj -> seq;
    if(exists $h{$o_id}){
        my $id = $h{$o_id};
        $s1{$id} = $seq;
    }else{
        $s2{$o_id} = $seq;
    }
}
for (@a){
    print ">$_\n$s1{$_}\n";
}      
print ">$_\n$s2{$_}\n" for sort  keys %s2;
