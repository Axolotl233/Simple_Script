#! perl
#python /data/00/user/user112/software/goatools/scripts/find_enrichment.py --obo /data/01/user112/database/go/go-basic.obo --goslim /data/01/user112/database/go/goslim_generic.obo --outfile=Fst.AS-ES.50K.12.5K.windowed.weir.phase.fst.top1.fst.gene.list.go.xlsx Fst.AS-ES.50K.12.5K.windowed.weir.phase.fst.top1.fst.gene.list /data/01/user112/project/Brachypodium/04.annotation/Bsta-pbc-hic.fix/evm.gene.lst /data/01/user112/project/Brachypodium/04.annotation/Bsta-pbc-hic.fix/12.go_final/merge.go.goatools.out.txt;

use warnings;
use strict;
use File::Basename;

my $script = "/data/00/user/user112/code/script/z.Util";
my $tools = "/data/00/user/user112/software/goatools/scripts/find_enrichment.py";
my $obo = "/data/01/user112/database/go/go-basic.obo";
my $slim = "/data/01/user112/database/go/goslim_generic.obo";

my $dir = shift or die "need dir contain study gene\n";
my $app = shift;
$app //= "lst";

my $gene = shift;
my $background = shift;
$gene //= "/data/01/user112/project/Brachypodium/04.annotation/Bsta-pbc-hic.fix/evm.gene.lst";
#$background //= "/data/01/user112/project/Brachypodium/04.annotation/Bsta-pbc-hic.fix/12.go_final/merge.go.goatools.out.txt";
$background //= "/data/01/user112/project/Brachypodium/04.annotation/Bsta-pbc-hic.fix/12.go_final/merge.go.goatools.out.no_nr.no_swissprot.txt";
#$gene //= "/data/01/user112/project/Brachypodium/07.evo/07.bhyb_subgenome_bias/1.gene_expression/0.data/all.pair.gene.txt";
#$gene //= "/data/01/user112/project/Brachypodium/04.annotation/Bhyb-pbc-hic.fix/merge.out.gene.lst";
#$background = "/data/01/user112/project/Brachypodium/04.annotation/Bhyb-pbc-hic.fix/08.go/merge.go.goatools.out.txt";

my @fs = grep {/$app$/} `find $dir`;
for my $f (@fs){
    chomp $f;
    (my $n = basename $f) =~ s/(.*)\..*/$1/;
    my $o = $n."\.xlsx";
    print "python $tools --obo $obo --goslim $slim --outfile=$o $f $gene $background;perl $script/goatools.filter.pl $o > $n.goplot.txt;perl $script/goatools.plot.pl $n.goplot.txt > $n.goplot.R\n";
}
