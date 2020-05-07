#! perl

use warnings;
use strict;
use Getopt::Long;
use Cwd 'abs_path';
use File::Basename;
use PerlIO::gzip;
use MCE::Map;
use MCE::Loop;
use MCE::Flow;
use MCE::Candy;

=filter_annotation

0:depth out of 3 or 1/3 (default) fold of sample aveage depth
1:GQ value < 20 (default)
2:only called in several samples (default=0.8)
3:DP range (default 2 and 50)
4:SNP site in range 5 bp (default) of INDEL 
5:SNP site in repeat region

=cut
sub print_help{


    print STDERR<<USAGE;

    Usage: perl SnpFilterMultithreads.pl -c <config file> -o <path2dir> -n <INT> -s -g -m -D -i -R [--all] -t 

      Options:
      -c   giving the config file with all needed things.
      -o   directory of out file.
      -t   save temp file of every step.
      -n   number of threads;

      Filter Parameter:
      -s   filter site depth out of 3 or 1/3 (default) fold of sample aveage depth
      -g   filter site GQ value < 20 (default)
      -m   filter site only called in several samples (default=0.2)
      -D   DP range (default (2 to 50)*sample_num)
      -I   SNP site in range 5 bp (default) of INDEL(need Indel.vcf.gz)
      -R   SNP site in repeat region(need bed file of repeat region)
      -a   ALL of above
      
      FORMAT must be GT:AD:DP:GQ:PL or GT:AD:DP:GQ:PGT:PID:PL  

USAGE
}

my @step;
(my $config,my $out_dir,my $all,my $middle,my $thread);

GetOptions(
           'sample_depth' => \$step[0],
           'GQ' => \$step[1],
           'miss' => \$step[2],
           'DP' => \$step[3],
           'Indel' => \$step[4],
           'Repeat' => \$step[5],
           'temp' => \$middle,
           'all' => \$all,
           'out_dir=s' => \$out_dir,
           'config=s' => \$config,
           'nubmerthread=s' => \$thread
          );

unless (($config && $out_dir)){
    &print_help;
    exit;
}
map{$_ = 1} @step if ($all);

$thread = 1 unless ($thread);
MCE::Map::init {
    max_workers => $thread, chunk_size => 1
};
MCE::Loop::init {
    max_workers => $thread, chunk_size => 1
};

my @item = qw/Depth_of_sample GQ_value Miss_rate DP_value INDEL_nearby Repeat_region/;

print STDERR "\n==========================\n\nStart filter, these items will be done:\n";
for (my $i = 0;$i < @step;$i++){
    if($step[$i]){
        print STDERR "$item[$i]\n";
    }
}
print STDERR "\n==========================\n"."\nProgram Start!\n";

my %config = &read_conf;
my @name;

my %dp;
(my $dp_max,my $dp_min);
if($step[0]){
    $dp_max = $config{Sample_max};
    ($dp_min = $config{Sample_min}) =~ s/1\///;
    %dp = &Sample_depth_get($config{Depth_file});
}
my %indel_site;
my %repeat;

if($middle){
    for (my $i = 0;$i < @step;$i++){
        if($step[$i]){
            &Data_Loader($item[$i]);
            print STDERR "$item[$i] filter start\n";
            $config{Raw_vcf} = &Temp_file_create($config{Raw_vcf},"$item[$i]");
            print STDERR "$item[$i] filter done\n";
            &Mme_Free($item[$i]);
        }
    }
}else{
    open my $notmpIN ,"<:gzip", $config{Raw_vcf} or die "$!";
    (my $file_name = basename $config{Raw_vcf}) =~ s/vcf.gz/Final_Filter\.vcf\.gz/;
    
    open my $notmpOUT,">:gzip","$out_dir/$file_name";
    
    my @header;
    while(<$notmpIN>){
        if (/^#/){
        my $line = &Head_get($_);
        push @header, $line;
        }
        if(/^#C/){
            last;
        }
    }
    
    my @result = mce_map_f {&Mce_run_notemp($_)} $notmpIN;

    unshift @result, @header;
    mce_flow {
    chunk_size => 1, max_workers => $thread,
      gather => MCE::Candy::out_iter_fh($notmpOUT)
    }, sub {
      my ($mce, $chunk_ref, $chunk_id) = @_;
      $mce->gather($chunk_id, $chunk_ref->[0]); 
    }, @result;
    
    print STDERR "\nDone\n";
}
sub Mce_run_notemp{
    my $line = shift @_;
    my $token = "print";
    if (/^#/){
        my $line = &Head_get($line);
        return $line; 
    }else{
        if($step[0]){
            $line = &Sample_depth_filter($line);
        }
        if($step[1]){
            $line = &GQ_filter($line);
        }
        if($step[2]){
            $token = &Miss_filter($line);
            return undef if ($token eq "filter");
        }
        if($step[3]){
            $token = &DP_range_filter($line);
            return undef if ($token eq "filter");
        }
        if($step[4]){
            $token = &Indel_filter($line);
            return undef if ($token eq "filter");
        }
        if($step[5]){
            $token = &Repeat_filter($line);
            return undef if ($token eq "filter");
        }
        if($token eq "print"){
            return $line;
        }
    }
}

