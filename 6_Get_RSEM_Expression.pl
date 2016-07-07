use strict;
use warnings;

if (@ARGV < 2) {die "Please supply a directory of Cufflinks Output and a prefix for outputfiles\n";}

my $dir = $ARGV[0];
my $outprefix = $ARGV[1];

# First get expression for all genes & store details for all Cuff-Genes
my %AllGenes = (); my %AllSamples = ();
my %Gene2Sample2FPKM = ();
my %Gene2Sample2TPM = ();

my @files = glob("$dir/*.genes.results");	
foreach my $file (@files) {
#	$file =~ /([ATCG]{5,})/;
	my $ID = "ERR";
#	if ($file =~ /([^_]+_Cell\d\d)/) {
	if ($file =~ /RSEM-(\d+)-/) {
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
		my $gene = $record[0];
		my $fpkm = $record[6];
		my $tpm = $record[5];
		$Gene2Sample2FPKM{$gene}->{$ID}=$fpkm;
		$Gene2Sample2TPM{$gene}->{$ID} =$tpm;
	} close ($ifh);
} 

print STDERR "Done reading FPKMs\n";

open (my $ofhfpkm, ">", "$outprefix.fpkm") or die $!;
open (my $ofhtpm, ">", "$outprefix.tpm") or die $!;
my @IDs = sort{$a<=>$b} keys(%AllSamples);
print $ofhfpkm "Gene\t".join("\t",@IDs)."\n";
print $ofhtpm "Gene\t".join("\t",@IDs)."\n";

foreach my $gene (keys(%Gene2Sample2FPKM)) {
	print $ofhfpkm "$gene";
	print $ofhtpm "$gene";
	foreach my $ID (@IDs) {
                 my $tpm = "NA";
                 my $fpkm = "NA";
                 if (exists($Gene2Sample2FPKM{$gene}->{$ID})) {
                         $fpkm = $Gene2Sample2FPKM{$gene}->{$ID};
                 } else {
                         $fpkm = "0";
                 }
                 if (exists($Gene2Sample2TPM{$gene}->{$ID})) {
                         $tpm = $Gene2Sample2TPM{$gene}->{$ID};
                 } else {
                         $tpm = "0";
                 }
                 print $ofhfpkm "\t".$fpkm;
                 print $ofhtpm "\t".$tpm;
         }
         print $ofhfpkm "\n";
         print $ofhtpm "\n";
}
close($ofhtpm);
close($ofhfpkm);
