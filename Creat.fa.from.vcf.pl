#! perl

use strict;
use warnings;
use File::Basename;
use MCE::Loop;
use Getopt::Long;
use Cwd qw(getcwd abs_path);
use Bio::SeqIO;
use zzIO;

my ($o_dir,$threads,$ref,$vcf,$sample,$hap);
GetOptions(
           'dir=s' => \$o_dir,
           'threads=s' => \$threads,
           'ref=s' => \$ref,
           'vcf=s' => \$vcf,
           'sample=s' => \$sample,
           'hap' => \$hap
          );
for my $s ($ref,$vcf,$sample){
    if(!$s){
        print STDERR 
        "###   USAGE : perl $0 --ref ref.fa --vcf vcf --sample sample.lst\n";
        exit;
    }
}
$o_dir //= ".";
$threads //= 10;
srand(time());

my %n = &read_sample($sample);
my %vcf;
if($hap){
    %vcf = %{&read_vcf_hap($vcf)};
}else{
    %vcf = %{&read_vcf($vcf)};
}
MCE::Loop::init {chunk_size => 1,max_workers => $threads};
mce_loop{ &run($_) } sort{$a cmp $b} keys %n;

sub run{
    my $name = shift @_;
    my $s_obj = Bio::SeqIO -> new(-file => $ref, -format => "fasta");
    my $fh1,my $fh2;
    if($hap){
        open $fh1,'>',"$o_dir/$name.hap1.fa" or die "$!";
        open $fh2,'>',"$o_dir/$name.hap2.fa" or die "$!";
    }else{
        open $fh1,'>',"$o_dir/$name.fa" or die "$!";
    }
    while(my $s_io = $s_obj -> next_seq){
        my $chr = $s_io -> display_id;
        my $seq = $s_io -> seq;
        if($hap){
            my @seq_fix = @{&seq_get_hap(\%{$vcf{$name}{$chr}},\$seq)};
            print $fh1 ">$chr\n$seq_fix[0]\n";
            print $fh2 ">$chr\n$seq_fix[1]\n";
        }else{
            my $seq_fix = ${&seq_get(\%{$vcf{$name}{$chr}},\$seq)};
            print $fh1 ">$chr\n$seq_fix\n";
        }
    }
    close $fh1;
    if($fh2){
        close $fh2;
    }
}
sub seq_get{
    my $ref1 = shift @_;
    my $ref2 = shift @_;
    my %h = %{$ref1};
    my $s = ${$ref2};
    for my $k (sort {$a <=> $b} keys %h){
        my $index = $k - 1;
        substr($s,$index,1) = $h{$k};
    }
    return \$s;
}
sub seq_get_hap{
    my $ref1 = shift @_;
    my $ref2 = shift @_;
    my %h = %{$ref1};
    my $s = ${$ref2};
    my @s_o = ($s,$s);
    undef $s;
    #substr($seq2,$index,1) = $ale;
    for my $k (sort {$a <=> $b} keys %h){
        my $index = $k - 1;
        my $hap1 = ${$h{$k}}[0];
        my $hap2 = ${$h{$k}}[1];
        substr($s_o[0],$index,1) = $hap1;
        substr($s_o[1],$index,1) = $hap2;
    }
    return \@s_o;
}
sub read_vcf_hap{
    my $f = shift @_;
    my $f_h = open_in_fh($f);
    my @head;
    my %h;
    while($f_h){
        next if /^##/;
        if(/^#C/){
            @head = split/\t/;
            next;
        }
        my @l = split/\t/;
        my $tmp_base = $l[3].",".$l[4];
        my @base = split/,/,$tmp_base; # 0 for ref, 1.. for ale
        
        for(my $i = 9;$i < @l;$i ++){
            my @q = split/:/,$l[$i];
            if ($q[0] =~/\.\/\./){
                push @{$h{$head[$i]}{$l[0]}},("-","-");
            }else{
                $q[0] =~ /(\d+)\/(\d+)/;
                (my $GT1,my $GT2) = ($1,$2);
                push @{$h{$head[$i]}{$l[0]}{$l[1]}},($base[$GT1],$base[$GT2]);
            }
        }
    }
    return \%h;
}
sub read_vcf{
    my $f = shift @_;
    my $f_h = open_in_fh($f);
    my @head;
    my %h;
    while(<$f_h>){
        next if /^##/;
        if(/^#C/){
            @head = split/\t/;
            next;
        }
        my @l = split/\t/;
        my $p;
        my $tmp_base = $l[3].",".$l[4];
        my @base = split/,/,$tmp_base; # 0 for ref, 1.. for ale
        for(my $i = 9;$i< @l;$i += 1){
            if ($l[$i] =~ /^\.\/\./){
                $h{$head[$i]}{$l[0]}{$l[1]} = "-";
            }else{
                my @info = split/:/,$l[$i];
                $info[0] =~ /(\d+)\/(\d+)/;
                (my $GT1,my $GT2) = ($1,$2);
                (my $dep_ref,my $dep_alt) = (split/,/,$info[1])[0,1];
                if($dep_ref == $dep_alt){
                    if ($dep_ref == 0){
                        $p="-";
                        $h{$head[$i]}{$l[0]}{$l[1]} = $p;
                    }else{
                        my $jud = int(rand(100));
                        $p = ($jud < 50)? $base[$GT1]:$base[$GT2];
                        $h{$head[$i]}{$l[0]}{$l[1]} = $p;
                    }
                }else{
                    $p = ($dep_ref > $dep_alt)? $base[$GT1]:$base[$GT2];
                    $h{$head[$i]}{$l[0]}{$l[1]} = $p;
                }
            }
        }
    }
    return \%h;
}
sub read_sample{
    my $f = shift @_;
    my %h;
    open IN,'<',$f or die "$!";
    while(<IN>){
        chomp;
        $h{$_} = 1;
    }
    close IN;
    return %h;
}
