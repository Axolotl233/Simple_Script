#! perl

use warnings;
use strict;
use Bio::SeqIO;
use Cwd qw(abs_path);
use File::Basename;
print STDERR "USAGE : perl $0 \$dir \[contain file name xxxx.cds.xxx xxxx.pep.xxx\]"
print STDERR "default seprate symbol \. \n";
my $dir = shift or die "need dir contain sequence\n";
my @files = sort{$a cmp $b} grep{/cds/} `find ./$dir`;
for my $file(@files){
    chomp $file;
    (my $name = basename $file) =~ s/(.*?)\..*/$1/;
    next if -e "clean_data/$name.cds.clean.fa";
    my $seq_dir = dirname $file;
    (my $p_name = basename $file) =~ s/cds/pep/;
    $p_name = $seq_dir."/$p_name";
    my %h;
    my $s_io = Bio::SeqIO -> new(-file => $file,-format =>"fasta");
    while(my $s = $s_io -> next_seq){
        my $id = $s -> display_id;
        my $seq = $s -> seq;
        my $len = $s -> length;
        (my $g_id = $id) =~ s/(.*)\..*/$1/;
        push @{$h{$g_id}} ,[$id,$seq,$len];
    }
    my %new;
    open O,'>',"clean_data/$name.cds.clean.fa";
    for my $k (sort {$a cmp $b} keys %h){
        my @gene = @{$h{$k}};
        @gene = sort {$b->[2] <=> $a->[2]} @gene;
        my $id = $gene[0] -> [0];
        my $seq = $gene[0] -> [1];
        print O ">$id\n$seq\n";
        $new{$id} = 1;
    }
    close O;
    open O,'>',"clean_data/$name.pep.clean.fa";
    my $p_io = Bio::SeqIO -> new(-file => $p_name,-format =>"fasta");
    while(my $p = $p_io -> next_seq){
        my $id = $p -> display_id;
        my $seq = $p -> seq;
        if(exists $new{$id}){
            print O ">$id\n$seq\n";
        }
    }
    close O;
}
