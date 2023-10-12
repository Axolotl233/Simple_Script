#! perl

use warnings;
use strict;
use File::Basename;
use Getopt::Long;

my($min,$gap,$prior,$gap2);

GetOptions(
           'prior=s' => \$prior,
           'exgap=s' => \$gap,
           'idgap=s' => \$gap2,
           'min=s' => \$min
          );
my $file = shift;
if(!$file){
    print STDERR "Usage : perl $0 \$paf_file [ --min 1000 --exgap 20000 --idgap 10000 --prior {muti line file, format:(sp1_chr1 sp2_chr2)} ]\n";
    exit;
}
$min //= 1000;
$gap //= 20000;
$gap2 //= 10000;

(my $prefix = basename $file) =~ s/(.*)\..*/$1/;
my $o = $prefix.".block.bed";
my $extend = $gap/2;
my %p;
if($prior){
    open IN,'<',$prior;
    while(<IN>){
        chomp;
        my @l =split/\s+/;
        $p{"$l[0]-$l[1]"} = 1;
    }
    close IN;
}
my %h;
open IN,'<',$file;
open O,'>',$o;
while(<IN>){
    chomp;
    my @l = split/\t/;
    if($prior){
        next unless exists $p{"$l[0]-$l[5]"};
    }
    next if $l[10] < $min;
    $l[2] -= $extend;
    $l[3] += $extend;
    if($l[7]>$l[8]){
        my $tmp = $l[8];
        $l[7] = $l[8];
        $l[8] = $tmp;
    }
    $l[7] -= $extend;
    $l[8] += $extend;
    my $pair = "$l[0]-$l[5]";
    push @{$h{"$l[0]-$l[5]"}}, [@l[0..10]];
}
close IN;

for my $k(sort {$a cmp $b} keys %h){
    my %o;
    my $c = 0;
    my $r_start;
    my $r_end;
    my $q_start;
    my $q_end;
    my @ref = @{$h{$k}};
    my @data = sort{$a->[2]<=>$b->[2]} @{$h{$k}};
    my $last = ${$data[0]}[4];;
    my $jud = 1;
    Do:for(my $i = 0; $i< @data;$i +=1){
        my @l = @{$data[$i]};
        if($i > 0 && $jud == 1){
            if($l[4] ne $last){
                $o{$i} = [$l[0],$l[2],$l[3],$l[5],$l[7],$l[8],$l[4]];
                
                $last = $l[4];
                $jud = 2;
	            next Do;
            }
            $q_start = $l[2];
            $q_end = $l[3];
            $r_start = $l[7];
            $r_end = $l[8];
            if($l[4] eq "+"){
                if($r_end <= ${$o{$i-1}}[5]){
                    $o{$i} = [$l[0],$l[2],$l[3],$l[5],$l[7],$l[8],$l[4]];
                }elsif($q_start > ${$o{$i-1}}[2] && $r_start > ${$o{$i-1}}[5]){
	                $o{$i} = [$l[0],$l[2],$l[3],$l[5],$l[7],$l[8],$l[4]];
                }else{
                    my $q_interval = $q_start - ${$o{$i-1}}[2];
                    my $r_interval = $r_start - ${$o{$i-1}}[5];
                    if($q_interval >$gap2 || $r_interval > $gap2){
                        $o{$i} = [$l[0],$l[2],$l[3],$l[5],$l[7],$l[8],$l[4]];
                    }else{
                        $o{$i} = $o{$i-1};
                        ${$o{$i}}[2] = $q_end;
                        ${$o{$i}}[5] = $r_end; 
	                    delete $o{$i-1};
                    }
                }
            }else{
                if($r_start >= ${$o{$i-1}}[4]){
                    $o{$i} = [$l[0],$l[2],$l[3],$l[5],$l[7],$l[8],$l[4]];
                }elsif($q_start > ${$o{$i-1}}[2] && $r_end < ${$o{$i-1}}[4]){
	                $o{$i} = [$l[0],$l[2],$l[3],$l[5],$l[7],$l[8],$l[4]];
                }else{
                    my $q_interval = $q_start - ${$o{$i-1}}[2];
                    my $r_interval = ${$o{$i-1}}[4] - $r_end;
                    #print $q_interval.",".$r_interval;exit;
                    if($q_interval >$gap2 || $r_interval > $gap2){
                        $o{$i} = [$l[0],$l[2],$l[3],$l[5],$l[7],$l[8],$l[4]];
                    }else{
                        $o{$i} = $o{$i-1};
                        ${$o{$i}}[2] = $q_end;
                        ${$o{$i}}[4] = $r_start; 
	                    delete $o{$i-1};
                    }
                }
            }
        }else{
            $o{$i} = [$l[0],$l[2],$l[3],$l[5],$l[7],$l[8],$l[4]];
            $last = $l[4];
            $jud = 1;
        }
    }
    for my $k (sort {$a <=> $b} keys %o){
        my @t = @{$o{$k}};
        $t[2] -= $extend;
        $t[1] += $extend;
        $t[5] -= $extend;
        $t[4] += $extend;
        push @t,$t[2] - $t[1];
        push @t,$t[5] - $t[4];
        my $p = join"\t",@t;
        print O $p."\n";
    }
}
