#! perl

use warnings;
use strict;
use Getopt::Long;
use MCE::Loop;
use Tie::CharArray;
use Bio::SeqIO;
use File::Basename;

my (@in_dir,$out,$threads,$sample,$bed);
GetOptions(
           'in=s' => \@in_dir,
           'out=s' => \$out,
           'threads=s' => \$threads,
           'sample=s' => \$sample,
           'chr=s' => \$bed
          );
$threads //= 10;
$out //= "anc.fa.gz";
my %s;my @fas_tmp;my @fas;
for my $d(@in_dir){
    push @fas_tmp, sort{$a cmp $b} grep{/\.fa|fasta$/} `find $d`;
}
chomp $_ for @fas_tmp;

if($sample){
    %s = read_bed($sample,1);
    for my $f (@fas_tmp){
        (my $n = basename $f) =~ s/(.*?)\..*/$1/;
        push @fas , $f if exists ($s{$n});
    }
}else{
    @fas = @fas_tmp;
}
if (scalar @fas == 0){
    &help_cal_anc_fa();
    exit;
}
my %chrs= read_bed($bed,3);
my @chr = keys %chrs;
my $t = &merge_fa(\@fas,\%chrs,$threads);
print STDERR "### print res\n";
open (my $O_M,"|bgzip -c > $out");
foreach my $chr (sort keys %$t) {
    print $O_M $$t{$chr};
}
close $O_M;
`samtools faidx $out`;

sub read_bed{
    my $f = shift @_;
    my $jud = shift @_;
    open IN,'<',$f or die "$!";
    my %h;
    while(<IN>){
        chomp;
        my @l = split/\s+/;
        if($jud == 1){
            $h{$l[0]} = 1;
        }elsif($jud == 2){
            $h{$l[1]}{$l[0]} = 1;
        }elsif($jud == 3){
            $h{$l[0]} = $l[1];
        }
    }
    close IN;
    return %h;
}

############ sub cal anc ###########
sub merge_fa{
    my $ref = shift @_;my @fs = @{$ref};
    my $ref2 = shift @_; my @scaffolds = sort{$a cmp $b} keys %{$ref2};
    my $threads = shift @_;
    my $thread1 = scalar @fs ; ##sample size
    $thread1 = $threads if ($thread1 > $threads);
    MCE::Loop::init {
        max_workers => $thread1, chunk_size => 1
    };
    my %seq;
    %seq = mce_loop {
        my $in=$_;
        (my $id = basename $in) =~s/(.*?)\..*/$1/;
        my %seq_t;
        my $fa_obj=Bio::SeqIO->new(-format=>"fasta",-file=>"$in");
        print STDERR "### loading $id seq\n";
        while (my $seq_obj=$fa_obj->next_seq) {
            my $chr_now=$seq_obj->id;
            my $seq_now=$seq_obj->seq;
            $seq_now=uc($seq_now);
            #bing string to array and can operate like push~
            tie my @split, 'Tie::CharArray', $seq_now;
            $seq_t{$id}{$chr_now} = \@split;
        }
        MCE->gather("$id",$seq_t{$id});
    } @fs;
    print STDERR "### seq loaded\n";
    MCE::Loop::finish;
    my $thread2 = scalar @scaffolds;
    $thread2 = $threads if ($thread2 > $threads);
    MCE::Loop::init {
        max_workers => $thread2, chunk_size => 1
    };
    my %r;
    my @ids=sort keys %seq;
    %r = mce_loop {
        my $chr=$_;
        my $ok=0;
        for my $id (@ids){
            $ok++ if (exists $seq{$id}{$chr}) ;
        }
        my $chr_anc;
        print STDERR "cal $chr anc seq\n";
        $chr_anc=&cal_anc($chr, \%seq,$ref2) if $ok == @ids;
        MCE->gather("$chr",$chr_anc) if $chr_anc;
    } @scaffolds;
    MCE::Loop::finish;
    undef %seq;
    return \%r;
}

sub cal_anc() {
    my $chr = shift @_;
    my $seq_t= shift @_;
    my $ref = shift @_;
    my %chrs = %{$ref};
    my $chr_anc .= ">$chr\n";
    my $chr_len= $chrs{$chr}-1;
    my @ids=sort keys %{$seq_t};
    for (my $i=0;$i<=$chr_len;$i++){
        my %out;
        my $allnum=0;
        for my $id (@ids){
            my $site=$seq_t->{$id}{$chr}->[$i];
            die "$id $chr $i $seq_t->{$id}{$chr}" unless $site;
            next if $site eq 'N';
            $out{$site}++;
            $allnum++;
        }
        my @out=keys %out;
        if(scalar(@out) == 0){
            $chr_anc .= "N";
        }elsif(scalar(@out) == 1){
            $chr_anc .= "$out[0]";
        }else{
            my ($max_site) = sort {$out{$b}<=>$out{$a}} keys %out;
            my $num = $out{$max_site};
            if ( $num > (0.5 * $allnum) and $num > (0.3*scalar(@ids)) ){
	$chr_anc .=  "$max_site";
            }else{
	$chr_anc .=  "N";
            }
        }
    }
    $chr_anc .= "\n";
    my $fix_num=$chrs{$chr} - length($chr_anc) + 1;
    if ($fix_num>0){
        my $n='N' x $fix_num;
        $chr_anc=$chr_anc.$n;
    }
    return $chr_anc;
}

sub help_cal_anc_fa{
        print STDERR "
  Usage: perl $0 --in <fa dir>
      --in       dir contain fa file
      --chr      [chr len]
    Options:
      --sample   sample list [all]
      --out      defalut [./merge.fa]
      --threads  defalut [10]
      --bed      bed file contain chr [chr len]

";
    }
####################################
