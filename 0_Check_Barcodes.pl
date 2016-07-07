use strict;
use warnings;

if (@ARGV < 3) { die "Breakdown_Paired_Ends.pl INPUT1 INPUT2 ProjectName\n";}
my $infile1 = $ARGV[0];
my $infile2 = $ARGV[1];

my %Barcodes = ();
open (my $ifh1, $infile1) or die $!;
while(<$ifh1>) {
	my $file1line = $_;
	if ($file1line =~ /^@/) {
		my @thing1 = split(/\s+/,$file1line);
		my $readname = $thing1[0];
		my $barcodes = <$ifh1>;
		if ($barcodes =~ /^([ATCGNUKMRYSWBVHDX]{11})([ATCGNUKMRYSWBVHDX]{10})/){
			my $UMI = $2;
			my $CellID = $1;
			$Barcodes{$UMI}++;
		}
	} else {next;}
}
close($ifh1);

my @codes = sort{$Barcodes{$a}<=>$Barcodes{$b}} keys(%Barcodes);
foreach my $code (@codes) {
	print "$code ".$Barcodes{$code}."\n";
}
