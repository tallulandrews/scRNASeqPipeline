use strict;
use warnings;

#Things to filter: 
#	single exon non-reference transcripts (class 'u' 'i'  & single exon), 
#	transcripts with retained introns (class 'e'), 
#	polymerase read-though (class 'p'), 
#	class code 's' (likely read mapping error)
# helpful info: http://seqanswers.com/forums/showthread.php?t=3518
# Stats I would like to have: (1) % reference transcripts recovered (# transcripts class '=' vs # transcripts genome, (2) # novel intergenic multi-exonic transcripts, (3) # novel alternatively spliced transcripts

if (@ARGV < 1) {die "Please provide cuffmerge outputfile\n";}

my %code2count = ();
my %transcriptid2lines =();
my %transcriptid2code=();
my %transcriptid2numexons = ();
open (my $ifh, $ARGV[0]) or die $!;
while (<$ifh>) {
	chomp;
	$_ =~ /transcript_id "(.+)"; exon_number/;
	my $tid = $1;
	push(@{$transcriptid2lines{$tid}},$_);
	$_ =~ /class_code "(.+)"; tss_id/;
	my $code = $1;
	if (exists($transcriptid2code{$tid}) && $transcriptid2code{$tid} ne $code) {die "Contradicting codes\n";}
	$transcriptid2code{$tid}=$code;
	$code2count{$code}++;
	if ($_ =~ /exon_number "(\d+)"/) {
		if (!exists($transcriptid2numexons{$tid}) || $transcriptid2numexons{$tid} < $1) {
			$transcriptid2numexons{$tid} = $1;
		}
	} else { die "exon_num not match\n";}
} close($ifh);


my $Nrecovered = 0;
my $Nremoved = 0;
%code2count=();
open(my $ofh, ">", "New_Transcriptome.gtf") or die $!;
foreach my $tid (keys(%transcriptid2lines)) {
	$Nremoved++;
	my $code = $transcriptid2code{$tid};
	my $exons = $transcriptid2numexons{$tid};
	$code2count{$code}++;
	if ($exons == 1 && ($code eq "u" || $code eq "i")) {next;}
	if ($code eq "e" || $code eq "p" || $code eq "s" || $code eq "r") {next;}
	if ($code eq "=") {$Nrecovered++;}
	$Nremoved--;

	foreach my $line (@{$transcriptid2lines{$tid}}) {
		print $ofh $line."\n";
	}
}
foreach my $code (keys(%code2count)) {
	print "$code : $code2count{$code}\n";
}
print "transcripts recovered: $Nrecovered\n";
print "transcripts removed: $Nremoved\n";
