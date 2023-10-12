#! perl

use warnings;
use strict;
use Bio::SeqIO;
use List::Util qw (sum max min);
use Getopt::Long;
use File::Basename;

(my $stat,my $level,my $sp,my $NG);

GetOptions(
           'NG' => \$NG,
           'stat=s' => \$stat,
           'level=s' => \$level,
           'sp=s' => \$sp
          );

my $file = $ARGV[0] or die "USAGE : perl $0 seq_file [--stat 50 --level s --NG]\n";

$level //= "s";
$level = "c" if $NG;
$stat //=50;
$sp //= "species";
my @len;

my $seqio_obj = Bio::SeqIO -> new (-file => $file, -format => "fasta", -alphabet => "dna");
my $c = 0;
my $g_d = 0;
my $g_l = 0;
while(my $seq_obj = $seqio_obj -> next_seq){
    my $seq = $seq_obj -> seq;
    $seq = uc($seq);
    if($level eq "c"){
        my @seq = split/[Nn]+/,$seq;
        $g_l += ($seq =~ tr/Nn/Nn/);
        for my $s (@seq){
            next if (length $s == 0);
            push @len,length $s;
            $c += 1;
        }
        $g_d += (scalar @seq - 1);
        print STDERR "loaded [$c] seqences \r";
    }else{
        my $length = $seq_obj -> length;
        push @len , $length;
        $c += 1;
        print STDERR "loaded [$c] seqences \r";
    }
}
print STDERR"\n#############################\n";
my $contig = scalar(@len);

if($level eq "c"){
    print "contig_num\t$contig\n";
    print "gap_num\t$g_d\n";
    print "gap_length\t$g_l\n";
}else{
    print "scaffold_num\t$contig\n";
}
my $total_len = sum(@len);
print "total_length\t$total_len\n";
my $ave = $total_len/$contig;
print "average_length\t";
printf "%.2f",$ave;
my $max_contig = max(@len);
my $min_contig = min(@len);
print "\nmax\t$max_contig\n";
print "min\t$min_contig\n";

@len = sort {$b <=> $a} @len;
my @a = split/,/,$stat;
map {&stats(\@len,$_,$total_len)} @a ;
print STDERR "#############################\n";

if($NG){
    my @t = &calculate_NG($total_len,\@len);
    my $name = basename $file;
    open O,'>',$name.".NG.txt";
    for my $e (@t){
        print O join"\t",@{$e};
        print O "\t$sp\n";
    }
}

sub stats{
    my $contigs = shift @_;
    my $N = shift @_;
    my $alllen = shift @_;
    my @contig = @{$contigs};
    my $dy;
    my $per = ($alllen * $N)/100;
    for (my $i = 0 ;$i < @contig; $i++){
        $dy += $contig[$i];
        my $n = $i + 1;
        if ($dy >= $per){
	print "N"."$N"."\t$contig[$i]\n"."L"."$N"."\t$n\n";
	last;
            }
    }
    return;
}
sub calculate_NG{
    #REF:https://academic.oup.com/gigascience/article/2/1/2047-217X-2-10/2656129?login=true
    my $t = shift @_;
    my $r = shift @_;
    my @l = @{$r};
    #print join"\n",@l;exit;
    my @t_res;
    my $t_sum = 0;
    my $cum = 0;
    my $i = 0;
    my $per = 0;
    my %h;
    for my $e (@l){
        $t_sum += $e;
        $per = ($t_sum/$t)*100;
        my $per2 = ($e/$t)*100;
      DO:while($i < $per){
            #push @{$h{$i}} , $e;
            push @t_res, [$e,$per,$per2,$i];
            $i += 1;
        }
        $i = int($per);
    }
    return @t_res;
}
__END__
