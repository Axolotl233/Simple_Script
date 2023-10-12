#! perl

use warnings;
use strict;
use MCE::Loop;
use Getopt::Long;
use File::Basename;

(my $g,my $d,my $threads,my $depth_ref,my $method);
GetOptions(
           'd=s' => \$d,
           'g=s' => \$g,
           't=s' => \$threads,
           'r=s' => \$depth_ref,
           'm=s' => \$method,
          );

my $vcf_dir = shift or die "USAGE : perl $0 \$vcf_dir -d max,min -g min_gq -t threads -r dir contain res created by bamdst\n";
(my $dp_max ,my $dp_min) = split/,/,$d;
$dp_max //= 3;
$dp_min //= "1/3";
if($dp_min =~ /([0-9\w]+)\/([0-9\w]+)/){
    $dp_min = ($1/$2);
}

my %dp;
if($method eq "Bamdst"){
    %dp = &get_dp_bamdst ($depth_ref) if ($d && $depth_ref);
}elsif($method eq "BamDeal"){
    %dp = &get_dp_bamdeal ($depth_ref) if ($d && $depth_ref);
}

MCE::Loop::init {chunk_size => 1,max_workers => $threads};
my @vcfs = sort{$a cmp $b} grep{/\.vcf$/} `find $vcf_dir`;
chomp $_ for @vcfs;
mce_loop{ &run($_) } @vcfs;

sub run{
    my $f = shift @_;
    next if -d $f;
    (my $head,my $heads_ref) = &get_head($f);
    my @heads = @{$heads_ref};
    (my $chr = basename $f) =~ s/(.*?)\..*/$1/;
    my $new = $chr;
    if($d){
        $new .= "\.sample_dp";
    }
    if($g){
        $new .= "\.gq";
    }
    $new .= ".vcf";
    open O, '>',"$vcf_dir/$new";
    print O $head;
    open IN,'<',$f;
    while(<IN>){
        next if /^#/;
        chomp;
        my @l = split/\t/;
        my @c = &format_check($l[8]);
        if($d){
            @l = &depth_filter(\@l,\@c,\@heads);
        }
        if($g){
            @l = &gq_filter(\@l,\@c);
        }
        print O join"\t",@l;
        print O "\n";
    }
    close IN;
    close O;
    unlink $f;
}

sub get_dp_bamdst{
    my $dir = shift @_;
    my %t;
    my @depth_f = grep{/chromosomes.report/}`find $dir`;
    chomp $_ for @depth_f;
    for my $f (@depth_f){
        (my $sample = basename dirname $f) =~ s/(.*?)\..*/$1/;
        open IN,'<',$f;
        readline IN;
        while(<IN>){
            s/\s+//;
            my @l = split/\s+/;
            $t{$sample}{$l[0]} = $l[2];
        }
        close IN;
    }
    return %t;
}
sub get_dp_bamdeal{
    my $dir = shift @_;
    my %t;
    my @depth_f = grep{/\.stat$/}`find $dir`;
    chomp $_ for @depth_f;
    for my $f (@depth_f){
        (my $sample = basename dirname $f) =~ s/(.*?)\..*/$1/;
        open IN,'<',$f;
        readline IN;
        while(<IN>){
            next if /^#/;
            my @l = split/\t/;
            $t{$sample}{$l[0]} = $l[5];
        }
        close IN;
    }
    return %t;
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
            for (@hs){
	chomp $_;
	$_ =~ s/\.\d+//;
            }
            last;
        }
    }
    close IN;
    return($h,\@hs)
}
sub format_check{    
    my $ar = shift @_;
    my @fo = split":",$ar;
    my @re;
    if (@fo == 5){
        @re = ("5",".\/.:0,0:0:.:0,0,0");
        return @re;
    }elsif(@fo == 7){
        @re= ("7","./.:0,0:0:.:.:.:0,0,0");
        return @re;
    }elsif(@fo == 8){
        @re= ("7","./.:0,0:0:.:.:.:0,0,0");
        return @re;
    }else{
        die "error format!\n$ar\n";
    }
}

sub depth_filter{
    my @arg = @_;
    my @a = @{$arg[0]};
    my @b;
    my @c = @{$arg[1]};
    my @n = @{$arg[2]};
    for(my $i = 9;$i < @a;$i ++){
        @b = split ":", $a[$i];
        next if ($b[0] eq "\.\/\." || $b[0] eq "\.\|\.");
        if(!exists $dp{$n[$i]}{$a[0]}){die "the depth data $a[0]:$n[$i] is not exists!";}
        my $min = ($dp{$n[$i]}{$a[0]} * $dp_min);
        my $max = ($dp{$n[$i]}{$a[0]} * $dp_max);
        if((scalar(@b) != $c[0])){
            $a[$i] = $c[1];
        }elsif($b[2] eq "\."){
            $a[$i] = $c[1];
        }elsif($b[2] > $max || $b[2] < $min){
            $a[$i] = $c[1];
        }
    }
    return @a;
}
sub gq_filter{
    my @arg = @_;
    my @a = @{$arg[0]};
    my @b;
    my @c = @{$arg[1]};
    for(my $i = 9;$i < @a;$i ++){
        @b = split ":", $a[$i];
        next if ($b[0] eq "\.\/\." || $b[0] eq "\.\|\.");
        if((scalar(@b) != $c[0])){
            $a[$i] = $c[1];
        }elsif($b[0] =~ /^\.\/\./){
            $a[$i] = $c[1];
        }elsif($b[3] < $g || $b[3] eq "\."){
            $a[$i] = $c[1];
        }
    }
    return @a;
}
