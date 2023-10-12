#! perl

use warnings;
use strict;
use Bio::SeqIO;
use File::Basename;

my $ref = shift or die "need ref";

open R,'<',$ref or die "$!";
my %h;
while(<R>){
    chomp;
    (my $old,my $new) = (split/\s+/,$_)[0,1];
    $h{$old} = $new;
}
my $seqio_obj = Bio::SeqIO -> new(-file => shift, -format =>"fasta");
while(my $seq_obj = $seqio_obj -> next_seq){
    my $o_id = $seq_obj -> display_id;
    my $seq = $seq_obj -> seq;
    $seq = uc($seq);
    my $id;
    if(exists $h{$o_id}){
        $id = $h{$o_id};
    }else{
        $id = $o_id;
    }
    print ">$id\n$seq\n";
}
