#! perl

BEGIN {
    my $module = "/data/00/user/user112/perl5/lib/perl5";
    unshift(@INC, $module);
}

use warnings;
use strict;
use Getopt::Long;
use Cwd 'abs_path';
use File::Basename;
use Switch;

my ($config,$out_dir);
GetOptions(
           'config=s' => \$config,
           'o=s' => \$out_dir
          );

if ((! $config) || (! $out_dir)){
    &print_help;
    exit;
}

my %config = &read_conf;

my $racon = "c";
my $pilon = "c";
#map {print"$_:$config{$_}\n"}keys %config;
foreach (keys %config){
    switch($_){
        case "genome" {
	       die"must have a path to draft genome\n" if ($config{genome} eq "a" );
	      }
          case "correct" { if (($config{correct}) eq "a") {
              print STDERR "\n\n\n\nyou don't have long reads, just run Pilon\n\n\n\n";
              $racon = "false";
          }
	         }
          case "NGS" {if ($config{NGS} eq "a") {
              print STDERR "\n\n\n\nyou don't have short reads, just run Racon\n\n\n\n";
              $pilon = "false";
          }
	     }
          case "bwa" {$config{bwa}= "bwa" if ($config{bwa} eq "a");}
          case "samtools" {$config{samtools}= "samtools" if ($config{samtools} eq "a");}
          case "minimap2" {$config{minimap2}= "minimap2" if ($config{minimap2} eq "a");}
          case "pilon" {die "you must have path to pilon.jar\n" if ($config{pilon} eq "a");}
          case "racon" {$config{racon}= "racon" if ($config{racon} eq "a");}
          case "pilon_mem" {$config{pilon_mem}= "50G" if ($config{pilon_mem} eq "a");}
          case "threads" {$config{threads}= "20" if ($config{threads} eq "a");}
          case "racon_cycle" {$config{racon_cycle}= "2" if ($config{racon_cycle} eq "a");}
          case "pilon_cycle" {$config{pilon_cycle}= "2" if ($config{pilon_cycle} eq "a");}
          else {print STDERR "trash program\n"}
    }
    #print "$_:$config{$_}\n";
}

$out_dir = abs_path($out_dir);
system("mkdir $out_dir") unless (-d $out_dir);
my $name;
eval{($name = basename ($config{genome})) =~ s/(.*)\..*/$1/};
$name = "default" unless($name);

#################racon################
while(1){
    last if ($racon eq "false");
    system("mkdir $out_dir/0.racon");
    chdir("$out_dir/0.racon");
    
    my $c_racon = $config{racon_cycle};
    
    for(my $i = 1;$i <= $c_racon;$i++){
        system("mkdir racon$i");
        chdir("racon$i") or die "$!";
        open OUT,'>',"racon$i.sh";
        print OUT "cd $out_dir/0.racon/racon$i\n";
        print OUT "$config{minimap2} -t $config{threads} -ax map-pb $config{genome} $config{correct} --secondary=no | samtools sort -@ 50 -O SAM  > $name\_racon$i.sam\n";
        print OUT "$config{racon} -t $config{threads} $config{correct} $out_dir/0.racon/racon$i/$name\_racon$i.sam $config{genome} > $name\_racon$i.fa\n";
        $config{genome} = "$out_dir/0.racon/racon$i/$name\_racon$i.fa";
        chdir("$out_dir/0.racon");
    }
    close OUT;
    
    chdir("$out_dir");
    open R,'>>',"0.final.sh";
    map {print R "sh $out_dir/0.racon/racon$_/racon$_.sh\n"} (1..$config{racon_cycle});
    close R;
    last;
}
################pilon##################
while(1){
    last if ($pilon eq "false");
    #print $config{NGS};exit;
    $config{NGS} =~ s/\s//g;
    my @NGS = split/;/,$config{NGS};
    
    system("mkdir $out_dir/0.pilon");
    chdir("$out_dir/0.pilon");
    
    my $c_pilon = $config{pilon_cycle};
    for(my $i = 1;$i <= $c_pilon;$i++){
        system("mkdir pilon$i");
        chdir("pilon$i") or die "$!";
        open OUT,'>',"pilon$i.sh";
        print OUT "cd $out_dir/0.pilon/pilon$i\n";
        print OUT "$config{bwa} index $config{genome}\n";
        print OUT "$config{bwa} mem -t $config{threads} $config{genome} $NGS[0] $NGS[1] | $config{samtools} sort -@ $config{threads} > bwa_tmp$i.bam\n";
        print OUT "$config{samtools} index bwa_tmp$i.bam\n";
        print OUT "java -Xmx$config{pilon_mem} -jar $config{pilon} --threads $config{threads} --fix all --genome $config{genome} --frags bwa_tmp$i.bam --output pilon$i\n";
        $config{genome} = "$out_dir/0.pilon/pilon$i/pilon$i.fasta";
        chdir("$out_dir/0.pilon");
    }
    close OUT;
    
    chdir("$out_dir");
    open P,'>>',"0.final.sh";
    map {print P "sh $out_dir/0.pilon/pilon$_/pilon$_.sh\n"} (1..$config{pilon_cycle});
    close P;
    last;
}

#######################################

print STDERR "\n###################################\n\n"."All done, please run command \'sh $out_dir/0.final.sh\' "."\n\n###################################\n\n";

######################################
sub read_conf{
    my %r;
    my $term; my $c;
    $config=abs_path($config);
    open (TF,"$config") || die "no such file: $config\n";
    while (<TF>) {
        chomp;
        next if /^#/;
        next if /^\s*$/;
        #next unless $_=~/^(\S+)\s*?=\s*?(\S+)/;
        $_=~/^(\S+)\s*?=/;
        $term = $1;
        if ($_=~ /=\s*?([^#\s]+)\s*?#*?.*/){
            #print "$1\n";
            $c = ($1);
        }else {
            $c = "a";
        }
        #print "$c\n";
        $r{$term}=$c;
    }
    close TF;
    return %r;
}

sub print_help{
    print STDERR<<USAGE;
    
    Usage: perl polish_cmd.pl --config <config file> --out_dir <path2dir>
      
      Options:
      --config    giving the config file with all needed things.
      --o   directory of out file:

USAGE

}
  
