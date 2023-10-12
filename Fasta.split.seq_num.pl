#! perl

use warnings;
use strict;
use Bio::SeqIO;
use File::Basename;
use Cwd qw (abs_path getcwd);
my $fa = shift or die "Need Fasta File\n";
$fa = abs_path($fa);
my $item = shift;
$item //= 10000;

(my $name = basename $fa) =~ s/(.*?)\..*/$1/;
mkdir $name.".split" if ! -e $name.".split";
chdir $name.".split";

my $s_io = Bio::SeqIO -> new (-file => $fa, -format => "fasta");
my $c = 0;
my $d = 1;
my $p_n = 1;
my $p;
my $e_n = 0;
my $s_n = 0;
while(my $s = $s_io -> next_seq){
    my $id = $s -> display_id;
    my $seq = $s -> seq;
    if($item == 1){
        open O,'>',"$id.fa";
        print O">$id\n$seq\n";
        close O;
        next;
    }
    $c += 1;
    $p .= ">$id\n$seq\n";
    if($c == ($d * $item)){
        $e_n = $d * $item;
        $s_n = $e_n - $item + 1;
        open O,'>',"$name.$s_n-$e_n.fa";
        print O $p;
        close O;
        $p = "";
        $d += 1;
        
    }
}
unless($item == 1){
    my $last = $e_n + 1;
    open O,'>',"$name.$last-$c.fa";
    print O $p;
    close O;

}
