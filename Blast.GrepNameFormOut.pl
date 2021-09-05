#! perl

use warnings;
use strict;
use PerlIO::gzip;
use Cwd;

my $h_dir = getcwd();
print STDERR "perl $0 blast.out(tab split) /data/01/user112/database/nr/prot.accession2taxid.gz /data/01/user112/database/nr/names.dmp out.file.name\n";

my %h;
open B,'<',shift;
while(<B>){
    my $nr_p =(split/\t/,$_)[1];
    $h{$nr_p} = 1;
}
close B;
open T,'<:gzip',shift;
open E,'>',"$h_dir/GrepNameFormBlastOut.tmp";
my %h2;
while(<T>){
    my @line = split/\t/,$_;
    if(exists $h{$line[1]}){
        $h{$line[1]} = $line[2];
        push @{$h2{$line[2]}} ,$line[1];
        print E $line[1]."\t".$line[2]."\n";
    }
}
close T;
close E;
my %h3;
open R,'<',"$h_dir/GrepNameFormBlastOut.tmp";
while(<R>){
    chomp;
    my $num = (split/\t/,$_)[1];
    next if (! $num =~ /\d/);
    $h3{$num} += 1;
}

open N,'<',shift;
open O,'>',shift;
while(<N>){
    chomp;
    next unless /scientific name/;
    my @n = split/\|/,$_;
    $n[0] =~ s/\s+//g;
    $n[1] =~ s/\s+//g;
    if (exists $h3{$n[0]}){
        print O $n[0]."\t".$n[1];
        print O "\t".$h3{$n[0]};
        print O "\n";
    }
}
