Statistic result from RepeatMasker,RepeatModeler,RepeatProteinMasker

perl *gff ConvertRepeatMasker2gff.pl
cat Denovo.gff TE.gff TP.gff | grep -v -P "^#" | cut -f 1,4,5 | sort -k1,1 -k2,2n -k3,3n > All.repeat.bed
bedtools merge -i All.repeat.bed > All.repeat.merge.bed
