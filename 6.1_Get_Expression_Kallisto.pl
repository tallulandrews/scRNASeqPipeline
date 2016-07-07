use strict;
use warnings;

if (@ARGV != 1) {die "Please provide a /path/prefix for output.\n";}

my $outprefix = $ARGV[0];

my %Gene2ID2FragCount = ();
my %Gene2ID2TPM = ();
my @IDs = ();

my %transcript2gene = ();
open (my $ifh, "/lustre/scratch108/compgen/team218/TA/genomebuilding/Mus_musculus.GRCm38.79.gtf") or die $!;
while (<$ifh>) {
	if ($_ =~ /^#/) {next;}
	my $geneid = "ERROR";
	if ($_ =~ /gene_id "(.+?)"/) {
		$geneid=$1;
	} else {
		die "No gene id!\n";
	}
	
	my @record = split(/\t/);
	if ($record[2] =~ /gene/i) {
		#gene
	} elsif ($_ =~ /exon_id "(.+?)"/) {
		#exon
	} elsif ($_ =~ /transcript_id "(.+?)"/) {
		#transcript
		$transcript2gene{$1}=$geneid;
	}
} close ($ifh);
print STDERR "Done reading Annotations\n";

foreach my $file (glob("/lustre/scratch108/compgen/team218/TA/RNASeqFilesQuantified/Buettner_Kallisto/*.abundance*.tsv")) {
#	$file =~ /([ATCG]{5,})/;
	my $ID = "ERROR";
	if ($file =~ /([^\/]+_Cell\d\d)/) {
		$ID = $1;
	} else {die "$file did not match!\n";}
	push(@IDs,$ID);
	open(my $ifh, $file) or die $!;
	while (<$ifh>) {
		chomp;
		if ($_ =~ /^#/ || $_ =~ /^target_id/) {next;} #skip header & comments
		my @record=split(/\t/);
		my $gene = $record[0]; $gene =~ s/\s+//g;
#		if (exists($transcript2gene{$gene})) {
#			$gene = $transcript2gene{$gene};
#		}
		if (exists($Gene2ID2FragCount{$gene}->{$ID})) {
			$Gene2ID2FragCount{$gene}->{$ID} += $record[3]; 
			$Gene2ID2TPM{$gene}->{$ID} += $record[4]; 
		} else {
			$Gene2ID2FragCount{$gene}->{$ID} = $record[3]; 
			$Gene2ID2TPM{$gene}->{$ID} = $record[4]; 
		}
	} close ($ifh);
}



open(my $ofh1, ">", "$outprefix\_kallisto_counts.txt") or die $!;
open(my $ofh2, ">", "$outprefix\_kallisto_tpm.txt") or die $!;
print $ofh1 "Gene\t".join("\t",@IDs)."\n";
print $ofh2 "Gene\t".join("\t",@IDs)."\n";
foreach my $gene (keys(%Gene2ID2FragCount)) {
	print $ofh1 "$gene";
	print $ofh2 "$gene";
	foreach my $ID (@IDs) {
		my $count = "NA";
		my $tpm = "NA";
		if (exists($Gene2ID2FragCount{$gene}->{$ID})) {
			$count = $Gene2ID2FragCount{$gene}->{$ID};
		} else { 
			$count = "NA";
		}
		if (exists($Gene2ID2TPM{$gene}->{$ID})) {
			$tpm = $Gene2ID2TPM{$gene}->{$ID};
		} else { 
			$tpm = "NA";
		}
		print $ofh1 "\t".$count;
		print $ofh2 "\t".$tpm;
	}
	print $ofh1 "\n";
	print $ofh2 "\n";
}
