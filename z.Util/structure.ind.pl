my $ped=shift;
my $out=$ped.".ind";
my $count=0;
open(O,'>'."$out");
open(F,$ped);
while(<F>){
    chomp;
    my @a=split(/\s+/);
    my @b=split(//,$a[1]);
    my $ind="$a[1]";
    my $species="$b[0]$b[1]$b[2]";
    $count++;
    print O "$count\t$ind\t0\t0\t0\t$species\n";
}

close(F);
close(O);
