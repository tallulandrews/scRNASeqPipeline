use strict;
use warnings;
# Currently replaces all estimated FPKMs which are not significantly bigger than 0 with 0. -> not as of (Feb 9 2016), also changed "not detected" genes from NA to 0.

if (@ARGV < 2) {die "Please supply a directory of Kallisto Output and a prefix for output\n";}

my $dir = $ARGV[0];
my $outprefix = $ARGV[1];

# Now read in genome annotations
my %transcript2gene = ();
open (my $ifh, "/lustre/scratch108/compgen/team218/TA/genomebuilding/Mus_musculus.GRCm38.79.gtf") or die $!;
while (<$ifh>) {
	if ($_ =~ /^#/) {next;}
	
	if ($_ =~ /transcript_id "(.+?)"/) {
		my $transid = $1;
		#transcript
		my $geneid = "ERROR";
		if ($_ =~ /gene_id "(.+?)"/) {
			$geneid=$1;
		} else {
			die "No gene id!\n";
		}
		$transcript2gene{$transid}=$geneid;
	}
	
} close ($ifh);
print STDERR "Done reading Annotations\n";

# First get expression for all genes & store details for all Cuff-Genes
my %AllGenes = (); my %AllSamples = ();
my %Gene2Sample2TPM = ();
my %Gene2Sample2Counts=();

my @files = glob("$dir/*.abundances.tsv");	
foreach my $file (@files) {
#	$file =~ /([ATCG]{5,})/;
	my $ID = "ERR";
	if ($file =~ /([^_]+_Cell\d\d)/) {
		$ID = $1;
	} else {
		die "$file does not match!";
	}
	$AllSamples{$ID}=1;
	open(my $ifh, $file) or die $!;
	<$ifh>; # header
	while (<$ifh>) {
		chomp;
		my @record = split(/\t/);
		my $trans = $record[0];
		my $count = $record[3];
		my $tpm = $record[4];
		my $gene = $trans;
		if (exists($transcript2gene{$trans})) {
			$gene = $transcript2gene{$trans};
		}
		if (exists($Gene2Sample2TPM{$gene})) {
			$Gene2Sample2TPM{$gene}->{$ID}+=$tpm;
			$Gene2Sample2Counts{$gene}->{$ID}+=$count;
		} else {
			$Gene2Sample2TPM{$gene}->{$ID}=$tpm;
			$Gene2Sample2Counts{$gene}->{$ID}=$count;
		}
	} close ($ifh);
} 

open (my $ofhtpm, ">", "$outprefix.tpm") or die $!;
open (my $ofhcounts, ">", "$outprefix.counts") or die $!;
my @IDs = sort(keys(%AllSamples));
print $ofhtpm "Gene\t".join("\t",@IDs)."\n";
print $ofhcounts "Gene\t".join("\t",@IDs)."\n";

foreach my $gene (keys(%Gene2Sample2TPM)) {
	print $ofhtpm "$gene";
	print $ofhcounts "$gene";
	foreach my $ID (@IDs) {
                 my $tpm = "NA";
                 if (exists($Gene2Sample2TPM{$gene}->{$ID})) {
                         $tpm = $Gene2Sample2TPM{$gene}->{$ID};
                 } else {
                         $tpm = "0";
                 }
                 my $count = "NA";
                 if (exists($Gene2Sample2Counts{$gene}->{$ID})) {
                         $count = $Gene2Sample2Counts{$gene}->{$ID};
                 } else {
                         $count = "0";
                 }
                 print $ofhcounts "\t".$count;
                 print $ofhtpm "\t".$tpm;
         }
         print $ofhcounts "\n";
         print $ofhtpm "\n";
}
close($ofhcounts);
close($ofhtpm);
