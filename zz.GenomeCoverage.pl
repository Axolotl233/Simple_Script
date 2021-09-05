
my ($file,$genomeSize)=@ARGV;
my $id;
#if($file=~m/(.*\/)(\S+)\.(realn|sort|rehead)\.bam$/){
if ($file=~/([^\/]+)$/){
    $id=$1;
}else{
    die "$file\n";
}


my $sites=0;
my $depth=0;
open(F,"samtools depth $file |");
while(<F>){
    chomp;
    next if(/^\s*$/);
    my @a=split("\t",$_);

    $sites++;
    $depth+=$a[2];
}
close(F);
my $gc=$sites/$genomeSize;
my $ed=$depth/$genomeSize;

my $aln=0;
open(F, "samtools view $file |");
while(<F>){
    chomp;
    next if(/^\@SQ/);
    my @a=split(/\s+/);
    my $flag=$a[1];
    next if($flag & 4);
    next if($flag > 255);
    $aln++;
}
close F;


open(O,'>',"$file.GCstat");
print O  "#ID\tMappedReads\tCoveredSites\tSumDepth\tGenomeCoverage\tEffectiveDepth\n";
print O "$id\t$aln\t$sites\t$depth\t$gc\t$ed\n";
close(O);

