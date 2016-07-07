use strict;
use warnings;

# Input a pair of sequencing FastQ files
# gunzip, read, write out smaller broken down files in a format suitable for submitting job array, and re-gzip each one in turn
# Breakdown by lane & cellID
# Keep order. 
# This should work equally well for single-end reads and can take any number of files as arguments.
# TESTED

if (@ARGV < 3) { die "Breakdown_Paired_Ends.pl JOBID MAXREADS OUTPUTDIR FastQfile1 FastQfile2\n";}

my $JOBID = shift(@ARGV); #Maxmimum number of reads per file [job].
my $MAX_READS_PER_FILE = shift(@ARGV); #Maxmimum number of reads per file [job].
my $OUTPUT_DIR = shift(@ARGV); #directory for output
system("mkdir -p $OUTPUT_DIR");

foreach my $file (@ARGV) {
	my %cell2lines = ();
	my $workingfile = $file;
#	my $workingfile = "/lustre/scratch108/compgen/team218/TA/TemporaryFileDir/temporaryfile$JOBID.txt.gz";
#	system("cp $file $workingfile");
#	system("gunzip $workingfile");
#	$workingfile =~ s/\.gz$//;
#	my $pair = 0; my $orig_file_id = 0; my $experiment = "";
#	if ($file =~ /(exp\d)_.*_(Bergiers_\w+)_(\d)_sequence/) {
#	if ($file =~ /(lane\d)(sample\d)_(\d)_sequence/) {
#		$experiment = $1;
#		$orig_file_id = $2;
#		$pair = $3;
#	}
		
	open (my $ifh, $workingfile) or die "Cannot open $workingfile :  $!\n";

	while (<$ifh>) {
		if ($_ =~ /^@/) {
			my @record = split(/\s+/);
			my $cell = "AAAAAAAAAAA";
			if (scalar(@record) == 3) {
				$cell = $record[1];
			}
			push(@{$cell2lines{$cell}}, $_);
			push(@{$cell2lines{$cell}}, <$ifh>);
			push(@{$cell2lines{$cell}}, <$ifh>);
			push(@{$cell2lines{$cell}}, <$ifh>);
		}
	} close ($ifh);
#	system("rm $workingfile");
	foreach my $cell (sort(keys(%cell2lines))) {
		my $fileid = 1; my $Nlines = 0;
#		my $currentfile = "$OUTPUT_DIR/$orig_file_id\_$experiment\_$cell\_$pair.$fileid.fq";
		my $currentfile = "$OUTPUT_DIR/$JOBID\_$cell.$fileid.fq";
		open (my $ofh, ">$currentfile") or die $!;
		foreach my $line (@{$cell2lines{$cell}}) {

			print $ofh $line;
			$Nlines++;

			if ($Nlines == $MAX_READS_PER_FILE*4) {
				close ($ofh); #close current file
				system("gzip $currentfile"); #compress it
				$fileid++; 
#				$currentfile = "$OUTPUT_DIR/$orig_file_id\_$experiment\_$cell\_$pair.$fileid.fq";
				$currentfile = "$OUTPUT_DIR/$JOBID\_$cell.$fileid.fq";
				open ($ofh, ">$currentfile") or die $!; #open the next file
				$Nlines = 0; #reset line counter
			}
		}
		close($ofh); system("gzip $currentfile"); # close and compress the current file.
	}
#	if (-e $workingfile) {
#		system("rm $workingfile");
#	}
}
