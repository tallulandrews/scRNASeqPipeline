use strict;
use warnings;

if (@ARGV < 1) {die "Please supply a directory of RSEM Output\n";}

my $dir = $ARGV[0];

# First get expression for all genes
my %AllGenes = (); my %AllSamples = ();
my %Gene2Sample2FPKM = ();
my %Gene2Sample2TPM = ();

my @files = glob("$dir/bowtie2*.genes.results");	
foreach my $file (@files) {
	my $ID = "ERR";
	if ($file =~ /bowtie2_RSEM-(\d+)/) { # Match file name.
		$ID = $1;
	} else {
		next;
	}
	$AllSamples{$ID}=1;
} 

my @IDs = sort{$a<=>$b} keys(%AllSamples);
print ( join("\n", @IDs) );
