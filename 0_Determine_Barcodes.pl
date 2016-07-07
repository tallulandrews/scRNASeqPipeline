use strict;
use warnings;

if (@ARGV < 1) {die "Required Argument: output from Check_Barcodes.pl\n";}

open(my $ifh, $ARGV[0]) or die $!;
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
foreach my $code (@codes) {
	print "$code ".$Barcodes{$code}."\n";
}

	
