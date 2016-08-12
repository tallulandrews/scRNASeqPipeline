use strict;
use warnings;

if (@ARGV < 3) {die "0_My_Extract_Transcriptome.pl .gtf .fa Nascent?[0|1]\n";}
# To Do:
# get all exons per transcript
# sort by start
# if overlap (start2 < end1) then merge
# else switch to new exon
sub merge_transcripts { # Tested
	my @exons = sort{$a->{"st"} <=> $b->{"st"}} @_;
	my %curr = %{shift(@exons)};
	my @finalexons = ();
	foreach my $exon2 (@exons) {
		if ($curr{"end"} > $exon2->{"st"}) {
			# overlap == merge
			if ($exon2->{"end"} > $curr{"end"}) {
				$curr{"end"} = $exon2->{"end"};
			}
		} else {
			my $tmp1 = $curr{"st"};
			my $tmp2 = $curr{"end"};
#			print "save $tmp1 $tmp2\n";
			push(@finalexons, {"st"=>$tmp1,"end"=>$tmp2});
			%curr = %{$exon2};
		}
	}
	my $tmp1 = $curr{"st"};
	my $tmp2 = $curr{"end"};
#	print "save $tmp1 $tmp2\n";
	push(@finalexons, {"st"=>$tmp1,"end"=>$tmp2});
	return(@finalexons);
}


my %Ensg2Seq = ();
my %Ensg2Tail = ();
my %Ensg2Gtf = ();
my @Ensgs = ();
my $flank = 10;

my $nascent = $ARGV[2];

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
		my %exons = ();
		while ($gtf_line = <$gtf>) {
			if ($gtf_line =~ /^#/) {next;} # ignore headers
			my $geneid = "";
			if ($gtf_line =~ /gene_id "(.+?)";/) {
				$geneid = $1;
			} else {
				next;
			} # get gene id
			my @record = split(/\t/, $gtf_line);
			my $seq_chr = $record[0];
			if ($seq_chr ne $chr) {next;}
			my $seq_st = $record[3]-$flank;
			my $seq_end = $record[4]+$flank;
			my %item; $item{"st"} = $seq_st; $item{"end"} = $seq_end; 
			if ($seq_chr ne $chr) {die "Something has gone terribly wrong $seq_chr $chr\n";}
			if (!$nascent) {
				if ($record[2] eq "exon" || $record[2] eq "UTR") {
					push(@{$exons{$geneid}}, \%item);
#					if (exists($Ensg2Seq{$geneid})) {
#						$Ensg2Seq{$geneid}.= substr($chr_seq, $seq_st-$flank, ($seq_end-$seq_st+$flank));
#					} else {
#						$Ensg2Seq{$geneid} = substr($chr_seq, $seq_st-$flank, ($seq_end-$seq_st+$flank));
#					}
				}
			} else {
				if ($record[2] eq "gene") {
					push(@{$exons{$geneid}}, \%item);
#					$Ensg2Seq{$geneid} = substr($chr_seq, $seq_st-$flank, ($seq_end-$seq_st+$flank));
				}
			}
			if ($record[2] eq "gene") {
				push(@Ensgs, $geneid);
				$Ensg2Gtf{$geneid} = $gtf_line;
				$COUNT++;
			}
		}
		close($gtf);
		foreach my $ensg (@Ensgs) {
			# Get sequence
			my @parts = @{$exons{$ensg}};
			my @merged = merge_transcripts(@parts);
			my $gene_seq = "";
			foreach my $item (@merged) {
				my $seq_st  = $item->{"st"};
				my $seq_end = $item->{"end"};
#print "$seq_st $seq_end aquired\n";
				$gene_seq .= substr($chr_seq, $seq_st, ($seq_end-$seq_st));
			}
			
			print $fa_out ">$ensg\n";
			print $fa_out $gene_seq."\n";
			my $seq_length = length($gene_seq);
#			print $fa_out $Ensg2Seq{$ensg}."\n";
#			my $seq_length = length($Ensg2Seq{$ensg});
			my $old_gtf = $Ensg2Gtf{$ensg};
			$old_gtf =~ s/transcript_id "(.+?)"/transcript_id "$ensg"/;
			my @record = split(/\t/, $old_gtf);
			$record[0] = $ensg;
			$record[3] = 1;
			$record[4] = $seq_length-1;
			print $gtf_out join("\t",@record);
			my $lastele = scalar(@record)-1;
			$record[$lastele] = "gene_id \"$ensg\"; transcript_id \"$ensg\"; exon_number \"1\"; gene_name \"$ensg\"\n";
			$record[2] = "exon";
			print $gtf_out join("\t",@record);
		}
		print "$chr $newchr\n";
		%exons = ();
		$chr = $newchr;
		$chr_seq="";
		$COUNT=0;
		@Ensgs=();
	} else {
		chomp;
		$chr_seq = $chr_seq.$_;
	}
}
# Output last chromosome
# Output gene sequences 
open (my $gtf, $ARGV[0]) or die $!;
my $gtf_line = "";
while ($gtf_line = <$gtf>) {
	if ($gtf_line =~ /^#/) {next;} # ignore headers

	my $geneid = "";
	if ($gtf_line =~ /gene_id "(.+?)";/) {
		$geneid = $1;
	} else {
		next;
	} # get gene id

	my @record = split(/\t/, $gtf_line);
	my $seq_chr = $record[0];
	if ($seq_chr ne $chr) {next;}
	my $seq_st = $record[3];
	my $seq_end = $record[4];
	if ($seq_chr ne $chr) {die "Something has gone terribly wrong $seq_chr $chr\n";}
	if (!$nascent) {
		if ($record[2] eq "exon" || $record[2] eq "UTR") {
			if (exists($Ensg2Seq{$geneid})) {
				$Ensg2Seq{$geneid}.= substr($chr_seq, $seq_st-10, ($seq_end-$seq_st+10));
			} else {
				$Ensg2Seq{$geneid} = substr($chr_seq, $seq_st-10, ($seq_end-$seq_st+10));
			}
		}
	} else {
		if ($record[2] eq "gene") {
			$Ensg2Seq{$geneid} = substr($chr_seq, $seq_st-10, ($seq_end-$seq_st+10));
		}
	}
	if ($record[2] eq "gene") {
		push(@Ensgs, $geneid);
		$Ensg2Gtf{$geneid} = $gtf_line;
		$COUNT++;
		if ($record[6] eq "+") {
			$Ensg2Tail{$geneid}->{"+"} = substr($chr_seq,$seq_end,$flank);
		} else {
			$Ensg2Tail{$geneid}->{"-"} = substr($chr_seq,$seq_st-$flank,$flank);
		}
	}
}
close($gtf);
foreach my $ensg (@Ensgs) {
	print $fa_out ">$ensg\n";
	print $fa_out $Ensg2Seq{$ensg}."\n";
	my $seq_length = length($Ensg2Seq{$ensg});
	my $old_gtf = $Ensg2Gtf{$ensg};
	$old_gtf =~ s/transcript_id "(.+?)"/transcript_id "$ensg"/;
	my @record = split(/\t/, $old_gtf);
	$record[0] = $ensg;
	$record[3] = 1;
	$record[4] = $seq_length-1;
	print $gtf_out join("\t",@record);

	my $lastele = scalar(@record)-1;
	$record[$lastele] = "gene_id \"$ensg\"; transcript_id \"$ensg\"; exon_number \"1\"; gene_name \"$ensg\"\n";
	$record[2] = "exon";
	print $gtf_out join("\t",@record);
}

close($fa_out);
close($gtf_out);
close($fa);
