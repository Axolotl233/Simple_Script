#! perl

use warnings;
use strict;
use File::Basename;
use Cwd;

my $h_dir = getcwd;
my $vcf = shift;
if(! $vcf){
    print STDERR "USAGE : perl $0 \$vcf \[\$out_prefix\]\n";
    exit;
}
my $prefix = shift;
$prefix //= "Pop";
my %h;
mkdir ("$prefix.stat.out") if ! (-e "$prefix.stat.out");
my @head;
open IN, "zcat $vcf |" or die "$!";

while(<IN>){
    if(/^##/){
        next;
    }if(/^#C/){
        chomp;
        @head = split/\t/,$_;
        last;
    }
}
while(<IN>){
    my @l = split/\t/;
    for (my $i = 9;$i < @l;$i+=1){
        my @a = split/\:/,$l[$i];
        if($a[0] eq "0/0"){
            $h{$head[$i]}{$l[0]}{"homozygous_ref"} += 1;
        }elsif($a[0] eq "0/1"){
            $h{$head[$i]}{$l[0]}{"heterzygous"} += 1;
        }elsif($a[0] eq "1/1"){
            $h{$head[$i]}{$l[0]}{"homozygous_ale"} += 1;
        }elsif($a[0] eq "./."){
            $h{$head[$i]}{$l[0]}{"miss"} += 1;
        }else{
            print STDERR  "bi-allele is not support now, please use other tools or manual fix this script\n";
            exit;
        }
    }
}

close IN;
my %o;
chdir ("$prefix.stat.out");
for my $k(sort {$a cmp $b} keys %h){
    my $t_r = 0;
    my $t_e = 0;
    my $t_a = 0;
    my $t_m = 0;
    open O,'>',"$k.snp.stat.txt";
    print O "chr\t00\t01\t11\tmiss\n";
    for my $k2(sort {$a cmp $b} keys %{$h{$k}}){
        my $h_r = 0;
        my $h_e = 0;
        my $h_a = 0;
        my $m = 0;
        if(exists $h{$k}{$k2}{"homozygous_ref"}){
            $h_r = $h{$k}{$k2}{"homozygous_ref"};
        }
        if(exists $h{$k}{$k2}{"heterzygous"}){
            $h_e = $h{$k}{$k2}{"heterzygous"};
        }
        if(exists $h{$k}{$k2}{"homozygous_ale"}){
            $h_a = $h{$k}{$k2}{"homozygous_ale"};
        }
        if(exists $h{$k}{$k2}{"miss"}){
            $m =  $h{$k}{$k2}{"miss"}
        }
        print O join "\t",($k2,$h_r,$h_e,$h_a,$m);
        print O "\n";
        $t_r += $h_r;
        $t_e += $h_e;
        $t_a += $h_a;
        $t_m += $m;
    }
    close O;
    push @{$o{$k}},($t_r,$t_e,$t_a,$t_m);
}
chdir $h_dir;
open O,'>',"$prefix.stat.summary.txt";
print O "sample\t00\t01\t11\tmiss\n";
for my $k(sort {$a cmp $b} keys %o){
    print O "$k\t";
    print O join "\t", @{$o{$k}};
    print O "\t\n";
}
close O;
