#! perl

open IN,'<',shift;

while(<IN>){
    chomp;
    $h{$_} = 1;
}

close IN;

open IN,'<',shift;

while(<IN>){
    (my $id,my $phase) = (split/\t/,$_)[0,2];
    next unless exists $h{$id};
    next unless $phase eq gene;
    (my $start,my$end) = (split/\t/,$_)[4,5];
    my $middle = ($start + $end)/2;
    print $id."\t".$middle."\n";
}
