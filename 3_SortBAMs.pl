use strict;
use warnings;

foreach my $file (glob("/lustre/scratch108/compgen/team218/TA/RNASeqFilesMapped/*.out.bam")) {
	$file =~ /(.*)\.out\.bam$/;
	my $outprefix = "$1.sorted";
	system("bsub -R\"select[mem>3000] rusage[mem=3000]\" -M3000 -q normal -o output.%J /nfs/users/nfs_t/ta6/RNASeqPipeline/3_SAMtools_sort_wrapper.sh $file $outprefix 3000000000\n");
}
