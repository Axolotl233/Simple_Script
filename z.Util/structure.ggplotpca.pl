use strict;
use warnings;

my $evec=shift or die "perl $0 \$evec \$ind\n";
my %dy;
my $ind=shift or die "perl $0 \$evec \$ind\n";
open (F,"$ind");
while (<F>) {
    chomp;
    my @a=split(/\s+/,$_);
    $a[1]=~/^([a-zA-Z]+)/;
    $dy{$a[0]} = $a[1];
    #$dy{$a[0]}=$1;
}
close F;
open (F,"$evec")||die"$!";
open (O,">$evec.ggplot2");
while (<F>) {
    chomp;
    s/^\s+//;
    my @a=split(/\s+/,$_);
    if (/^#eigvals/){
        print O "FID\tPC1\tPC2\tPC3\tPC4\tPC5\tPC6\tPC7\tPC8\tPC9\tPC10\tspecies\n";
    }else{
        #$a[0]=~/\d+\:([a-zA-Z]+)/ or die "$_\n";
        #$a[-1]=$1;
        $a[-1]=$dy{$a[0]};
        print O join("\t",@a),"\n";
    }
}
close F;
close O;

open (O1,">$evec.R");
print O1 "library(\"ggplot2\");\n";
print O1 "a=read.table(\"$evec.ggplot2.fix\",header=T);\n\n";
for (my $i=1;$i<=3;$i++){
    for (my $j=$i+1;$j<=4;$j++){
        print O1 "pdf(file=\"$evec.PC$i","_PC$j.pdf\");\n";
        print O1 "ggplot(a,aes(PC$i,PC$j,color=species))+geom_point(alpha=0.8,size=4)\n";
        print O1 "dev.off()\n\n";
    }
}
close O1;
