#! perl

my @file = sort {$a cmp $b} `find ./res`;
my $pos;

for my $file(@file){
    chomp;
    open IN,"<$file" or die "$!";
    while (<IN>){
        if(/id/){
            if(!$pos){
	s/id\t//;
	print $_;
	$pos = 1;
            }
        }else{
            chomp;
            my @a = split/\t/;
            for(my $i = 0;$i<10;$i+=1){
	if (!$a[$i]){
	    $a[$i] = 0
	}
            }
            next if ($a[9] eq "0.0");
            shift @a;
            #print scalar @a;
            my $line = join"\t",@a;
            print $line."\n";
        }
    }
}

