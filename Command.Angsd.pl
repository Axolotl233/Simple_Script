#! perl

use warnings;
use strict;
use File::Basename;
use Cwd qw(abs_path getcwd);
use Getopt::Long;

my $angsd = "angsd";
my $realsfs = "realSFS";

if(! $ARGV[0]){
    print STDERR "USAGE : perl $0 [bam2fa|sfs]\n";
    exit;
}
if ($ARGV[0] eq "bam2fa"){
    &bam2fa();
}
if ($ARGV[0] eq "sfs"){
    &sfs();
}

sub bam2fa{
    my (@in_dir,$out_dir,$threads,$sample);
    GetOptions(
               'in=s' => \@in_dir,
               'out=s' => \$out_dir,
               'threads=s' => \$threads,
               'sample=s' => \$sample,
              );
    $out_dir //= "./consensus_fa"; $threads //= 10;
    mkdir $out_dir if ! -e $out_dir;
    my %s;my @bams;
    if($sample){
        %s = &read_bed($sample,1);
    }
    for my $d(@in_dir){
        push @bams, sort{$a cmp $b} grep{/bam$/} `find $d`;
    }
    if (scalar @bams == 0){
        &help_bam2fa();
        exit;
    }
    for $b(@bams){
        chomp $b;
        $b = abs_path($b);
        (my $n = basename $b) =~ s/(.*?)\..*/$1/;
        if($sample){
            next if !exists $s{$n};
            print "$angsd -i $b -only_proper_pairs 1 -uniqueOnly 1 -remove_bads 1 -nThreads $threads -minQ 20 -minMapQ 30 -doFasta 2 -basesPerline 100 -doCounts 1 -out $out_dir/$n 2>&1 |tee $out_dir/$n.log; zcat $out_dir/$n.fa.gz > $out_dir/$n.fa\n" unless -e "$out_dir/$n.fa";
        }else{
            print "$angsd -i $b -only_proper_pairs 1 -uniqueOnly 1 -remove_bads 1 -nThreads $threads -minQ 20 -minMapQ 30 -doFasta 2 -basesPerline 100 -doCounts 1 -out $out_dir/$n 2>&1 |tee $out_dir/$n.log; zcat $out_dir/$n.fa.gz > $out_dir/$n.fa\n" unless -e "$out_dir/$n.fa";
        }
    }
}

sub sfs {
    my (@in_dir,$out,$threads,$pop,$bed,$ref,$anc);
    GetOptions(
               'in=s' => \@in_dir,
               'out=s' => \$out,
               'threads=s' => \$threads,
               'pop=s' => \$pop,
               'bed=s' => \$bed,
               'ref=s' => \$ref,
               'anc=s' => \$anc
              );
    $out //= ".";
    $threads //= 10;
    for my $s ($pop,$ref,$anc){
        if (!$s){
            &help_sfs;
            exit;
        }
    }
    my @bams;
    for my $d(@in_dir){
        push @bams, sort{$a cmp $b} grep{/bam$/} `find $d`;
    }
    if (scalar @bams == 0){
        &help_sfs();
        exit;
    }
    my %group = &read_bed($pop,2);
    my @g = sort {$a cmp $b} keys %group;
    my @t;
    
    for my $p (@g){
        open O,'>',"$p.bam.list";
        my $i = 0;
        for my $b (@bams){
            chomp $b;
            $b = abs_path $b;
            (my $n = basename $b) =~ s/(.*?)\..*/$1/;
            #print "$n:$b:$p\n";
            if (exists $group{$p}{$n}){
	print O $b."\n";
	$i += 1;
            }
        }
        push @t,$i;
        $i = 0;
        close IN;
        print "$angsd -gl 1 -anc $anc -dosaf 1 -only_proper_pairs 1 -uniqueOnly 1 -remove_bads 1 -C 50 -minMapQ 30 -minQ 20 -out $out/$p -bam $p.bam.list -ref $ref -P $threads";
        if($bed){
            print " -rf $bed";
        }
        print ";$realsfs  $out/$p.saf.idx -P $threads -fold 1 > $p.saf.idx.fold.sfs\n";
    }
    print "$realsfs  $out/$g[0].saf.idx  $out/$g[1].saf.idx -P $threads > $out/anc.sfs\n";
    print "perl ~/code/script/z.Util/angsd.sfs2obs.pl $t[0]\n";
}

############ sub bam2fa ############
sub help_bam2fa{
#$angsd -i $bam -only_proper_pairs 1 -uniqueOnly 1 -remove_bads 1 -rf $bed -nThreads 6 -minQ 20 -minMapQ 30 -doFasta 2 -basesPerline 100 -doCounts 1 -out $out_dir/$id 2>&1 |tee $out_dir/$id.log") unless -e "$out_dir/$id.fa.gz";
    print STDERR "
  Usage: perl Command.Angsd.pl bam2fa --in <bam dir>
      --in       dir contain bam file
    Options:
      --sample   sample list [all]
      --out      defalut [./consensus_fa]
      --threads  defalut [10]

";
}
####################################
############ sub run sfs ###########
sub help_sfs{
    print STDERR "
  Usage: perl Command.Angsd.pl cal_anc_fa --in <fa dir>
      --in       dir contain bam file
      --pop      pop list [sample popluation]
      --ref      ref fasta
      --anc      anc fasta
    Options:
      --out      defalut [./]
      --threads  defalut [10]
      --bed      bed file contain filter region [chr:start-end]

";
}
####################################
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
