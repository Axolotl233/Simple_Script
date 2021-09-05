#!/usr/bin/perl
use strict;
use warnings;

my $clustalw="clustalw2";
my $in=shift or die "Usage: ConvertTypeByClustalw.pl <infile> <outfile> <CLUSTAL|GCG|GDE|PHYLIP|PIR|NEXUS|FASTA>\n";
my $out=shift or die "Usage: ConvertTypeByClustalw.pl <infile> <outfile> <CLUSTAL|GCG|GDE|PHYLIP|PIR|NEXUS|FASTA>\n";
my $type=shift or die "Usage: ConvertTypeByClustalw.pl <infile> <outfile> <CLUSTAL|GCG|GDE|PHYLIP|PIR|NEXUS|FASTA>\n";

print "$clustalw -INFILE=$in -CONVERT -TYPE=DNA -OUTFILE=$out -OUTPUT=$type\n";
