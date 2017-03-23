use strict;
use warnings;

if (@ARGV < 1) {die "Required input: gtf file\n";}

my %GeneID2Stuff = ();
my %TranscriptID2GeneID = ();
open (my $ifh, $ARGV[0]) or die $!;
while (<$ifh>) {
	if ($_ =~ /^#/) {next;}
	my $geneid = "ERROR";
	if ($_ =~ /gene_id "(.+?)"/) {
		$geneid=$1;
	} else {
		die "No gene id!\n";
	}
	
	if ($_ =~ /transcript_id "(.+?)"/) {
		$GeneID2Stuff{$geneid}->{"transcript_ids"}->{$1} = 1;
		$TranscriptID2GeneID{$1}=$geneid;
	}
	if ($_ =~ /gene_name "(.+?)"/) {
		$GeneID2Stuff{$geneid}->{"gene_name"} = $1;
	}
	if ($_ =~ /gene_biotype "(.+?)"/) {
		$GeneID2Stuff{$geneid}->{"gene_biotype"} = $1;
	}
	my @record = split(/\t/);
	my $length = $record[4]-$record[3];
	if (!exists($GeneID2Stuff{$geneid}->{"length"}) || $GeneID2Stuff{$geneid}->{"length"} < $length) {
		$GeneID2Stuff{$geneid}->{"length"} = $length;
	}
} close ($ifh);
	
foreach my $gene (sort(keys(%GeneID2Stuff))) {
	print $gene."\t".$GeneID2Stuff{$gene}->{"gene_biotype"}."\n";
}
	
