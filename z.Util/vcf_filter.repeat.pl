#! perl

use warnings;
use strict;
use MCE::Loop;
use Getopt::Long;
use File::Basename;
use List::Util qw/max/;

(my $r,my $threads);
GetOptions(
           'i=s' => \$r,
           't=s' => \$threads,
          );
my $vcf_dir = shift or die "USAGE : perl $0 \$vcf_dir -i \$ref_repeat_bed -t threads \n";
my @vcfs = sort{$a cmp $b} grep{/\.vcf$/} `find $vcf_dir`;
my %h;

open IN,'<',$r;
while(<IN>){
    next if /^#/;
    next unless $_;
    chomp;
    my @l = split/\s+/,$_;
    for(my $i = $l[1] ;$i <= $l[2] ;$i ++){
        $h{$l[0]}{$i} = 1;
    }
}
chomp $_ for @vcfs;
MCE::Loop::init {chunk_size => 1,max_workers => $threads};
mce_loop{ &run($_) } @vcfs;

sub run{
    my $f = shift @_;
    (my $head,my $heads_ref) = &get_head($f);
    my @heads = @{$heads_ref};
    my $c = scalar(@heads);
    (my $chr = basename $f) =~ s/(.*?)\..*/$1/;
    my $new = "$chr.repeat.vcf";
    open O, '>',"$vcf_dir/$new";
    open IN,'<',$f;
    print O $head;
    while(<IN>){
        next if /^#/;
        my @l = split/\t/,$_;
        if(exists $h{$l[0]}{$l[1]}){
            next;
        }else{
            print O $_;
        }
    }
    close O;
    close IN;
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
            last;
        }
    }
    close IN;
    return($h,\@hs)
}
