use strict;
use warnings;

if (scalar(@ARGV) != 1) {die "Please provide a directory of UMI-tools running output\n";}

my @files = glob("$ARGV[0]/*err*");
print "sample\tmethod\tNreads\tNmolecules\n";
for(my $i = 0; $i < scalar(@files); $i++) {
	my $file = $files[$i];

	my $Nreads = 0, my $Nmolecules = 0;
	my $cellID = ""; my $method = "";
	open(my $ifh, $file) or die $!;
	while (<$ifh>) {
		if ($_ =~ /Number of reads in:\s*(\d+)/) {$Nreads = $1;}
		if ($_ =~ /Number of reads out:\s*(\d+)/) {$Nmolecules = $1;}
		if ($_ =~ /([AGCT]+)Aligned/) {$cellID = $1;}
		if ($_ =~ /Method:\s*(\w+)/) {$method = $1;}
	} close ($ifh);

	print "$cellID\t$method\t$Nreads\t$Nmolecules\n";
}
