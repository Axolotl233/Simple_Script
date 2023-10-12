#! perl

use warnings;
use strict;

my $pop = shift;
my $vcf = shift;
my $rate = shift;
$rate //= "no";

if(! $vcf || !$pop){
    print STDERR "USAGE : perl $0 \$pop \$vcf \$rate[no:yes]\n";
    exit;
}
my %gr = read_pop($pop);
my %gr2;
for my $k (sort {$a cmp $b} keys %gr){
    $gr2{$gr{$k}} += 1;
}
my $fh;
if($vcf =~ /gz$/){
    open $fh, "zcat $vcf |" or die "$!";
}else{
    open $fh,'<',$vcf;
}

print "CHROM\tPOS\tREF\tALT";
for my $k (sort {$a cmp $b} keys %gr2){
    print "\t"."$k";
}
print "\n";
my @head;push @head,0..8;
while(<$fh>){
    chomp;
    if(/^##/){
        next;
    }elsif(/^#C/){
        my @l = (split/\t/,$_);
        for(my $i = 9;$i< @l;$i += 1){
            push @head, $l[$i];
        }
    }else{
        my @l = split/\t/;
        my %tmp;
        my %tmp2;
        my @base = ($l[3],$l[4]);
        for(my $i = 9;$i< @l;$i += 1){
            my $tmp_gr = $gr{$head[$i]};
            $tmp2{$tmp_gr} += 1;
            if(!exists $tmp{$tmp_gr}){
	$tmp{$tmp_gr}{ref} = 0;
	$tmp{$tmp_gr}{heter} = 0;
	$tmp{$tmp_gr}{ale} = 0;
	$tmp{$tmp_gr}{miss} = 0;
            }
            my @t = split/:/,$l[$i];
            if ($t[0] eq "./." || $t[0] eq ".|."){
	$tmp{$tmp_gr}{miss} += 1;
            }elsif ($t[0] eq "0/0" || $t[0] eq "0|0"){
	$tmp{$tmp_gr}{ref} += 1;
            }elsif ($t[0] eq "1/1" || $t[0] eq "1|1"){
	$tmp{$tmp_gr}{ale} += 1;
            }else{
	$tmp{$tmp_gr}{heter} += 1;
            }
        }
        print "$l[0]\t$l[1]\t$l[3]\t$l[4]";
        for my $k(sort {$a cmp $b} keys %gr2){
            my @p;
            
            if($rate eq "yes"){
	push @p, sprintf("%.2f",$tmp{$k}{ref}/$tmp2{$k});
	push @p, sprintf("%.2f",$tmp{$k}{heter}/$tmp2{$k});
	push @p, sprintf("%.2f",$tmp{$k}{ale}/$tmp2{$k});
	push @p, sprintf("%.2f",$tmp{$k}{miss}/$tmp2{$k});
            }else{
	push @p, $tmp{$k}{ref};
	push @p, $tmp{$k}{heter};
	push @p, $tmp{$k}{ale};
	push @p, $tmp{$k}{miss};
            }
            print "\t";
            print join":",@p;
        }
        print "\n";
    }
}
sub read_pop{
    my $f = shift;
    my %h;
    open IN,'<',$f;
    while(<IN>){
        chomp;
        my @l = split/\t/;
        $h{$l[0]} = $l[1];
    }
    close IN;
    return %h;
}
