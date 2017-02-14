use strict;
use warnings;

if (@ARGV < 2) {die "Required Argument: Barcode counting output, expected number of cells\n";}

my $ExpectNCells = $ARGV[1]; # This is just used as a guide does not have to be exact.
my $trunc = 1; #Only output the identified cell IDs.

open(my $ifh, $ARGV[0]) or die $!; # list of the form: barcode frequencey; in decending order of frequency.
my %Barcodes = ();

my $count = 0;
while(<$ifh>) {
	chomp;
	my @record = split(/\s+/);
	my $barcode = $record[0];
	my $counts = $record[1];
	my @seencodes = keys(%Barcodes);
	$Barcodes{$barcode} = $counts;
	foreach my $key (@seencodes) {
		my $count = ( $barcode ^ $key ) =~ tr/\0//;
		my $mismatches = length($barcode)-$count;
		if ($mismatches <= 1) {
			$Barcodes{$barcode} = $Barcodes{$key}+$Barcodes{$barcode};
			delete($Barcodes{$key});
		}
	}
	$count++;
	if ($count > 10000) {print STDERR scalar(@seencodes)."\n"; $count=0;}
}

my @codes = sort{$Barcodes{$a}<=>$Barcodes{$b}} keys(%Barcodes);
my $quantile = $ExpectNCells*0.75;
my $quantile_freq = $Barcodes{$codes[$quantile]};
my $threshold = $quantile_freq - ($Barcodes{$codes[0]}-$quantile_freq);

my $count = 0;
foreach my $code (@codes) {
	if ($Barcodes{$code} < $threshold) {
		print STDERR "$count cell barcodes found.\n"
		if ($tunct) {last;}
	}
	print "$code ".$Barcodes{$code}."\n";
	$count++;
}
