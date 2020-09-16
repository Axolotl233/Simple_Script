pipeline for Circos

grep '>' $genome.fa | perl -ple 'print if s/>//' >  0.Chrlist.txt
#then manual fix '0.Chrlist.txt'
perl Circos_Util/0.GrepChrFasta.pl 0.Chrlist.txt Rl.genome.hic.fa > Rl.genome.hic.circos.fa
#
