use strict;
use warnings;

if (@ARGV < 1) {die "0_My_Extract_Transcriptome.pl .gtf\n";}

my %Ensg2Gtf = ();

open (my $gtf_out, ">","Transcripts_featureCounts.gtf") or die $!;
open (my $gtf, $ARGV[0]) or die $!;
my $gtf_line = "";
while ($gtf_line = <$gtf>) {
	if ($gtf_line =~ /^#/) {
		next;
	} # ignore headers
	my $geneid = "";
	if ($gtf_line =~ /gene_id "(.+?)";/) {
		$geneid = $1;
	} else {
		next;
	} # get gene id
	my @record = split(/\t/, $gtf_line);
	my $seq_chr = $record[0];
	my $seq_st = $record[3];
	my $seq_end = $record[4];
	if ($record[2] eq "exon") {
		$gtf_line =~ s/transcript_id "(.+?)"/transcript_id "$geneid"/;
		print $gtf_out $gtf_line;
	} else {
		$record[2] = "exon";
		my $lastele = scalar(@record)-1;
		$record[$lastele] = "gene_id \"$geneid\"; transcript_id \"$geneid\"; exon_number \"1\"; gene_name \"$geneid\"\n";
		print $gtf_out join("\t", @record);
	}
}
close($gtf);
close($gtf_out);
