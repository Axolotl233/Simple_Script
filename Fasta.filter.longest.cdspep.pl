#! perl

use warnings;
use strict;
use Bio::SeqIO;
use File::Basename;

if(scalar @ARGV != 2){
    print STDERR "USAGE : perl $0 \$cds \$pep \[id format : xxxxxxxxx.xx\]\n";
    exit;
}

my $cds = $ARGV[0];
my $pep = $ARGV[1];
my %h;

my $c_obj = Bio::SeqIO -> new(-file => $cds, -format => "fasta");
while(my$c_io = $c_obj -> next_seq){
    my $id = $c_io -> display_id;
    my $len = $c_io -> length;
    (my $g_id = $id) =~ s/(.*)\..*/$1/;
    push @{$h{$g_id}} , [$id,$len];
}
my %new;
for my $k (sort {$a cmp $b} keys %h){
    my @gene = @{$h{$k}};
    @gene = sort {$b->[1] <=> $a->[1]} @gene;
    my $id = $gene[0] -> [0];
    $new{$id} = 1;
}
&print_res($cds,"cds");
&print_res($pep,"pep");

sub print_res{
    my $fa = shift @_;
    my $type = shift @_;
    (my $name = basename $fa) =~ s/(.*?)\..*/$1/;
    open O,'>',"$name.clean.$type.fa";
    my $s_obj = Bio::SeqIO -> new(-file => $fa, -format => "fasta");
    while(my $s_io = $s_obj -> next_seq){
        my $id = $s_io -> display_id;
        my $seq = $s_io -> seq;
        if(exists $new{$id}){
            print O ">$id\n$seq\n";
        }
    }
    close O;
}
