#! perl

use warnings;
use strict;
use Getopt::Long;
use File::Basename;

(my $bed, my $window_file, my $window_length, my $extend_bp, my $value_line,my $out);
GetOptions(
           'bed=s' => \$bed,
           'file=s' => \$window_file,
           'window=s' => \$window_length,
           'extend=s' => \$extend_bp,
           'value=s' => \$value_line,
           'out=s' => \$out
          );
for my $s ($bed,$window_file,$out){
    if(!$s){
        print STDERR "USAGE : perl $0 
                                    --bed    \$gene_bed\[Chr start end gene\] (tab split)
                                    --file   \$fst_res\[chr window_start window_end\] (tab split,need head line) 
                                    --window \$window_length 
                                    --extend \$extend_bp
                                    --value  \$value_line
                                    --out    \$out
";
        exit;
    }
}
$window_length //= 10000;
$extend_bp //= 2000;
$value_line //= 4;
my %r;
open R,'<',$bed or die "$!";
while(<R>){
    chomp;
    my @line = split/\t/;
    $r{$line[0]}{$line[3]} = [$line[1],$line[2]];
}
close R;

my %h;
open IN,'<',$window_file or die "$!";
readline IN;
while(<IN>){
    chomp;
    my @line = split/\t/;
    for my $k2(keys %{$r{$line[0]}}){
        my $s = ${$r{$line[0]}{$k2}}[0] - $extend_bp ;
        my $e = ${$r{$line[0]}{$k2}}[1] + $extend_bp ;
        my $gene_length = $e - $s;
        my $v = $value_line;
        my @p = ($line[0],$s,$e,$line[$v],$line[1],$line[2]);
        my $c = 0;
        if ($e < $line[1]){
            next;
        }elsif($s > $line[2]){
            next;
        }elsif ($s < $line[1] && $e > $line[1]){
            if ($e > $line[2]){
	$c = 1;
            }else{
	$c = ($e - $line[1] + 1)/$gene_length;
            }
        }elsif ($s < $line[2] && $e > $line[2]){
            if ( $s < $line[1]){
	$c = 1;
            }else{
	$c = ($line[2] - $s + 1)/$gene_length;
            }
        }elsif ($s > $line[1] && $e < $line[2]){
            $c = 1;
        }
        if($c == 1){
            push @p , ("full",$c);
            $h{$line[0]}{$k2} = \@p;
        }elsif($c != 0){
            push @p , ("part",$c);
            $h{$line[0]}{$k2} = \@p;
        }
    }
}
open O,'>',"$out";
print O "chr\tgene_s\tgene_e\tvalue\twindow_s\twindow_e\tclass\tper\n";
for my $k (sort {$a cmp $b} keys %h){
    for my $k2 (sort {$a cmp $b} keys %{$h{$k}}){
        my $p = join "\t", @{$h{$k}{$k2}};
        print O $k2."\t".$p."\n";
    }
}
