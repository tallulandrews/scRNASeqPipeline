use strict;
use warnings;


if (@ARGV < 1) {die "requires at least one headerfile\n";}
my %CellID2WellID = ();

foreach my $file (@ARGV) {
	#Extract cell ID
	my $cellid = "";
	if ($file =~ /_(\d_\d+)\./) {
		$cellid = $1;
	} else {
		die "$file does not match\n";
	}
	open (my $ifh, $file) or die $!;
	while (<$ifh>) {
		if ($_ =~ /^\@RG/) {
			# Match the plate-well ID
			my $wellid = "";
			if ($_ =~ /SM:SCGC--(\w+)/) {
				$wellid = $1;
			} else {
				die "$_ does not match";
			}
			$CellID2WellID{$cellid} = $wellid;
			last;
		} else {
			next;
		}
	} close($ifh);
}

foreach my $cell (sort(keys(%CellID2WellID))) {
	print $cell."\t".$CellID2WellID{$cell}."\n";
}
