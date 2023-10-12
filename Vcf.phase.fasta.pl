#! perl

use warnings;
use strict;
use File::Basename;
use Getopt::Long;

my ($vcf,$type,$ref_file,$out);
GetOptions(
           'vcf=s' => \$vcf,
           'type=s' => \$type,
           'ref=s' => \$ref_file,
           'out=s' => \$out
          );
if (!$vcf){
    print "USAGE : perl $0 --vcf \$vcf [--type 1 or 2 --ref ref_site,chr loc --out out name]\n";
    exit;
}

$type //= 2;
my %ref;
if($ref_file){
    %ref = &get_ref($ref_file);
}
my $fh;
if($vcf =~ /.gz$/){
    open $fh, "zcat $vcf|" or die "$!";
}else{
    open $fh,'<',$vcf or die "$!";
}
my $vcf_name = (basename $vcf =~ s/\..*//);
$out //= $vcf_name."fa";
my @head;push @head, 0..8;
my %fa2;
srand(time());
my $d = 0;

D:while(<$fh>){
    next if /^##/;
    chomp;
    if(/^#C/){
        my @line = (split/\t/,$_);
        for(my $i = 9;$i< @line;$i += 1){
            push @head, $line[$i];
        }
    }else{
        my @line = split/\t/,$_;
        my $p;
        if($ref_file){
            next D if (!exists $ref{$line[0]}{$line[1]});
        }
        $d += 1;
        my $tmp_base = $line[3].",".$line[4];
        my @base = split/,/,$tmp_base; # 0 for ref, 1.. for ale
        if ($type == 1){
            if($line[8] =~ /AD/){
	for(my $i = 9;$i< @line;$i += 1){
	    if ($line[$i] =~/^\.\/\./){
	        $p = "-";
	        $fa2{$head[$i]}{$line[0]}{$line[1]} = $p;
	    }else{
	        my @info = split/:/,$line[$i];
	        $info[0] =~ /(\d+)\/(\d+)/;
	        (my $GT1,my $GT2) = ($1,$2);
	        (my $dep_ref,my $dep_alt) = (split/,/,$info[1])[0,1];
	        if($dep_ref == $dep_alt){
	            if ($dep_ref == 0){
		$p="-";
		$fa2{$head[$i]}{$line[0]}{$line[1]} = $p;
	            }else{
		my $jud = int(rand(100));
		$p = ($jud < 50)? $base[$GT1]:$base[$GT2];
		$fa2{$head[$i]}{$line[0]}{$line[1]} = $p;
	            }
	        }else{
	            $p = ($dep_ref > $dep_alt)? $base[$GT1]:$base[$GT2];
	            $fa2{$head[$i]}{$line[0]}{$line[1]} = $p;
	        }
	    }
	}
            }else{
	print STDERR "CAN'T CALULATE ALLELE in $line[0],$line[1]\n";
	next;
            }
        }
        if($type == 2){
            for(my $i = 9;$i< @line;$i += 1){
	if ($line[$i] =~/^\.\/\./){
	    $p = "--";
	    $fa2{$head[$i]}{$line[0]}{$line[1]} = $p;
	    #push @{$fa{$head[$i]}}, $p;
	}else{
	    my @info = split/:/,$line[$i];
	    $info[0] =~ /(\d+)\/(\d+)/;
	    (my $GT1,my $GT2) = ($1,$2);
	    $p = "$base[$GT1]$base[$GT2]";
	    $fa2{$head[$i]}{$line[0]}{$line[1]} = $p;
	    #push @{$fa{$head[$i]}}, $p;
	}
            }
        }
    }
}
close $fh;
open O,'>',"$out";
for my $sam (sort {$a cmp $b} keys %fa2){
    print O ">$sam\n";
    for my $chr (sort {$a cmp $b} keys %{$fa2{$sam}}){
        for my $loc (sort {$a <=> $b} keys %{$fa2{$sam}{$chr}}){
            print O "$fa2{$sam}{$chr}{$loc}";
	    }
    }
    print O "\n";
}
print STDERR "$d\n";

sub get_ref{
    my $f = shift @_;
    open R,'<', $f or die "$!";
    my %h;
    while(<R>){
        chomp;
        my @kk=split /\s+/,$_;
        my $chr=$kk[0];
        my $loc=$kk[1];
        $h{$chr}{$loc} = 1;
    }
    close R;
    return %h;
}
