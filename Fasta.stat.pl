#! perl

use warnings;
use strict;
use Bio::SeqIO;
use Getopt::Long;
use List::Util qw(sum);

my $method = shift;
my $fa = shift;

my %r;
for (qw/gc len num gap/){
    $r{$_} = 1
}

if(!$method ){
    print STDERR "USAGE : perl $0 [gc|len|num|gap]\n";
    exit;
} else{
    if(!exists $r{$method}){
        print STDERR "USAGE : perl $0 [gc|len|num|gap]\n";
        exit;
    }
}

if ($method eq "gc"){
    &gc_stat($fa);
}
if ($method eq "len"){
    &len_stat($fa);
}

sub len_stat{
    my ($b,$)
}


sub gc_stat{
    my ($e);
    GetOptions(
               'e' => \$e
              );
    my $f = shift @_;
    if (!$f){
        print STDERR "USAGE perl $0 gc \$fa [-e: stat with contig]";
        exit;
    }
    my @b = (0,0,0,0,0);
    my $oa = 0;
    print "id\tA\tT\tC\tG\tN\tGC\tother\n";
    my $s_obj = Bio::SeqIO -> new(-file => $f,-format => "fasta" );
    while(my $s_io = $s_obj->next_seq){
        my $id = $s_io -> display_id;
        my $len = $s_io -> length;
        my $seq = $s_io -> seq;
        my @a = (0,0,0,0,0);
        $a[0] += ($seq =~tr/Aa//);
        $a[1] += ($seq =~tr/Tt//);
        $a[2] += ($seq =~tr/Gg//);
        $a[3] += ($seq =~tr/Cc//);
        $a[4] += ($seq =~tr/Nn//);
        my $total = sum (@a);
        for(my$i = 0; $i < @a;$i += 1){
            $b[$i] += $a[$i];
            $a[$i] = ($a[$i]/$total) * 100;
            $a[$i] = sprintf('%.04f',$a[$i]);
        }
        my $ot = $len - $total;
        $oa += $ot;
        if ($e) {
            my $gc = $a[2]+$a[3];
            print "$id\t$a[0]\t$a[1]\t$a[2]\t$a[3]\t$a[4]\t$gc\t$ot\n";
        }
    }
    if(!$e){
        my $t = sum(@b);
        for(my$i = 0;$i < @b;$i += 1){
            $b[$i] = ($b[$i]/$t)*100;
            $b[$i] = sprintf('%.04f',$b[$i]);
        }
        my $gc = $b[2]+$b[3];
        print "All\t$b[0]\t$b[1]\t$b[2]\t$b[3]\t$b[4]\t".$gc."\t$oa\n";
    }
}
