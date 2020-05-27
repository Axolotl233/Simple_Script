#! perl

use FindBin qw($Bin);

my $s = $ARGV[0];

if($s eq "1"){

    my $t = $ARGV[1];
    my $g = $ARGV[2];

    open S1,'>',"0.step1.sh";

    print S1 "perl $Bin/Util/TypeBed.pl > All.repeat.type.sort.bed\n";
    print S1 "perl $Bin/Util/SplitBed.pl All.repeat.type.sort.bed\n";
    print S1 "perl $Bin/Util/CreatRepeatChart.pl $t > RepeatStatistic.txt\n";
    print S1 "perl $Bin/Util/RateRepeat.pl $g RepeatStatistic.txt\n";

}

if ($s == "2"){
    open S2,'>',"0.step2.sh";

    my $t = $ARGV[1];
    my $g = $ARGV[2];
    my $r = $ARGV[3];
    print S2 "perl $Bin/Util/SplitGff3.pl ./\n";
    print S2 "perl $Bin/Util/ClassStatisticByContig.pl $t\n";
    print S2 "perl $Bin/Util/MergeClassRes.pl $g $r\n";
}
