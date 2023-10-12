#! perl

use warnings;
use strict;
use File::Basename;
use Getopt::Long;
use MCE::Loop;
use Cwd qw /getcwd abs_path/;

my $h_dir = getcwd();
my($min,$gap,$prior,$gap2,$type,$threads);
GetOptions(
           'prior=s' => \$prior,
           'exgap=s' => \$gap,
           'idgap=s' => \$gap2,
           'min=s' => \$min,
           'type=s' => \$type,
           'threads=s' => \$threads
          );
my $file = shift;
if(!$file){
    print STDERR "Usage : perl $0 \$coord_file --prior {muti line file, format:(sp1_chr1 sp2_chr2)} [-type [r,q or 1,not support m] --min 0 --exgap 20000 --idgap 5000 ]\n";
    exit;
}
$min //= 0;
$gap //= 20000;
$gap2 //= 5000;
$type //= "r";

(my $prefix = basename $file) =~ s/(.*)\..*/$1/;
my $outdir = $prefix.".split_coord"; 
my $outfile = $prefix.".block.bed";
my $extend = $gap/2;

&split_coord($prior,$file);
$threads //= 10;
MCE::Loop::init {chunk_size => 1,max_workers => $threads,};
chdir "$outdir" or die "$!";
my @fs = grep{/coord.txt/} `ls ./`;

mce_loop{ &run($_) } @fs;
MCE::Loop::finish;

chdir $h_dir;
my @fs2 = sort{$a cmp $b} grep{/.block.bed/} `find ./$outdir`;
open O2,'>',"$outfile";
open O3,'>',"$outfile.stat";
my ($ref_all,$que_all);
for my $f (@fs2){
    chomp $f;
    (my $n = basename $f) =~ s/(.*?)\..*/$1/;
    open I3,'<',$f;
    my $ref;
    my $que;
    while(<I3>){
        print O2 $_;
        chomp;
        my @l = split/\t/;
        $ref += $l[8];
        $que += $l[9];
    }
    print O3 "$n\t$ref\t$que\n";
    $ref_all += $ref;
    $que_all += $que;
    close I3;
}
close O2;
print O3 "all\t$ref_all\t$que_all\n";
close O3;

