#! perl

use warnings;
use strict;
print STDERR "perl $0 \$stringtie_merge \$file \$col_index\ [default: 0\]\n (target file need head line)\n";
my %h;

my $merge = shift or die "need merge file\n";
my $target = shift or die "need target file\n";
my $col = shift;
$col //= 0;
my %len;
open IN ,'<', $merge or die "$!";
while(<IN>){
    next if /^#/;
    (my $jud,my $start,my $end) = (split/\t/,$_)[2,3,4];
    next unless $jud eq "transcript";
    $_ =~ /gene_id "(.*?)";/;
    my $mstrg = $1;
    $_ = /transcript_id "(.*?)"/;
    my $gene_id = $1;
    next if $gene_id =~ /MSTRG/;
    my $len = $start - $end;
    push @{$h{$mstrg}},$gene_id;
}
close IN;

for my $key (keys %h){
    @{$h{$key}} = filter(\@{$h{$key}});
}
my %h2;

open IN2,'<',$target or die "$!";
my $head = readline IN2;
while(<IN2>){
    my $m = (split/\t/,$_)[$col];
    if(exists $h{$m}){
        if ( (scalar @{$h{$m}}) > 1) {
            print $_."\n" for @{$h{$m}};exit;
            for my $id (@{$h{$m}}){
	my $new_d = $id;
	$_ =~ s/$m/$new_d/;
	push @{$h2{$new_d}}, $_;
            }
        }else{
            my $new = ${$h{$m}}[0];
            $_ =~ s/$m/$new/;
            ${$h2{$new}}[0] = $_;
        }
    }else{
        ${$h2{$m}}[0] = $_;
    }
}
close IN2;

my %h3;
print $head;
for my $key (sort keys %h2){
    if (@{$h2{$key}} > 1){
        my @count;
        for my $line (@{$h2{$key}}){
            chomp $line;
            my @count2 = split/,/,$line;
            for (my $i = 1;$i < @count2;$i ++){
	if(! $count[$i]){
	    $count[$i-1] = $count2[$i];
	}else{
	    $count[$i-1] += $count2[$i];
	}
            }
        }
        my $p1 = join"\t",@count;
        print "$key\t$p1\n";
    }else{
        print ${$h2{$key}}[0];
    }
}  

sub filter{
    my $ref = shift @_;
    my @arr = @{$ref};
    my %h;
    $h{$_} = 1 for @arr;
    return keys %h;
}
