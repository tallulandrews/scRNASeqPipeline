use strict;
use warnings;
# Currently replaces all estimated FPKMs which are not significantly bigger than 0 with 0. -> not as of (Feb 9 2016), also changed "not detected" genes from NA to 0.

if (@ARGV < 2) {die "Usage: 6_Get_Salmon_Expression.pl [directory of Salmon output] [gene|transcript] [output prefix]\n";}

my $dir = $ARGV[0];
my $feature = $ARGV[1];
my $outprefix = $ARGV[2];

# Process arguments
my @files = ();
if ($feature =~ /gene/i) {
	@files = glob("$dir/*.quant.genes.sf");
} else {
	@files = glob("$dir/*.quant.sf");
}
# More efficient to do both at once
#my $col = -1;
#if ($type =~ /tpm/i) {
#	# column of salmon output corresponding to tpm
#	$col = 3;
#} else {
#	# column of salmon output corresponding to read counts
#	$col = 4;
#}


# First get expression for all genes & store details for all Cuff-Genes
my %AllGenes = (); my %AllSamples = ();
my %Gene2Sample2TPM = ();
my %Gene2Sample2Counts=();

foreach my $file (@files) {
#	$file =~ /([ATCG]{5,})/;
	# Regular expressions to extract sample name from file name
	my $ID = "ERR";
	if ($file =~ /([^_]+_Cell\d\d)/) {
		$ID = $1;
	} else {
		die "$file does not match!";
	}
	#####
	$AllSamples{$ID}=1;
	open(my $ifh, $file) or die $!;
	<$ifh>; # header
	while (<$ifh>) {
		chomp;
		my @record = split(/\t/);
		my $feature = $record[0];
		my $count = $record[4];
		my $tpm = $record[3];
		if (exists($Gene2Sample2TPM{$feature})) {
			$Gene2Sample2TPM{$feature}->{$ID}+=$tpm;
			$Gene2Sample2Counts{$feature}->{$ID}+=$count;
		} else {
			$Gene2Sample2TPM{$feature}->{$ID}=$tpm;
			$Gene2Sample2Counts{$feature}->{$ID}=$count;
		}
	} close ($ifh);
} 

open (my $ofhtpm, ">", "$outprefix.tpm") or die $!;
open (my $ofhcounts, ">", "$outprefix.counts") or die $!;
my @IDs = sort(keys(%AllSamples));
print $ofhtpm "Gene\t".join("\t",@IDs)."\n";
print $ofhcounts "Gene\t".join("\t",@IDs)."\n";

foreach my $gene (sort(keys(%Gene2Sample2TPM))) {
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
