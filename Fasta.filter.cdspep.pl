#! perl

use warnings;
use strict;
use File::Basename;
use Bio::SeqIO;

my $cds = shift;
my $pep = shift;

unless ($pep){
    print STDERR "USAGE : perl $0 file.cds file.pep\n";
    exit;
}

print STDERR"#####   cds and pep must have same sequence name\n";


(my $pname = basename $pep) =~ s/\.pep(\.fa)?//;
(my $cname = basename $cds) =~ s/\.cds(\.fa)?//;

open O,'>',"$pname.fix.pep" or die "can't create pep file\n";

my %h;
my %c;

my $seqio_obj = Bio::SeqIO -> new (-file => $pep, -format => "fasta");
while(my $seq_obj = $seqio_obj -> next_seq){
    my $seq = $seq_obj -> seq;
    my $id = $seq_obj -> display_id;
    $h{$id} = $seq;
}

foreach my $key (keys %h){

    unless($h{$key} =~ /\w\*\w/) {
        if($h{$key} =~/\*$/){
            print O ">$key\n"."$h{$key}\n";
            $c{$key} += 1;
        }
    }
}
close O;

open O,'>',"$cname.fix.cds" or die "can't create cds file\n";

my $m = Bio::SeqIO -> new (-file => $cds, -format => "fasta");
while(my $seq_obj = $m -> next_seq){
    my $id = $seq_obj -> display_id;
    next unless exists $c{$id};
    if ($c{$id} > 1){
        print STDERR "$id duplicate\n";
    }
    my $seq = $seq_obj -> seq;
    print O ">$id\n$seq\n";
}
print STDERR "#####   All done\n";
close O;
