use strict;
use warnings;

# Now read in genome annotations
my %chr2exon2locus = ();
my %exon2gene = ();
my %exon2transcript = ();
my %exon2size = ();
my %chr2gene2locus = ();
my %transcript2gene = ();
my %gene2trans = ();
my %trans2exon = ();
my %gene2exon = ();
my %Addedchr = ();
open (my $ifh, "/lustre/scratch108/compgen/team218/TA/genomebuilding/Mus_musculus.GRCm38.79.gtf") or die $!;
while (<$ifh>) {
	my $transcriptID = "ERROR";
	if ($_ =~ /^#/) {next;}
	my $geneid = "ERROR";
	if ($_ =~ /gene_id "(.+?)"/) {
		$geneid=$1;
	} else {
		die "No gene id!\n";
	}
	if ($_ =~ /transcript_id "(.+?)"/) {
		#transcript
		$transcriptID = $1;
		$transcript2gene{$transcriptID}=$geneid;
		$gene2trans{$geneid}->{$transcriptID} = 1;
	}
	
	my @record = split(/\t/);
	my $size = $record[4] - $record[3];
	if ($size < 0) {
		$size = $record[3] - $record[4];
	}

	if ($record[2] =~ /gene/i) {
		#gene
		#$chr2gene2locus{$locus->[0]}->{$geneid} = $locus;
	} elsif ($_ =~ /exon_id "(.+?)"/) {
		#exon
#		$chr2exon2locus{$locus->[0]}->{$1} = $locus;
		my $exonID = "$geneid $record[3] $record[4]";
		$exon2gene{$exonID}=$geneid;
		$exon2size{$exonID} = $size;
		$exon2transcript{$exonID}->{$transcriptID} = 1;
		$trans2exon{$transcriptID}->{$exonID} = 1;
		$gene2exon{$geneid}->{$exonID} = 1;
	}
	
} close ($ifh);

foreach my $g (keys(%gene2trans)) {
	my $total_trans = scalar(keys(%{$gene2trans{$g}}));
	my $Perc_diff = 0;
	if ($total_trans > 1) {
		my $total_size = 0;
		my $var_size = 0;
		foreach my $e (keys(%{$gene2exon{$g}})) {
			$total_size += $exon2size{$e};
			if (scalar(keys(%{$exon2transcript{$e}})) > 1) {
				$var_size += $exon2size{$e};
			}
		}
		$Perc_diff = $var_size/$total_size;
	}
	print "$g $total_trans $Perc_diff\n";
}