sub Head_get{
    my $line_head = shift @_;
    if ($line_head =~ /^##/){
        return $line_head;
    }
    elsif($line_head =~ /^#CHROM/){
        @name = split/\t/, $line_head;
        chomp $name[-1];
        print STDERR "VCF head have be geted~\n";
        return $line_head;
    }
}

sub Data_Loader{
    my $class = shift @_;
    if($class eq "INDEL_nearby"){
        my $indel_site = &Indel_get($config{Indel_vcf});
        %indel_site = %{$indel_site};
    }elsif($class eq "Repeat_region"){
        my $repeat = &Repeat_get($config{Repeat_bed});
        %repeat = %{$repeat};
    }
}

sub Prefix_Get{
    my $full_name = shift @_;
    my $new_prefix = $full_name;
    $new_prefix = "Rm".$full_name if $full_name =~ /^[RI]/;
    return $new_prefix;
}

sub Mce_run_temp{
    my $a = shift @_;
    my $met = shift @_;
    #print $met."\n";exit;
    my $token = "print";
        if ($met eq "Depth"){
	          my $line = $a;
	          $line = &Sample_depth_filter($a);
	          return $line;
        }elsif($met eq "GQ"){
	          my $line = $a;
	          $line = &GQ_filter($line);
	          return $line;
        }elsif($met eq "Miss"){
	          my $line = $a;
	          $token = &Miss_filter($line);
	          return $line if ($token eq "print");
        }elsif($met eq "DP"){
	          my $line = $a;
	          $token = &DP_range_filter($line);
	          return $line if ($token eq "print");    
        }elsif($met eq "INDEL"){
	          my $line = $a;
	          $token = &Indel_filter($line);
	          return $line if ($token eq "print");
        }elsif($met eq "Repeat"){
	          my $line = $a;
	          $token = &Repeat_filter($line);
	          return $line if ($token eq "print");
        }
    
}

sub Temp_file_create{
    my $raw_file = shift @_;
    (my $met = shift @_) =~ s/(.*?)_.*/$1/;
    my $prefix = &Prefix_Get($met);
    open my $fh ,"<:gzip", $raw_file or die "$!";
    (my $file_name = basename $raw_file) =~ s/vcf.gz//;
    $file_name .= $prefix;
    $file_name = "$out_dir/$file_name.vcf.gz";
    my @header;
    
    while(<$fh>){
        if (/^#/){
            my $line = &Head_get($_);
            push @header, $line;
        }
        if(/^#C/){
            last;
        }
    }
    
    open my $out,">:gzip", $file_name or die "$!";
    my @result = mce_map_f { &Mce_run_temp($_,$met) } $fh;
    #print scalar(@result);exit;
    unshift @result, @header;
    mce_flow {
    chunk_size => 1, max_workers => $thread,
      gather => MCE::Candy::out_iter_fh($out)
    }, sub {
      my ($mce, $chunk_ref, $chunk_id) = @_;
      $mce->gather($chunk_id, $chunk_ref->[0]); 
    }, @result;
    close $fh;
    close $out;
    undef @result;
    return $file_name;
}

sub Repeat_get{
    print STDERR "Load Repeat info start~\n";
    my $re_file = shift @_;
    my %temp_re;
    open my $repeat,'<', $re_file or die "$!";
    while(<$repeat>){
        next if /^#/;
        chomp;
        my @re = split /\t/,$_;
        next if (($re[2] - $re[1]) < 100);
        for(my $i = $re[1];$i <= $re[2];$i += 1){
            $temp_re{$re[0]}{$i}=1;
        }
    }
    print STDERR "Load Repeat success\n";
    return \%temp_re;
}

sub Mme_Free{
    my $class = shift @_;
        if($class eq "INDEL_nearby"){
            undef %indel_site;
        }elsif($class eq "Repeat_region"){
            undef %repeat; 
    }
}

sub Repeat_filter{
    my $line_re = shift @_;
    (my $chr,my $pos) = (split/\t/,$line_re)[0,1];
    if(exists $repeat{$chr}{$pos}){
        return "filter";
    }else{
        return "print";
    }
}   

