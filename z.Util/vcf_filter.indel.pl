#! perl

use warnings;
use strict;
use MCE::Loop;
use Getopt::Long;
use File::Basename;
use List::Util qw/max/;

(my $r,my $threads,my $w);
GetOptions(
           'i=s' => \$r,
           't=s' => \$threads,
           'w=s' => \$w
          );
$w //= 5;
my $vcf_dir = shift or die "USAGE : perl $0 \$vcf_dir -i \$ref_indel -w \$window_bp -t threads \n";
die "$!" if ! -e "$vcf_dir";
my @vcfs = sort{$a cmp $b} grep{/\.vcf$/} `find $vcf_dir`;
my %h;

open R,"zcat $r |";
while(<R>){
    next if /^#/;
    next unless $_;
    my @l = split/\s+/,$_;
    my $tmp = "$l[3],$l[4]";
    my @a = split/,/,$tmp;
    my @len;
    for my $e (@a){
        push @len , length $e;
    }
    my $max = max(@len);
    for(my $i = $l[1] - $w; $i < $l[1] + $max + $w ;$i ++){
            $h{$l[0]}{$i} = 1;
    }
}
close R;
chomp $_ for @vcfs;
MCE::Loop::init {chunk_size => 1,max_workers => $threads};
mce_loop{ &run($_) } @vcfs;

sub run{
    my $f = shift @_;
    (my $head,my $heads_ref) = &get_head($f);
    my @heads = @{$heads_ref};
    my $c = scalar(@heads);
    (my $chr = basename $f) =~ s/(.*?)\..*/$1/;
    my $new = "$chr.indel.vcf";
    open O, '>',"$vcf_dir/$new";
    open I,'<',$f;
    print O "$head";
    while(<I>){
        next if /^#/;
        my @l = split/\t/,$_;
        if(exists $h{$l[0]}{$l[1]}){
            next;
        }else{
            print O $_;
        }
    }
    close O;
    close I;
    unlink $f;
}
sub get_head{
    my $f = shift @_;
    (my $h, my @hs);
    open IN,'<',$f or die "$!";
    while(<IN>){
        if(/^##/){
            $h .= $_;
        }elsif(/^#C/){
            $h .= $_;
            @hs = split/\t/,$_;
            chomp $_ for @hs;
            last;
        }
    }
    close IN;
    return($h,\@hs)
}
