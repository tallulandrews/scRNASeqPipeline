use strict;
use warnings;

if (@ARGV < 6) { die "Breakdown_Paired_Ends.pl OUTPUTDIR INPUT1 INPUT2 BarcodeIndexfile BarcodeColumn(0=first column) ProjectName\n";}
my $OUTPUT_DIR = $ARGV[0]; #directory for output
system("mkdir -p $OUTPUT_DIR");
my $infile1 = $ARGV[1];
my $infile2 = $ARGV[2];

# Get acceptable cell barcodes
my %CellBarcodes = ();
open (my $ifh, $ARGV[3]) or die "Cannot open $ARGV[3]\n";
<$ifh>; # header
my $column = $ARGV[4];
my $index=1;
my %ofhs = ();
while (<$ifh>) {
	if ($_ =~/^#/) {next;}
	my @record = split(/\s+/);
	my $barcode = $record[$column];
	$CellBarcodes{$barcode} = $index;
	open(my $fh,'>',"$OUTPUT_DIR/$ARGV[5]_$barcode.fq") or die $!;
	$ofhs{$index} = $fh;
	$index++;
} close($ifh);

my $NotProperTail = 0;
my $NotPossibleCell = 0;
my $AmbiguousCell = 0;
my $ExactMatch = 0;
my $Mismatch1 = 0;
my $Mismatch2 = 0;
my $total_reads = 0;
open (my $ifh1, $infile1) or die $!;
open (my $ifh2, $infile2) or die $!;
while(<$ifh1>) {
	my $file1line = $_;
	my $file2line = <$ifh2>;
	if ($file1line =~ /^@/) {
		my @thing1 = split(/\s+/,$file1line);
		my @thing2 = split(/\s+/,$file2line);
		my $readname = $thing1[0];
		if ($readname ne $thing2[0]) {die "file1 & file2 readnames don't match!\n";}
		my $barcodes = <$ifh1>;
		my $read = <$ifh2>;
		$total_reads++;
		my $mismatches = 0;
#		if ($barcodes =~ /([ATCGNUKMRYSWBVHDX]{11})([ATCGNUKMRYSWBVHDX]{10})[TKYWBHDNX]{9}/) {
		if ($barcodes =~ /^([ATCGNUKMRYSWBVHDX]{11})([ATCGNUKMRYSWBVHDX]{10})/) {
			my $UMI = $2;
			my $CellID = $1;
			if (!exists($CellBarcodes{$CellID})) { # Not an expected barcode
				if ($CellID !~ /^[ATCG]+$/) {
					$mismatches = () = $CellID =~ /[^ATCG]/g; # count uncertain bases as mismatches
					$CellID =~ s/[^ATCG]/./g; #Turn non-ATCG bases into wildcards
				}
				my @matches = ();
				my %close = ();
				foreach my $barcode (keys(%CellBarcodes)) {
					if ($barcode =~/$CellID/) { # Match but with uncertainty
						push(@matches, $barcode);
					} else {
						if (scalar(@matches == 0)) { # Count mismatches
							my $count = ( $barcode ^ $CellID ) =~ tr/\0//;
							if ($count >= length($barcode)-2) { # Allow upto 2 mismatches
								$close{$barcode} = $count;
							}
						}
					}
				}
				if (scalar(@matches) == 0 && scalar(keys(%close)) > 0) { # Has 1 or 2 mismatches
					my $max = my_max(values(%close)); # Closest match
					$mismatches = length($CellID)-$max;
					foreach my $code (keys(%close)) {
						if ($close{$code} == $max) {
							push(@matches,$code);
						}
					}
				}
				if (scalar(@matches) == 1) { # single best match
					$CellID = $matches[0];
					if ($mismatches == 2) {
						$Mismatch2++;
					}
					if ($mismatches == 1) {
						$Mismatch1++;
					}
				} elsif (scalar(@matches) > 1) { #More than one equally good match
					$AmbiguousCell++;
					next;
				} else { # No match
					$NotPossibleCell++;
					next;
				}
			} else { # Exact match
				$ExactMatch++;
			} 
			# ProperTailProperBarcode
			<$ifh1>;<$ifh2>; #+'s
			my $file1qual = <$ifh1>;
			my $file2qual = <$ifh2>;
			my $handle = $ofhs{$CellBarcodes{$CellID}};
			print $handle "$readname:$UMI\n$read+\n$file2qual";
		} else {
			$NotProperTail++;
			next;
		}
	} else {next;}
}
print STDERR "Not proper read: $NotProperTail\nNot possible cell: $NotPossibleCell\nAmbiguous: $AmbiguousCell\nExact Matches:$ExactMatch\nOne mismatch: $Mismatch1\nTwo mismatch: $Mismatch2\n Total: $total_reads\n";
close($ifh1);
close($ifh2);
foreach my $ofh (keys(%ofhs)) {close($ofhs{$ofh});}


sub my_max {
	if (scalar(@_) == 1) {return($_[0])};
	my $max = shift;
	foreach my $ele (@_) {
		if ($ele > $max) {$max = $ele;}
	}
	return($max);
}
