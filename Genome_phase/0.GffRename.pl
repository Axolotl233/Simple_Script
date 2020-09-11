#! perl

use warnings;
use strict;
use File::Basename;

my $gff = $ARGV[0] or die "USAGE : perl $0 gff newname (ref?)";
(my $name = basename $gff) =~ s/gff3?//;
my $new = $ARGV[1];
my $ref = $ARGV[2];
my $c = 1;
my %h1;
my $jud;

if($ref){
    open R,'<',$ref;
    while(<R>){
        chomp;
        my @l = split/\t/;
        $h1{$l[0]} = $l[1];
    }
    close R;
}else{
    $jud = 0;
}

my $head;
my $first_line;
my @line;

open IN,'<',$gff;

H:while(<IN>){
    chomp;
    if (/^#/){
        $head .= $_;
    }else{
        $first_line = $_;
        last H;
    }
}

J:while(1){
    @line = split/\t/,$first_line;
    if($line[2] ne "gene"){
        print STDERR "$. : maybe format error";
        $head .= $first_line;
    }else{
        last J;
    }
}

my %h2;
(my $last_gene = $line[8]) =~ s/ID=//;
my $num = sprintf"%05d",$c;
$line[8] =~ s/$last_gene/$new$num/;
my $p = join"\t",@line;

open O,'>',$name."rename.gff";
print O $p."\n";

$h2{$last_gene} = $new.$num;

while(<IN>){
    chomp;
    @line =split/\t/;

    if(exists $h1{$line[0]}){
        $line[0] = $h1{$line[0]};
    }
    
    if ($line[2] =~ /gene/){
        $c += 1;
        $num = sprintf"%05d",$c;
        (my $gene = $line[8]) =~ s/ID=//;
        if($gene ne $last_gene){
            $line[8] =~ s/$gene/$new$num/g;
            $last_gene = $gene;
            $h2{$last_gene} = $new.$num;
        }else{
            die "$. : duplicate gene exists\n";
        }
    }else{
        $line[8] =~ s/$last_gene/$new$num/g;
    }
    $p = join"\t",@line;
    print O $p."\n";
}
close O;

open O,'>',"convert.txt";
for my $k (sort {$a cmp $b} keys %h2){
    print O "$k\t$h2{$k}\n";
}
close O