sub Indel_get{
    print STDERR "Load INDEL info start~\n";
    my %temp;
    my $Indel_file = shift @_;
    open my $INDEL,"<:gzip",$Indel_file or die "$!";
    my $bp = $config{Indel_Range};
    while(<$INDEL>) {
        chomp;
        next if /^#/;
        next unless $_;
        my @a = split /\s+/, $_;
        my $len = length($a[3]);
        for(my $i = $a[1] - $bp;$i < $a[1] + $len + $bp ;$i ++){
            $temp{$a[0]}{$i} = 1;
        }
    }
    close $INDEL;
    print STDERR "load INDEL info success~\n";
    return \%temp;
}

sub Indel_filter{
    my $line_indel = shift @_;
    my @b = split /\t/, $line_indel;
    if(exists $indel_site{$b[0]}{$b[1]}){
        return "filter";
    }else{
        return "print";
    }
}
        
sub DP_range_filter{

    my $line_DP = shift @_;
    my $qual = (split/\t/,$line_DP)[5];
    (my $dp = $line_DP )=~s/.*;DP=(.*?);.*/$1/;
    my $num = scalar(@name)-9;
    my $site_max= $config{DP_max}*$num;
    my $site_min= $config{DP_min}*$num;
    unless($dp >= $site_min && $dp <= $site_max){
        return "filter";
    }
    unless($qual >= $config{Qual}){
        return "filter";
    }    
    return "print";
}

sub Miss_filter{
    my @line_miss_token;
    my $line_ms = shift @_;
    my @a =split/\s+/,$line_ms;
    my $n = 0;
    my $m=int ((@a-9)*$config{Rate});#print "$m";exit;
    for (my $i=9;$i<@a;$i++){
        if ($a[$i]=~/\.\/\./){
            $n++;
        }else{next;}
    }
    if ($n>$m){
        return "filter";
    }else{
        return "print";
    }
}

sub GQ_filter{
    my $line_gq=shift @_;
    my @a = split /\t+/, $line_gq;
    my @b;
    my $len = scalar @a;
    my @c = &Format_check($a[8]);
    for(my $i = 9;$i < $len;$i ++){
        unless($a[$i] eq "\.\/\."){
            @b = split ":", $a[$i];
            if((scalar(@b) != $c[0])){
	$a[$i] = $c[1];
            }elsif($b[0] =~ /^\.\/\./){
	$a[$i] = $c[1];
            }elsif($b[3] < $config{GQ_therehold} || $b[3] eq "\."){
	$a[$i] = $c[1];
            }
        }
    }
    my $out_gq = join "\t", @a;
    $out_gq .= "\n" unless $out_gq =~ /\n$/;
    return $out_gq;
}

sub Format_check{
    
    my $ar = shift @_;
    my @fo = split":",$ar;
    my @re;
    if (@fo == 5){
        @re = ("5",".\/.:0,0:0:.:0,0,0");
        return @re;
    }elsif(@fo == 7){
        @re=  ("7",".\/.:0,0:0:.:.:.:0,0,0");
        return @re;
    }   
}
    
sub Sample_depth_filter{
    my $line_dp = shift @_;
    #print $line_dp."\n";exit;
    my @a = split /\t/, $line_dp;
    my @b;
    my @c = &Format_check($a[8]);
    for(my $i = 9;$i < @a;$i ++){
        unless($a[$i] eq "\.\/\."){
            @b = split ":", $a[$i];
            if(!exists $dp{$name[$i]}){die "the data $name[$i] is not exists!";}
            my $min = int(($dp{$name[$i]}) / $dp_min);
            my $max = int(($dp{$name[$i]}) * $dp_max);
            if((scalar(@b) != $c[0])){
	                $a[$i] = $c[1];
            }elsif($b[2] eq "\."){
	                $a[$i] = $c[1];
            }elsif($b[2] > $max || $b[2] < $min){
	                $a[$i] = $c[1];
            }
        }
    }
    my $out_dp = join "\t", @a;
    $out_dp .= "\n" unless $out_dp =~ /\n$/;
    return $out_dp;
}

sub Sample_depth_get{
    my $dp_file = shift @_;
    print STDERR "Sample depth load start~\n";

    my %refer;
    
    open REF,"< $dp_file" or die "$!";
    
    while(<REF>){
        chomp;
        my @sdp_a = split /\t/, $_;
        $refer{$sdp_a[0]} = $sdp_a[1];
    }
    close REF;
    print STDERR "Sample depth load success~\n";
    return %refer;
}

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
            $c = ($1);
        }else {
            $c = "a";
        }
        $r{$term}=$c;

    }
    close TF;
    return %r;
}
