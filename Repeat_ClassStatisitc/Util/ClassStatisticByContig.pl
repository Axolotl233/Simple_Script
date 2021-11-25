#! perl

use warnings;
use strict;
use MCE::Loop;
use File::Basename;

my $thread_mce = shift;
MCE::Loop::init {chunk_size => 1,max_workers => $thread_mce,};

my @files = grep {/gff3$/} `find ./split_gff`;
chomp $_ for @files;

mce_loop{ &run($_) } @files;

sub run{
    my $file = shift @_;
    open my $fileIN,'<',$file;
    my %h;
    my %box;
    my $count = 1;
    while(<$fileIN>){
        chomp;
        (my $type,my $start, my $end) = &identify_type($_);
        push @{$h{$type}{$count}},($start,$end);
        $count += 1;
        if ($type=~/(LTR|LINE|DNA)/){
            push @{$h{$1}{$count}},($start,$end);
            $count += 1;
        }
    }
    close $fileIN;
    (my $name = basename $file) =~ s/\.gff3//;
    my $dir = dirname $file;
    my @tmp;
    for my $m (sort keys %h){
        my $ref = \%{$h{$m}};
        %box = &bin_merge($ref);
        my $res = &res_get(\%box);
        push @tmp,"$m\t$res";
    }
    open OUT,'>',"$dir/$name.repeat.table";
    print OUT "$_"."\n" for @tmp;
    close OUT;
}

sub res_get{
    my $ref = shift @_;
    my %h = %{$ref};
    my $t_len = 0;
    for my $k1 (keys %h){
        $t_len = ${$h{$k1}}[1] - ${$h{$k1}}[0] + $t_len;
    }
    return $t_len;
}

sub bin_merge{
    my $ref = shift @_;
    my %h = %{$ref};
    my @a = sort{${$h{$a}}[0] <=> ${$h{$b}}[0]} keys %h;
    
    my %b;
    my $start;
    my $end;
    
    for(my $i = 0;$i< @a; $i++){
        if($i > 0){
            $start = ${$h{$a[$i]}}[0];
            $end = ${$h{$a[$i]}}[1];
            if($start > ${$b{$i-1}}[1]){
	${$b{$i}}[0] = $start;
	${$b{$i}}[1] = $end;
            }else{
	${$b{$i}}[0] = (${$b{$i-1}}[0]<$start)?${$b{$i-1}}[0]:$start;
	${$b{$i}}[1] = (${$b{$i-1}}[1]<$end)?$end:${$b{$i-1}}[1];
	delete $b{$i-1};
            }
        }else{
            $start = ${$h{$a[$i]}}[0];
            $end = ${$h{$a[$i]}}[1];
            ${$b{$i}}[0] = $start;
            ${$b{$i}}[1] = $end;
        }
    }
    my @d = sort{$a <=> $b} keys %b;
    if(@d == 1){
        return %b;
    }else{
        my $c = 0;
        for(my $i =0;$i< @d;$i++){
            if($i == 0){
	next;
            }else{
	#print $b{$d[$i-1]}[1];exit;
	if(${$b{$d[$i-1]}}[1] > ${$b{$d[$i]}}[0]){
	    $c += 1;
	}
            }
        }
        if ($c == 0){
            return %b;
        }else{
            %b = &bin_merge(\%b);
        }
    }
}

sub identify_type{
    my $line = shift @_;
    my $type;
    my @l=split/\s+/,$line;#print "$l[1]";exit;
    if ($l[1]=~/TRF/){
        $type = "Simple_repeat";
    }else{
        $l[10]=~/Class=([\w\/-]+);?/ or die "unsuited GFF\n$l[10]\n";
        $type=$1;
        if ($type=~/LTR/){
            if($type=~/(Gypsy|Copia)/){
	$type="LTR_".$1;
            }else{
	$type="LTR_other";
            }
        }elsif($type=~/DNA/){
            if ($type=~/(CMC-EnSpm|hAT-Ac|hAT-Tip100|MuDR|PIF-Harbinger)/){
	$type="DNA_".$1;
            }else{
	$type="DNA_other";
            }
        }elsif($type=~/LINE/){
            if ($type=~/(L1|L2)/){
	$type="LINE_".$1;
            }else{
	$type="LINE_other";
            }
        }elsif($type=~/SINE.*/){
            $type="SINE";
        }elsif($type=~/Simple_repeat/){
            $type="Simple_repeat";
        }elsif($type=~/Satellite/){
            $type="Satellite";
        }elsif($type=~/rRNA|snRNA|tRNA/){
            $type="Small_RNA";
        }elsif($type=~/Low_complexity/){
            $type="Low_complexity";
        }else{
            $type="Unclassified_".$type;
        }
    }
    return ($type,$l[3],$l[4]);
}

    
