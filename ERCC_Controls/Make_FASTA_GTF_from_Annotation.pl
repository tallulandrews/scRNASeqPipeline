use strict;
use warnings;
# Converts the Annotation file from 

my @FASTAlines = ();
my @GTFlines = ();
open (my $ifh, "ERCC_Controls_Annotation.txt") or die $!;
<$ifh>; #header
while (<$ifh>) {
	# Do all the important stuff
	chomp;
	my @record = split(/\t/);
	my $sequence = $record[4];
	$sequence = $sequence."NNNN";
	my $name = $record[0];
	my $genbank = $record[1];
	push(@FASTAlines, ">$name\n$sequence\n");
# is GTF 1 indexed or 0 indexed? -> it is 1 indexed
# + or - strand?
	push(@GTFlines, "$name\tERCC\tgene\t1\t".length($sequence)-2."\t.\t+\t.\tgene_id \"$name-$genbank\"; transcript_id \"$name-$genbank\"; exon_number \"1\"; gene_name \"ERCC $name-$genbank\"\n");
	push(@GTFlines, "$name\tERCC\texon\t1\t".length($sequence)-2."\t.\t+\t.\tgene_id \"$name-$genbank\"; transcript_id \"$name-$genbank\"; exon_number \"1\"; gene_name \"ERCC $name-$genbank\"\n");
} close($ifh);

# Write output
open(my $ofh, ">", "ERCC_Controls.fa") or die $!;
foreach my $line (@FASTAlines) {
	print $ofh $line;
} close ($ofh);

open($ofh, ">", "ERCC_Controls.gtf") or die $!;
foreach my $line (@GTFlines) {
	print $ofh $line;
} close ($ofh);
