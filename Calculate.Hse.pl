#! perl

use warnings;
use strict;
use MCE::Loop;
use Cwd;
use File::Basename;
use List::Util qw/max min/;

print STDERR "======> script used for calculate HE\n\n####USEAG : perl $0 \$dir####
(dir created by bamdst, must contain a folder named \"region.tsv.gz.split with\" include files split region.tsv.gz by chr)\n\n";
my $thread = 5;
my $dir = shift or die "need dir \n";
my $window = shift;
$window //= 10000;
###para
my $dup_max_fold = 5; #5
my $dup_min_fold = 1.5; #1.5
my $del_max_fold = 0.6; #0.6
my $del_min_fold = 0; #0 
my $min_cov = 60; #60 no_use
my $confict_rate = 0.2; #0.2
my $no_means_rate = 0.3; #0.3
my $he_window = 0.3; #0.3

###load_depth
my %d = &read_depth("$dir/chromosomes.report");
###main
my $o = "$dir/HSE.out";
mkdir $o unless -e $o;
my @fs = sort{$a cmp $b} grep {/.split.file$/} `find $dir/region.tsv.gz.split`;
print STDERR "======> calculate start\n";
MCE::Loop::init {max_workers => $thread, chunk_size => 1};
mce_loop {&run($_)} @fs;
print STDERR "======> calculate done, please check $o\n";
print STDERR "======> gather result\n";
my $o_name = basename dirname $o;
my @dupf = sort{$a cmp $b} grep{/\.dup.HSE.txt/} `find $o`;
my @delf = sort{$a cmp $b} grep{/\.del.HSE.txt/} `find $o`;
&gather_res(\@dupf,"dup",$o_name);
&gather_res(\@delf,"del",$o_name);
print STDERR "======> gather done\n";

sub gather_res{
    my $ref = shift @_;
    my $type = shift @_;
    my $name = shift @_;
    my @fs = @{$ref};
    open O,'>',"1.$name.$type.hse.link.txt";
    for my $f (@fs){
        chomp $f;
        (my $chr = basename $f) =~ s/(.*?)\..*/$1/;
        open IN,'<',$f;
        my %p;
        my @a = ();
        my $c = 0;
        readline IN;
        my ($s,$e,$n);
        while(<IN>){
            if(/^#/){
	$s = min(@a);
	$e = max(@a);
	$n = ($e - $s)/$window;
	if($c/$n > $he_window){
	    print O "$chr\t$n\t$c\t$s\t$e\n";
	}
	@a = ();
	$c = 0;
            }elsif(/^\d+/){
	my @l = split/\t/;
	push @a,($l[0],$l[1]);
	$c += 1;
            }elsif(/^\s+/){
	next;
            }
        }
        if(scalar @a > 0){
            $s = min(@a);
            $e = max(@a);
            $n = ($e - $s)/$window;
            if($c/$n > $he_window){
	print O "$chr\t$n\t$c\t$s\t$e\n";
            }
        }
    }
}

sub run{
    my $f = shift @_;
    chomp $f;
    my $dir = dirname $f;
    (my $name = basename $f) =~ s/(.*?)\..*/$1/;
    die "$name not depth info\n" if(!exists $d{$name});
    my $ave = $d{$name};
    my $h_max = $ave * $dup_max_fold;
    my $h_min = $ave * $dup_min_fold;
    my $l_min = $ave * $del_min_fold;
    my $l_max = $ave * $del_max_fold;
    open IN,'<',"$f";
    my $c = 1;
    my %m;my %h;
    while(<IN>){
        chomp;
        
        my @l = split/\s+/;
        my $start = $l[1] - 1;
        my $end = $l[2] + 1;
        #next if $l[-1] < $min_cov;
        if($l[3] <= $h_max && $l[3] >= $h_min){
            $m{$c} = "dup";
        }elsif ($l[3] <= $l_max && $l[3] >= $l_min) {
            $m{$c} = "del";
        }elsif ($l[3] > $l_max && $l[3] < $h_min){
            $m{$c} = "nor";
        }else{
            $m{$c} = "l2h";
        }
        $h{$c} = [$start,$end,$l[3]];
        $c += 1;
    }
    close IN;
    my @dup = &window_link(\%m,"dup",1);
    my @del = &window_link(\%m,"del",1);
    my @dup_f = &window_filter(\%m,\@dup,"del");
    my @del_f = &window_filter(\%m,\@del,"dup");
    &window_print("$o/$name.dup.HSE.txt",\%h,\@dup_f);
    &window_print("$o/$name.del.HSE.txt",\%h,\@del_f);
}

sub window_print{
    my $name = shift @_;
    my $ref1 = shift @_;
    my $ref2 = shift @_;
    my %h = %{$ref1};
    open my $o,'>',$name;
    for my $e(@{$ref2}){
        print $o "###\n";
        map{print $o join"\t",@{$h{$_}};print $o "\n"} @{$e};
        print $o "\n";
    }
}

sub window_filter{
    my $ref1 = shift @_;
    my $ref2 = shift @_;
    my %m = %{$ref1};
    my @a = @{$ref2};
    my @res;
    for my $e (@a) {
        my @x = @{$e};
        my $w_num = $x[-1] - $x[0] +1;
        my $f_num = 0;
        my $r_num = 0;
        for my $v(@x){
            if($m{$v} eq "$type"){
	$f_num += 1;
            }elsif($m{$v} eq "l2h"){
	$r_num += 1;
            }
        }
        next if ($f_num/$w_num) > $confict_rate;
        next if ($r_num/$w_num) > $no_means_rate;
        push @res, \@x;
    }
    return @res;
}

sub window_link{
    my $ref1 = shift @_;
    my $type = shift @_;
    my $a = shift @_;
    my %m = %{$ref1};
    my @res;
    for(my $i = $a;$i < scalar(keys %m);$i+= 1){
        if(!exists $m{$i}){
            print "not exists depth row : ".$i."\n";
            exit;
        }
        if($m{$i} eq $type){
            my @a = &window_extend($i,\%m,$type);
            unshift @a, $i;
            $i = $a[-1] + 1;
            ### filter window_link
            next if (scalar @a < 3 || $a[-1] - $a[0] < 6);
            push @res, \@a;
        }
    }
    return @res;
}

sub window_extend{
    my $i = shift @_;
    my $ref = shift @_;
    my $type = shift @_;
    my @a;
    my %m = %{$ref};
    for (my $n = $i + 1; $n <= $i + 10;$n += 1){
        if(!exists $m{$n}){
            next;
        }
        if($m{$n} eq $type){
            push @a , $n;
            push @a , &window_extend($n,\%m,$type);
            last;
        }
    }
    return @a;
}
sub read_depth{
    my $f = shift @_;
    my %h;
    open I,'<',"$f" or die "$!";
    readline I;
    while(<I>){
        chomp;
        s/\s+//;
        my @l = split/\s+/;
        $h{$l[0]} = $l[2];
    }
    close I;   
    return %h;
}
