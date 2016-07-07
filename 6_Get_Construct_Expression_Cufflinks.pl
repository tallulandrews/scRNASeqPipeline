use strict;
use warnings;

my %ID2Things = ();
my %ID2Thingsloci = ();

my $fpkmcol = 9;

foreach my $file (glob("/lustre/scratch108/compgen/team218/TA/RNASeqFilesQuantified/*genes.fpkm_tracking")) {
	$file =~ /([ATCG]{5,})/;
	my $ID = $1;
	open(my $ifh, $file) or die $!;
	while (<$ifh>) {
		chomp;
		if ($_ =~ /A2lox-TRE/) {
			my @record=split(/\t/);
			$ID2Things{$ID}->{$record[0]} = $record[$fpkmcol]; 
			my $locus = $record[6];
			$locus =~ /(\d+)-(\d+)/;
			$ID2Thingsloci{$ID}->{$record[0]} = "$1\t$2"; 
		}
	} close ($ifh);
}


foreach my $id (keys(%ID2Things)) {
	foreach my $thing (keys(%{$ID2Things{$id}})) {
		print "$id\t$thing\t".$ID2Things{$id}->{$thing}."\t".$ID2Thingsloci{$id}->{$thing}."\n";
	}
}

		
