perl Util/SplitBed.pl All.repeat.type.sort.bed
perl Util/CreatRepeatChart.pl $theadnum > RepeatStatistic.txt
perl Util/RateRepeat.pl $genome_size RepeatStatistic.txt
perl Util/SplitGff3.pl $PathIncludeRepeatGFF
perl Util/ClassStatisticByContig.pl $threadnum
perl Util/MergeClassRes.pl $genome_size $repeatsize
