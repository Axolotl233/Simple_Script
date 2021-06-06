#Statistic result from RepeatMasker, RepeatModeler, RepeatProteinMasker and Trf

perl *gff ConvertRepeatMasker2gff.pl

#cat Denovo.gff TE.gff TP.gff | grep -v -P "^#" | cut -f 1,4,5 | sort -k1,1 -k2,2n -k3,3n > All.repeat.bed
#bedtools merge -i All.repeat.bed > All.repeat.merge.bed

perl path/to/0.GetPipeline.pl 1 $threads $genome_size
perl path/to/0.GetPipeline.pl 2 $threads $genome_size $repeat_size
