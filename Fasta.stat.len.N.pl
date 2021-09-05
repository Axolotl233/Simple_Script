#! perl

use warnings;
use strict;
use Bio::SeqIO;
use List::Util qw(max min);

my $f = shift or die "need fasta\n";
my $s_ioobj = Bio::SeqIO -> new(-file => $f);
while(my $s_io = $s_ioobj-> next_seq){
    my $id = $s_io -> display_id;
    my $seq = $s_io -> seq;
    $seq = uc($seq);
    (my $seq1 = $seq)=~ tr/N/:/cs;
    (my $seq2 = $seq)=~ tr/N/:/s;
    my @t;
    if ($seq =~ /^N/){
        $seq2 =~ s/://;
        @t = &p(\$seq1,\$seq2);
    }
    if ($seq =~ /^[ATCG]/){
        $seq1 =~ s/://;
        @t = &p(\$seq2,\$seq1);
    }
    #print join"\n",@t;exit;
    my $c1 = 1;
    my $c2 = 0;
    for my $e (@t){
        my $k = ($e =~/^N/)?"GAP":"SEQ";
        $c2 += length($e);
        print "$id\t$c1\t$c2\t$k\n";
        $c1 += length($e);
    }
}

sub p{
    my ($r1,$r2) =  @_;
    my @s1 = split/:/,${$r1};
    my @s2 = split/:/,${$r2};
    #print join"\n",@s2;exit;
    my @p;
    my $n1 = scalar @s1;
    my $n2 = scalar @s2;
    my $min = min($n1,$n2);
    my $d = $n1 - $n2;
    for(my $i = 0;$i < $min;$i+=1){
        push @p,$s1[$i];
        push @p,$s2[$i];
    }
    if($d == 0){
        return @p;
    }elsif($d > 0){
        for(my $i = $n2;$i<$n1;$i+=1){
            push @p , $s1[$i];
        }
        return @p;
    }elsif($d < 0){
        for(my $i = $n1;$i<$n2;$i+=1){
            push @p , $s2[$i];
        }
        return @p;
    }
}
#while(<IN>){
#chomp;
#my $a = $_;
#$a =~ tr/N/a/c;
#$a =~ tr/N/b/;
#while($a =~ /b/){
#    $a =~ s/(b+)//;
#    my $n1 = $1 =~ tr/b//;
#    print "$n1\n";
#    if($a =~ /a/){
#        $a =~ s/(a+)//;
#        my $n2 = $1 =~ tr/a//;
#        print "$n2\n";
#    }
#}
