use strict;
use warnings;

# Matches upto two mismatches between observed cell barcodes and the expected cell barcodes
# Excludes reads with problematic UMIs: >= 80% A, >= 80% T, contained in adaptor sequence. - Note do not provide adaptors for short UMI datasets (fewer than 7 bases) since there is a high probability of real UMIs being contained in the adaptor for such cases.
# Allows barcodes to contain ambiguous bases
# Allows trailing bases at the end of the barcode sequence but requires barcodes to begin from the first base in the barcode sequence.

if (@ARGV < 6) { die "Usage: 1_Breakdown_UMI_read_pairs.pl BarcodeFastq ReadFastq BarcodeStructure(C=cellbarcodebase, U=UMIbase) BarcodeIndexFile(\"UNKNOWN\" triggers counting reads with every unique barcode) BarcodeColumn(0=first column) OutputPrefix AdaptorFasta(optional)\n";}
my $infile1 = $ARGV[0];
my $infile2 = $ARGV[1];
my $barcodestructure = $ARGV[2];

# Parse Barcode Structure #

$barcodestructure =~ s/[^CU]//g;

print "$barcodestructure\n";

my $order = -1;
my $C_len = -1;
my $U_len = -1;

if ($barcodestructure =~ /^(C+)(U+)$/) {
	$order=1;
	$C_len = length($1);
	$U_len = length($2);
	print "Barcode Structure: $C_len bp CellID followed by $U_len bp UMI\n";
} elsif ($barcodestructure =~ /^(U+)(C+)$/) {
	$order = 0;
	$C_len = length($2);
	$U_len = length($1);
	print "Barcode Structure: $U_len bp UMI followed by $C_len bp CellID\n";
} else {
	die "Intermingled cell & umi barcodes are not supported\n";
}
# ----------------------- #

my $OUTprefix = $ARGV[5]; #prefix for output
#Ensure output directory exists
if ($OUTprefix =~ /^(.+)\/[^\/]$/) {
	if ($1 ne ".") {
		system("mkdir -p $1");
	}
}

