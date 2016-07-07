use strict;
use warnings;

if (@ARGV < 1) {die "1.6_Summarizing_Trimming.pl directory of outputfiles\n";}

my @files = glob("$ARGV[0]/*");
my %Cell2ReadCount = ();
foreach my $file (@files) {
	open (my $ifh, $file) or die $!;
	my $cell = "";
	my $surviving = 0;
	while(<$ifh>) {
		if ($_ =~ /([ATCG]+)\.fq/) {
			$cell = $1;
		}
		if ($_ =~ /Surviving: (\d+) /) {
			$surviving=$1;
			last;
		}
	} close ($ifh);
	$Cell2ReadCount{$cell} = $surviving;
}

foreach my $code (sort(keys(%Cell2ReadCount))) {
	print "$code\t$Cell2ReadCount{$code}\n";
}
		

