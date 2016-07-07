use strict;
use warnings;

if (scalar(@ARGV) != 1) {die "Please provide a directory of STAR output\n";}

my @files = glob("$ARGV[0]/*Log.final.out");
print "lane\tsample\texp\tproject\tfile\tNreads\tNuniquemap\tNmultimap\tNnomap\tNsplice\tNnovelSJ\tNoMapTooManyMap\tNoMapTooManyMis\tNoMapTooShort\n";
foreach my $file (@files) {
	my $fullfilename = $file;

	# Get as much info from file names as possible
	$file =~ /([^\/]+)$/; $file = $1;
	my $laneID = "NA"; my $sampleID = "NA"; my $expID = "NA"; my $projectID = "NA"; my $fileID = "NA";
	if ($file =~ s/(lane\d+)//) {$laneID = $1;}
#	if ($file =~ s/(exp\d+)//) {$expID = $1;}
#	if ($file =~ s/(sc\d)//) {$expID = $1;}
	if ($file =~ s/([ACTG]{5,})//) {$sampleID = $1;}
#	if ($file =~ s/(cell\d\d)//) {$sampleID = $1;}
	if ($file =~ /^([^_]+)/) {
		my @remnants = split(/_+/, $file);
		$projectID = $remnants[0];
		$fileID = $remnants[1];
	}

#	print "$fullfilename\n";
	print "$laneID\t$sampleID\t$expID\t$projectID\t$fileID\t";

	my $Nreads = 0, my $Nuniquelymapped = 0; my $Nmultimap = 0; my $Nsplice = 0; my $NspliceAnn = 0;
	my $UnmappedTooManyMultimapN = 0; my $UnmappedTooManyMMprop = 0; my $UnmappedTooShortprop = 0;
	open(my $ifh, $fullfilename) or die $!;
	while (<$ifh>) {
		if ($_ =~ /Number of input reads[\s|]+(\d+)/) {$Nreads = $1;}
		if ($_ =~ /Uniquely mapped reads number[\s|]+(\d+)/) {$Nuniquelymapped = $1;}
		if ($_ =~ /Number of reads mapped to multiple loci[\s|]+(\d+)/) {$Nmultimap = $1;}
		if ($_ =~ /Number of splices: Total[\s|]+(\d+)/) {$Nsplice = $1;}
		if ($_ =~ /Number of splices: Annotated \(sjdb\)[\s|]+(\d+)/) {$NspliceAnn = $1;}
		if ($_ =~ /Number of reads mapped to too many loci[\s|]+(\d+)/) {$UnmappedTooManyMultimapN = $1;}
		if ($_ =~ /of reads unmapped: too many mismatches[\s|]+([\d\.]+%)/) {$UnmappedTooManyMMprop = $1;}
		if ($_ =~ /of reads unmapped: too short[\s|]+([\d\.]+%)/) {$UnmappedTooShortprop = $1;}
	} close ($ifh);

	print "$Nreads\t$Nuniquelymapped\t$Nmultimap\t".($Nreads-$Nuniquelymapped-$Nmultimap)."\t$Nsplice\t".($Nsplice-$NspliceAnn)."\t$UnmappedTooManyMultimapN\t$UnmappedTooManyMMprop\t$UnmappedTooShortprop\n";

#	exit(); #short circuit for debugging
}