sub run{
    my $f = shift @_;
    chomp $f;
    (my $n = basename $f) =~ s/(.*?)\..*/$1/;
    my $tmp_o = "$n.block.bed";
    my %h = &load_coord($f);
    open O,'>',$tmp_o;
    for my $k(sort {$a cmp $b} keys %h){
        my %o;
        my $r_start;my $r_end;my $q_start;my $q_end;
        my @data = sort{$a->[1]<=>$b->[1]} @{$h{$k}};
        my $last = ${$data[0]}[6];;
        my $jud = 1;
        
      Do:for(my $i = 0; $i< @data;$i +=1){
            my @l = @{$data[$i]};
            $l[1] -= $extend;
            $l[4] -= $extend;
            $l[2] += $extend;
            $l[5] += $extend;
            if($i > 0 && $jud == 1){
            if($l[6] ne $last){
                $o{$i} = \@l;
                $last = $l[6];
                $jud = 2;
	next Do;
            }
            $q_start = $l[1];
            $q_end = $l[2];
            $r_start = $l[4];
            $r_end = $l[5];
            
            if($l[6] > 0){
                if($r_end <= ${$o{$i-1}}[5]){
                    $o{$i} = \@l;
                }elsif($q_start > ${$o{$i-1}}[2] && $r_start > ${$o{$i-1}}[5]){
	    $o{$i} = \@l;
                }else{
                    my $q_interval = $q_start - ${$o{$i-1}}[2];
                    my $r_interval = $r_start - ${$o{$i-1}}[5];
                    if($q_interval >$gap2 || $r_interval > $gap2){
                        $o{$i} = \@l;
                    }else{
                        $o{$i} = $o{$i-1};
                        ${$o{$i}}[2] = $q_end;
                        ${$o{$i}}[5] = $r_end; 
	        delete $o{$i-1};
                    }
                }
            }else{
                if($r_start >= ${$o{$i-1}}[4]){
                    $o{$i} = \@l;
                }elsif($q_start > ${$o{$i-1}}[2] && $r_end < ${$o{$i-1}}[4]){
	    $o{$i} = \@l;
                }else{
                    my $q_interval = $q_start - ${$o{$i-1}}[2];
                    my $r_interval = ${$o{$i-1}}[4] - $r_end;
                    #print $q_interval.",".$r_interval;exit;
                    if($q_interval >$gap2 || $r_interval > $gap2){
                        $o{$i} = \@l;
                    }else{
                        $o{$i} = $o{$i-1};
                        ${$o{$i}}[2] = $q_end;
                        ${$o{$i}}[4] = $r_start; 
	        delete $o{$i-1};
                    }
                }
            }
        }else{
            $o{$i} = \@l;
            $last = $l[6];
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
}

sub coord_filter{
    my $ref = shift @_;
    my %h = %{$ref};
    my @a = sort{$a cmp $b} keys %h;
    my $c = 0;
    for(my $i1 = 0;$i1 < @a;$i1+=1){
        $c += 1;
        next if (!exists $h{$a[$i1]});  
        my @l1 = @{$h{$a[$i1]}};
        
        my $d1 = $l1[2] - $l1[1];
        
        for(my $i2 = $c;$i2 < @a;$i2 += 1){
            next if (!exists $h{$a[$i2]});
            my @l2 = @{$h{$a[$i2]}};
            
            next if $l1[0] ne $l2[0];    
            if($l1[2] >= $l2[1] && $l2[2] >= $l1[1]){
             
                my $d2 = $l2[2] - $l2[1];
                if($d1 > $d2){
                    delete $h{$a[$i2]};
                }elsif($d1 == $d2){
                    if($l1[7] >= $l2[7]){
                        delete $h{$a[$i2]};
                    }else{
                        delete $h{$a[$i1]};
                    }
                }elsif($d1 < $d2){
                    delete $h{$a[$i1]};
                    $d1 = $d2;
                }
            }
        }
    }
    #print scalar keys %h;exit;
    my %o;
    if($type eq "r"){
        for my $k (%h){
            next if ! exists $h{$k};
            my @t = @{$h{$k}};
            @t = ($t[3],$t[4],$t[5],$t[0],$t[1],$t[2],$t[6],$t[7]);
            @{$o{$k}} = @t; 
        }
    }else{
        for my $k (%h){
            next if ! exists $h{$k};
            @{$o{$k}} = @{$h{$k}}; 
        }
    }
    return %o;
}

sub load_coord{
    my $f = shift @_;
    open IN,'<',$f;
    my %h;
    my %t;
    while(<IN>){
        next unless /^\d+/;
        chomp;
        my @l = split/\s+/;
        next if $l[4] < $min;
        next if $l[5] < $min;
        my $direct = $l[7] * $l[8];
        die "????" if $l[0] > $l[1];
        if($l[2] > $l[3]){
            my $tmp = $l[2];
            $l[2] = $l[3];
            $l[3] = $tmp;
        }
        
        if($type eq "r"){
            $t{"$l[9]-$l[0]-$l[1]"} = [$l[10],$l[2],$l[3],$l[9],$l[0],$l[1],$direct,$l[6]];
        }elsif($type eq "q"){
            $t{"$l[10]-$l[2]-$l[3]"} = [$l[9],$l[0],$l[1],$l[10],$l[2],$l[3],$direct,$l[6]];
        }
    }
    close IN;
    %t = coord_filter(\%t);
    for my $k (sort {$a cmp $b} keys %t){ 
        my @l = @{$t{$k}};
        my $pair = "$l[0]-$l[3]";
        push @{$h{$pair}}, \@l;
    }    
    return %h;
}
sub split_coord{
    my $f1 = shift @_;
    my $f2 = shift @_;
    $f2 = abs_path($f2);
    $f1 = abs_path($f1);
    mkdir "$outdir" if !-e "$outdir";
    chdir "$outdir";
    open I,'<',$f1;
    while(<I>){
        chomp;
        my @l1 =split/\s+/;
        open O,'>',"$l1[0]_$l1[1].coord.txt";
        open IN,'<',"$f2";
        while(<IN>){
            chomp;
            next unless /^\d+/;
            my @l2 = split/\s+/;
            print O $_."\n" if ($l2[9] eq $l1[0] && $l2[10] eq $l1[1]); 
        }
        close O;
    }
    chdir $h_dir;
    close I;
}
