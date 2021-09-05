#! perl

use warnings;
use strict;
use Cwd;

my $h_dir = getcwd();
my $round = shift;
$round //= "0,9";
if(! $round =~ /,/){
    &print_help();
    exit;
}
my @num = split/,/,$round;
if(scalar @num != 2){
    &print_help();
    exit;
}
unless($num[0] =~/^\d+$/ && $num[1] =~/^\d+$/){
    &print_help();
    exit;
}
unless(-e "mcmctree.2.ctl" && -e "out.BV" && -e "species.tree1"){
    &print_help();
    exit;
}
for(my $i = $num[0];$i<= $num[1];$i++){
    next if -e "r$i";
    mkdir "r$i";
    print "cd r$i;ln -s ../species.tree1;ln -s ../out.BV in.BV;ln -s ../mcmctree.2.ctl;mcmctree  mcmctree.2.ctl > mcmctree.ctl.log 2>&1 ; cd ..\n";
}

sub print_help{
    print STDERR<<USAGE;
    perl Mcmctree2.pl start_num,end_num[0,9];
         need file : mcmctree.2.ctl, out.BV, species.tree1(mcmctree  mcmctree.3.ctl > mcmctree.ctl.3.log 2>&1)
USAGE

  }
  
