use strict;
use warnings;

#Things to filter: 
#	single exon non-reference transcripts (class 'u' 'i'  & single exon), 
#	transcripts with retained introns (class 'e'), 
#	polymerase read-though (class 'p'), 
#	class code 's' (likely read mapping error)
# helpful info: http://seqanswers.com/forums/showthread.php?t=3518
# Stats I would like to have: (1) % reference transcripts recovered (# transcripts class '=' vs # transcripts genome, (2) # novel intergenic multi-exonic transcripts, (3) # novel alternatively spliced transcripts

if (@ARGV < 1) {die "Please provide reference GTF\n";}

my %transcriptid2lines =();
my %transcriptid2numexons = ();
open (my $ifh, $ARGV[0]) or die $!;
while (<$ifh>) {
	chomp;
	$_ =~ /transcript_id "(.+?)";/;
	my $tid = $1;
	if ($_ =~ /exon_number "(\d+)"/) {
		if (!exists($transcriptid2numexons{$tid}) || $transcriptid2numexons{$tid} < $1) {
			$transcriptid2numexons{$tid} = $1;
		}
	}
} close($ifh);

print "Number of Transcripts: ".scalar(keys(%transcriptid2numexons))."\n";
