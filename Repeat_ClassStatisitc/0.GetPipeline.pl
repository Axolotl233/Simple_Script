#! perl

use FindBin qw($Bin);

if(!$ARGV[0]){
    print STDERR "USAGE : perl $0 [step1|step2]\n";
    exit;
}
if($ARGV[0] eq "step1"){
    if(scalar @ARGV != 3){
        print STDERR "USAGE : perl $0 step1 \$threads \$genome_size\n";
        exit;
    }
    my $t = $ARGV[1];
    my $g = $ARGV[2];
    open S1,'>',"0.step1.sh";
    print S1 "perl $Bin/Util/TypeBed.pl > All.repeat.type.sort.bed\n";
    print S1 "perl $Bin/Util/SplitBed.pl All.repeat.type.sort.bed\n";
    print S1 "perl $Bin/Util/CreatRepeatChart.pl $t > RepeatStatistic.txt\n";
    print S1 "perl $Bin/Util/RateRepeat.pl $g RepeatStatistic.txt | tee 0.step1.txt\n";
    close S1;
    print STDERR "====>\nplease run \`sh 0.step1.sh`\n====>\n";
}

if ($ARGV[0] eq "step2"){
    if(scalar @ARGV != 4){
        print STDERR "USAGE : perl $0 step2 \$threads \$genome_size \$repeat_size\n";
        exit;
    }
    my $t = $ARGV[1];
    my $g = $ARGV[2];
    my $r = $ARGV[3];
    open S2,'>',"0.step2.sh";
    print S2 "perl $Bin/Util/SplitGff3.pl ./\n";
    print S2 "perl $Bin/Util/ClassStatisticByContig.pl $t\n";
    print S2 "perl $Bin/Util/MergeClassRes.pl $g $r | tee 0.step2.txt\n";
    close S2;
    print STDERR "====>\nplease run \`sh 0.step2.sh`\n====>\n";
}
