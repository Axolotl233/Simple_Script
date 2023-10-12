#! perl

use warnings;
use strict;
use File::Basename;
use List::Util qw(sum);
use Cwd;

print STDERR "perl $0 \$dir [\$out_prefix] [\$gene_name:gene\[g\] or transcript\[t\]\n";
my $h_dir = getcwd();
my $dir = shift or die "need dir contain gtf file\n";
my $pre = shift;
my $p_name = shift;
$pre //= "prefix";
$p_name //= "t";

my @files = grep{/gtf$/}`find $dir`;
my %f;my @n;my %t;

for my $file (sort {$a cmp $b} @files) {
    chomp $file;
    (my $name = basename $file) =~ s/(.*?)\.gtf/$1/;
    open IN,'<',$file;
    push @n,$name;
    while(<IN>){
        next if /^#/;
        my $jud = (split/\t/,$_)[2];
        next unless $jud =~ /transcript/;
        my $id;
        if($p_name eq "g"){
            #gene_id "MSTRG.51";
            if(/gene_id "(.*?)";/){
	
	$id = $1;
            }else{
	#print $_;
	#exit;
	next;
            }
        }elsif($p_name eq "t"){
            #transcript_id "evm.model.BhD1.14"
            /transcript_id "(.*?)";/;
            $id = $1;
        }
        #FPKM "0.421433"; TPM "0.908573";
        /FPKM "(.*?)"; TPM "(.*?)";/;
        my $f = $1;
        my $t = $2;
        #if(exists $f{$id}{$name}){
        #    print STDERR "duplicate $p_name id\n";
        #    exit;
        #}
        push @{$f{$id}{$name}} ,$f;
        push @{$t{$id}{$name}} ,$t;
    }
    close IN;
}

@n = sort {$a cmp $b} @n;

&out("fpkm",\%f);
&out("tpm",\%t);

sub out{
    my $c = shift @_;
    my $ref = shift @_;
    my %h = %{$ref};

    open OUT,'>',"$pre.$c.txt";
    print OUT "gene_id";
    map {print OUT "\t".$_} @n;
    print OUT "\n";

    for my $k1 (sort {$a cmp $b} keys %h){
        print OUT "$k1";
        for my $k2 (@n){
            if (exists $h{$k1}{$k2}){
	my $su = sum (@{$h{$k1}{$k2}});
	print OUT "\t$su";
            }else{
	print OUT "\t0";
            }
        }
        print OUT "\n";
    }
    close OUT;
}
