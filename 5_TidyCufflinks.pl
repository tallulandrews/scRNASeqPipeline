use strict;
use warnings;

if (@ARGV < 2) {die "Provide: a directory of cufflinks output, and the file it was produced from\n";}

my $tag="ERR";
my $origfile = $ARGV[1];
if ($origfile =~ /_([^_]+_Cell\d\d)/) {
        $tag = $1;
} else {
        die "$origfile does not match\n";
}

#$origfile =~ /([ACGT]{5,})/;
if( chdir($ARGV[0])) {

	foreach my $file (glob("*")) {
		system("mv $file ../$tag\_$file \n");
	}
	chdir("/nfs/users/nfs_t/ta6/RNASeqPipeline");
	rmdir($ARGV[0]);
} else {die "error changing directory to $ARGV[0]";}
	
