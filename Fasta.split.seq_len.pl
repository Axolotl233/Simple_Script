#! perl

use warnings;
use strict;
use Bio::SeqIO;
use File::Basename;
use Cwd qw (abs_path getcwd);

my $h_dir = getcwd();
my $fa = shift or die "USAGE : perl $0 \$fa \$len[default 1000000]\n";
$fa = abs_path($fa);
my $window = shift;
$window //= 1000000;

(my $name = basename $fa) =~ s/(.*?)\..*/$1/;
mkdir $name.".split" if ! -e $name.".split";
chdir $name.".split";

my $s_io = Bio::SeqIO -> new (-file => $fa, -format => "fasta");
while(my $seq_obj = $s_io -> next_seq){
    my $id = $seq_obj -> display_id;
    my $seq = $seq_obj -> seq;
    my $len = $seq_obj -> length;
    my $halfwindow = $window/2 ;
    my $b = $len + $window;
    if($window >= $len){
        chdir ("$name\.split");
        open O,'>',"$id.fa";
        print O ">$id:0-$len\n$seq\n";
        close O;
        next;
    }
  DO:for(my $a = 0;$a < $b;$a += $window){
        my $jud = $a + $window + $halfwindow;
        unless($jud > $len){
            my $s_seq = substr($seq,$a,$window);
            my $end = $a + $window;
            my $n = $id."\:$a-$end";
            #print "$name\.split/$n.fa";exit;
            #print "$s_seq\n";
            chdir ("$name\.split");
            open O,'>',"$n.fa" or die "$!";
            print O ">$n\n$s_seq\n";
            close O;
            chdir ($h_dir);
        }else{
            my $l = $len - $a;
            my $s_seq = substr($seq,$a,$l);
            my $end = $len;
            my $n = $id."\:$a-$end";
            chdir ("$name\.split");
            open O,'>',"$n.fa";
            print O ">$n\n$s_seq\n";
            close O;
            chdir ($h_dir);
            last DO;
        }
    }
}
