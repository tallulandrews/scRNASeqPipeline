use strict;
use warnings;

# Input a set of fastQ sequencing files
# gunzip, read, and re-gzip each one in turn
# Count No. Reads, Length of Reads, 
# Get number of unique cells & number of reads for each one (I think this is the second thing in the header line). 

if (@ARGV < 1) { die "Gather_Summary_Statistics.pl list_of_gzipped_fastq_files\n";}

my %cell2count = ();
my %lane2count = ();
#print join("\n", @ARGV)."\n";
#exit();
foreach my $file (@ARGV) {
	my $lane = "";
	if ($file =~ /(lane\d+)/) {
		$lane = $1;
	}
	my $workingfile = "/lustre/scratch108/compgen/team218/TA/temporaryfile1.txt.gz";
	system("cp $file $workingfile");
	system("gunzip $workingfile");
	$workingfile =~ s/\.gz$//;
	open (my $ifh, $workingfile) or die "Cannot open $workingfile :  $!\n";

	while (<$ifh>) {
		if ($_ =~ /^@/) {
			my @record = split(/\s+/);
			$cell2count{$record[1]} ++;
			$lane2count{$lane}++;
		}
	} close ($ifh);
	system("rm $workingfile");
#	exit();
}
foreach my $cell (sort(keys(%cell2count))) {
	print "$cell\t$cell2count{$cell}\n";
}
foreach my $lane (sort(keys(%lane2count))) {
	print "$lane\t$lane2count{$lane}\n";
}
