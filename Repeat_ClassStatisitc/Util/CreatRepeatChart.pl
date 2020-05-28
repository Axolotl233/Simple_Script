#! perl

use warnings;
use strict;
use MCE::Loop;
use File::Basename;
#use Hash::Merge qw( merge );

my $thread_mce = shift;
MCE::Loop::init {chunk_size => 1,max_workers => $thread_mce,};

my @files = grep {/.txt/} `find ./split_bed`;
chomp $_ for @files;
print "contig\tRepeatMasker\tRepeatModeler\tRepeatProteinMasker\tTRF\tTotal\n";

mce_loop{ &run($_) } @files;

sub run {
    my $file = shift @_;
    open my $fileIN,'<',$file;
    my %h;
    my %box;
    @{$h{RepeatMasker}{0}} = (1,0);
    @{$h{RepeatProteinMask}{0}} = (1,0);
    @{$h{RepeatModeler}{0}} = (1,0);
    @{$h{TRF}{0}} = (1,0);
    my $count = 1;
    while(<$fileIN>){

        chomp;
        my @line = split/\t/;
        
        if($line[3] =~ /RepeatMasker/){
            push @{$h{RepeatMasker}{$count}},($line[1],$line[2]);
            $count += 1;
        }elsif($line[3] =~ /RepeatModeler/){
            push @{$h{RepeatModeler}{$count}},($line[1],$line[2]);
            $count += 1;
        }elsif($line[3] =~ /RepeatProteinMask/){
            push @{$h{RepeatProteinMask}{$count}},($line[1],$line[2]);
            $count += 1;
        }elsif($line[3] =~ /TRF/){
            push @{$h{TRF}{$count}},($line[1],$line[2]);
            $count += 1;
        }
    }
    close $fileIN;
    (my $name = basename $file) =~ s/\.bed.txt//;
    my %t;
    my @p =(1,2);
    my @tmp;
    push @tmp,$name;
   #map {print $_."\n"} sort keys %h;exit;
    for my $method (sort keys %h){
        my $ref = \%{$h{$method}};
        %t = (%{$h{$method}},%t);
        %box = &bin_merge($ref);
        push @tmp ,&print_res(\%box,$p[0]);
        #%t = (%box,%t);
    }
    %t = &bin_merge(\%t);
    push @tmp,&print_res(\%t,$p[1]);
    my $tmp  = join"\t",@tmp;
    print $tmp;
}

sub print_res{
    my $ref = shift @_;
    my %h = %{$ref};
    my $t_len = 0;
    my $p = shift @_;

    for my $k1 (keys %h){
        $t_len = ${$h{$k1}}[1] - ${$h{$k1}}[0] + $t_len + 1;
    }
    if($p == 1){
        return "$t_len";
    }else{
        return "$t_len\n";
    }
}

  sub bin_merge{
      
      my $ref = shift @_;
      my %h = %{$ref};
      my @a = sort{${$h{$a}}[0] <=> ${$h{$b}}[0]} keys %h;
      
      my %b;
      my $start;
      my $end;

      for(my $i = 0;$i< @a; $i++){
          if($i > 0){
              $start = ${$h{$a[$i]}}[0];
              $end = ${$h{$a[$i]}}[1];
              if($start > ${$b{$i-1}}[1]){
	  ${$b{$i}}[0] = $start;
	  ${$b{$i}}[1] = $end;
              }else{
	  ${$b{$i}}[0] = (${$b{$i-1}}[0]<$start)?${$b{$i-1}}[0]:$start;
	  ${$b{$i}}[1] = (${$b{$i-1}}[1]<$end)?$end:${$b{$i-1}}[1];
	  delete $b{$i-1};
              }
          }else{
              $start = ${$h{$a[$i]}}[0];
              $end = ${$h{$a[$i]}}[1];
              ${$b{$i}}[0] = $start;
              ${$b{$i}}[1] = $end;
          }
      }
      my @d = sort{$a <=> $b} keys %b;
      if(@d == 1){
          return %b;
      }else{
          my $c = 0;
          for(my $i =0;$i< @d;$i++){
              if($i == 0){
	  next;
              }else{
	  #print $b{$d[$i-1]}[1];exit;
	  if(${$b{$d[$i-1]}}[1] > ${$b{$d[$i]}}[0]){
	      $c += 1;
	  }
              }
          }
          if ($c == 0){
              return %b;
          }else{
              %b = &bin_merge(\%b);
          }
      }
}