# Read Expected Cell Barcodes #
my %CellBarcodes = ();
my %ofhs = ();
if ($ARGV[3] ne "UNKNOWN") {
	open (my $ifh, $ARGV[3]) or die "Cannot open $ARGV[3]\n";
	<$ifh>; # header
	my $column = $ARGV[4];
	my $index=1;
	while (<$ifh>) {
		chomp;
		if ($_ =~/^#/) {next;}
		my @record = split(/\s+/);
		my $barcode = $record[$column];
		$CellBarcodes{$barcode} = $index;
		open(my $fh,'>',"$OUTprefix\_$barcode.fq") or die $!;
		$ofhs{$index} = $fh;
		$index++;
	} close($ifh);
}
# --------------------------- #

# Read Adaptor Fasta #
my @Adaptors = ();
if (defined($ARGV[6])) {
	open (my $afh, $ARGV[6]) or die $!;
	while (<$afh>) {
		if ($_ =~ /^>/) {
			my $seq = <$afh>;
			chomp($seq);
			push(@Adaptors, $seq);
		}
	} close($afh);
}
# ------------------ #
		

### Process Reads ###

# Summary Statistics
my $NotProperBarcodes = 0;
my $NotPossibleCell = 0;
my $AmbiguousCell = 0;
my $ExactMatch = 0;
my $Mismatch1 = 0;
my $Mismatch2 = 0;
my $BadUMI = 0;
my $total_reads = 0;
my $OutputReads=0;

open (my $ifh1, $infile1) or die $!;
open (my $ifh2, $infile2) or die $!;
while(<$ifh1>) {
	my $file1line = $_;
	my $file2line = <$ifh2>;
	if ($file1line =~ /^@/) { #Skip any file headers

		# Ensure matching pair of reads
		my @thing1 = split(/\s+/,$file1line);
		my @thing2 = split(/\s+/,$file2line);
		my $readname = $thing1[0];
		if ($readname ne $thing2[0]) {die "file1 & file2 readnames don't match! $readname $thing2[0]\n";}
		my $barcodes = <$ifh1>;
		my $read = <$ifh2>;
		$total_reads++;

		# Parse barcodes
		my $CellID = ""; my $UMI = "";
		if ($order) {
			if ($barcodes =~ /^([ATCGNUKMRYSWBVHDX]{$C_len})([ATCGNUKMRYSWBVHDX]{$U_len})/) {
				$CellID = $1; $UMI = $2;
			} else {$NotProperBarcodes++; next;}
		} else {
			if ($barcodes =~ /^([ATCGNUKMRYSWBVHDX]{$U_len})([ATCGNUKMRYSWBVHDX]{$C_len})/) {
				$CellID = $2; $UMI = $1;

			} else {$NotProperBarcodes++; next;}
		}
#		if ($barcodes =~ /^([ATCGNUKMRYSWBVHDX]{11})([ATCGNUKMRYSWBVHDX]{10})/) {


		# Correct for upto two mismatches between observed and expected cell barcodes
		if ($ARGV[3] ne "UNKNOWN") {
		my $mismatches = 0;
		if (!exists($CellBarcodes{$CellID})) { # Not an expected barcode

			# Barcode contains uncertain bases -> convert to wildcards and pattern match on expected barcodes. (given priority over barcodes with higher confidence mismatches)
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
			# If exact matches with uncertainty then give those priority, otherwise keep the most similar expected barcodes
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

		} #If known barcodes

		# UMI filter

		# All As or All Ts with 2 mismatches - No I think >80% A or T is a better definition since short UMIs quite likely to get real A/T rich UMIs
		my $As_in_UMI = () = $UMI =~ /A/g;	
		my $Ts_in_UMI = () = $UMI =~ /T/g;	
		if ($As_in_UMI >= length($UMI)*0.8 || $Ts_in_UMI >= length($UMI)*0.8) {
			$BadUMI++; next;
		}
		# UMI contained in adaptor sequence - Don't need UMI length limit here since just don't provide adaptor sequences for short UMI datasets.
		if (scalar(@Adaptors) > 0) {
			foreach my $adapt (@Adaptors) {
				if ($adapt =~ /$UMI/) {
					$BadUMI++; next;
				}
			}
		}

		if ($ARGV[3] ne "UNKNOWN") {
			# Has Acceptable Barcode
			<$ifh1>;<$ifh2>; #+'s
			my $file1qual = <$ifh1>;
			my $file2qual = <$ifh2>;
			my $handle = $ofhs{$CellBarcodes{$CellID}};
			print $handle "$readname:$UMI\n$read+\n$file2qual";
			$OutputReads++;
		} else {
			$CellBarcodes{$CellID}++;
		}
	} else {next;}
}
if ($ARGV[3] ne "UNKNOWN") {
	print STDERR "
	Not proper read: $NotProperBarcodes
	Not possible cell: $NotPossibleCell
	Ambiguous: $AmbiguousCell
	Exact Matches:$ExactMatch
	One mismatch: $Mismatch1
	Two mismatch: $Mismatch2
	Bad UMI: $BadUMI
	Input Reads: $total_reads
	Output Reads: $OutputReads\n";
	close($ifh1);
	close($ifh2);
	foreach my $ofh (keys(%ofhs)) {close($ofhs{$ofh});}
} else {
	print STDERR "Bad UMI: $BadUMI\n";
	my @Codes = sort { $CellBarcodes{$b} <=> $CellBarcodes{$a} } keys(%CellBarcodes);
	foreach my $code (@Codes) {
		print "$code ".$CellBarcodes{$code}."\n";
	}
}

sub my_max {
	if (scalar(@_) == 1) {return($_[0])};
	my $max = shift;
	foreach my $ele (@_) {
		if ($ele > $max) {$max = $ele;}
	}
	return($max);
}
