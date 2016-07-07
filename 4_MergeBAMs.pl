use strict;
use warnings;

# 18 Apr 2015 : added path to samtools and the check that this samtools is available.
# 10 Apr 2015 : added indexing of dedupped file.

if (scalar(@ARGV) < 2) {die "Arguements: sortedmappedbamfiledirectory outputfileprefix\n";}

my $dir = $ARGV[0];#"/lustre/scratch108/compgen/team218/TA/RNASeqFilesMapped";

# Sort files by cell
my @files = glob("$dir/*sorted*aligned.bam");
my %sample2files = ();
foreach my $file (@files) {
#	if ($file =~ /([ATCG]{5,})/) {
	if ($file =~ /([^\/]+_Cell\d\d)/) {
		push(@{$sample2files{$1}},$file);
	} else {
		die "$file does not match?\n";
	}
}

if (! -e "/usr/bin/samtools") { die "Cannot find samtools\n";}
# merge files for each cell 
open (my $ofh, ">", "$ARGV[1]\_DeDuppingStatistics.out") or die $!;
print $ofh "sample\tdups\treads\n";
foreach my $sample (sort(keys(%sample2files))) {
	print STDERR "Starting $sample\n";
	my $mergedfile = "$dir/$ARGV[1]\_$sample.sorted.bam";
	my $dedupedfile = "$dir/$ARGV[1]\_$sample.sorted.dedupped.bam";
	if (! -e $dedupedfile) {
		my @infiles = @{$sample2files{$sample}};
		if (scalar(@infiles) > 1) {
			print("/usr/bin/samtools merge $mergedfile @infiles\n");
	#		print STDERR "Finished Merging @infiles\n";
			print("/usr/bin/samtools rmdup $mergedfile $dedupedfile 2> dup.log\n");
	#		print STDERR "Finished removing dups from $mergedfile\n";
		#	system("samtools index $dedupedfile\n"); # Changed my mind, will do this as needed from 4_RSeQC_Multiple.sh
		} else {
			$mergedfile = $infiles[0];
			system("/usr/bin/samtools rmdup $mergedfile $dedupedfile 2> dup.log\n");
		}
		my $last = ""; 
#		open (my $ifh, "dup.log") or die $!;
#		while (<$ifh>) {$last=$_;} close($ifh);
#		if ($last =~ /(\d+) \/ (\d+) =/) {
#			print $ofh "$sample\t$1\t$2\n";
#		} else {die "$last line does not match\n";}
##		print STDERR "Finished extracting data from logfile & writing to new output file\n";
	}
}
close ($ofh);
