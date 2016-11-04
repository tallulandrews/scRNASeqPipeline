use strict;
use warnings;

if (@ARGV < 2) {die "0_My_Extract_Transcriptome.pl .gtf .fa\n";}

my %Ensg2Seq = ();
my %Ensg2Gtf = ();
my @Ensgs = ();
my $flank = 10;

my $nascent = 1;

open (my $fa, $ARGV[1]) or die $!;
open (my $fa_out, ">","Transcripts.fa") or die $!;
open (my $gtf_out, ">","Transcripts.gtf") or die $!;
my $chr = "None";
my $chr_seq = "";
my $COUNT = 0;
while (<$fa>) {
	if($_ =~ /^#/) {next;} # skip headers
	if ($_ =~ /^\>/) {
		# New Chr
		my @line = split(/\s+/);
		my $newchr = $line[0]; $newchr =~ s/>//g;
		if ($chr eq "None") {
			$chr = $newchr;
			next;
		}  
		# Output gene sequences for this chromosome
		open (my $gtf, $ARGV[0]) or die $!;
		my $gtf_line = "";
		while ($gtf_line = <$gtf>) {
			# Extract sequence for each gene on this Chr.
			if ($gtf_line =~ /^#/) {next;} # ignore headers

			my $geneid = "";
			if ($gtf_line =~ /gene_id "(.+?)";/) {
				$geneid = $1;
			} else {
				next;
			} # get gene id

			# Get coordinates
			my @record = split(/\t/, $gtf_line);
			my $seq_chr = $record[0];
			if ($seq_chr ne $chr) {next;}
			my $seq_st = $record[3];
			my $seq_end = $record[4];
			if ($seq_chr ne $chr) {die "Something has gone terribly wrong $seq_chr $chr\n";}
			# Get sequence
			if ($record[2] eq "gene") {
				# Add null flanks as necessary
				if ($seq_st-$flank < 0) {
					$chr_seq = ('N' x $flank) . $chr_seq;
					$seq_st = $seq_st+$flank;
					$seq_end = $seq_end+$flank;
				}
				if ($seq_end+$flank > length($chr_seq)) {
					$chr_seq = $chr_seq . ('N' x $flank);
				}
				$Ensg2Seq{$geneid} = substr($chr_seq, $seq_st-$flank, ($seq_end-$seq_st+$flank));
				push(@Ensgs, $geneid);
			}
			# Store Annotations
			if ($record[2] eq "exon" || $record[2] eq "UTR" || $record[2] eq "gene") {
				push(@{$Ensg2Gtf{$geneid}}, $gtf_line);
			}
		}
		close($gtf);
		# Write output for all genes on this Chr
		foreach my $ensg (@Ensgs) {
			print $fa_out ">$ensg\n";
			print $fa_out $Ensg2Seq{$ensg}."\n";
			my $seq_length = length($Ensg2Seq{$ensg});
			my $shift = -1;
			foreach my $old_gtf (@{$Ensg2Gtf{$ensg}}) {
				$old_gtf =~ s/transcript_id "(.+?)"/transcript_id "$ensg"/s;
				$old_gtf =~ s/gene_id "(.+?)"/gene_id "$ensg"/s;
				$old_gtf =~ s/gene_name "(.+?)"/gene_name "$ensg"/s;

				my @record = split(/\t/, $old_gtf);
				if($shift == -1 && $record[2] ne "gene") {die "ERROR: Requires first entry for each ensg to be \"gene\".\n";}
				if ($shift == -1) {
					$shift = $record[3]-$flank;
				}
				if (scalar(@record) < 5) {die "$old_gtf not enough entries\n";}

				$record[0] = $ensg;
				$record[3] = $record[3]-$shift;
				$record[4] = $record[4]-$shift;
				if ($record[4] > $seq_length) {
					print STDERR "$chr $ensg $record[2] $record[3] $record[4], seq = $seq_length\n";
					die "ERROR: annotation exceeds sequence length\n";
				}
				print $gtf_out join("\t",@record);
			}
		}
		print "$chr $newchr\n";
		$chr = $newchr;
		$chr_seq="";
		$COUNT=0;
		@Ensgs=();
	} else {
		# Read in chr sequence
		chomp;
		$chr_seq = $chr_seq.$_;
	}
}
# Output last chromosome
# Output gene sequences 
{
			# Output gene sequences for this chromosome
			open (my $gtf, $ARGV[0]) or die $!;
			my $gtf_line = "";
			while ($gtf_line = <$gtf>) {
				# Extract sequence for each gene on this Chr.
				if ($gtf_line =~ /^#/) {next;} # ignore headers

				my $geneid = "";
				if ($gtf_line =~ /gene_id "(.+?)";/) {
					$geneid = $1;
				} else {
					next;
				} # get gene id

				# Get coordinates
				my @record = split(/\t/, $gtf_line);
				my $seq_chr = $record[0];
				if ($seq_chr ne $chr) {next;}
				my $seq_st = $record[3];
				my $seq_end = $record[4];
				if ($seq_chr ne $chr) {die "Something has gone terribly wrong $seq_chr $chr\n";}
				# Get sequence
				if ($record[2] eq "gene") {
					# Add null flanks as necessary
					if ($seq_st-$flank < 0) {
						$chr_seq = ('N' x $flank) . $chr_seq;
						$seq_st = $seq_st+$flank;
						$seq_end = $seq_end+$flank;
					}
					if ($seq_end+$flank > length($chr_seq)) {
						$chr_seq = $chr_seq . ('N' x $flank);
					}
					$Ensg2Seq{$geneid} = substr($chr_seq, $seq_st-$flank, ($seq_end-$seq_st+$flank));
					push(@Ensgs, $geneid);
				}
				# Store Annotations
				if ($record[2] eq "exon" || $record[2] eq "UTR" || $record[2] eq "gene") {
					push(@{$Ensg2Gtf{$geneid}}, $gtf_line);
				}
			}
			close($gtf);
			# Write output for all genes on this Chr
			foreach my $ensg (@Ensgs) {
				print $fa_out ">$ensg\n";
				print $fa_out $Ensg2Seq{$ensg}."\n";
				my $seq_length = length($Ensg2Seq{$ensg});
				my $shift = -1;
				foreach my $old_gtf (@{$Ensg2Gtf{$ensg}}) {
					$old_gtf =~ s/transcript_id "(.+?)"/transcript_id "$ensg"/s;
					$old_gtf =~ s/gene_id "(.+?)"/gene_id "$ensg"/s;
					$old_gtf =~ s/gene_name "(.+?)"/gene_name "$ensg"/s;

					my @record = split(/\t/, $old_gtf);
					if($shift == -1 && $record[2] ne "gene") {die "ERROR: Requires first entry for each ensg to be \"gene\".\n";}
					if ($shift == -1) {
						$shift = $record[3]-$flank;
					}

					$record[0] = $ensg;
					$record[3] = $record[3]-$shift;
					$record[4] = $record[4]-$shift;
					if ($record[4] > $seq_length) {die "ERROR: annotation exceeds sequence length\n";}
					print $gtf_out join("\t",@record);
				}
			}
			exit();
			$chr_seq="";
			$COUNT=0;
			@Ensgs=();
		}
close($gtf_out);
close($fa);
