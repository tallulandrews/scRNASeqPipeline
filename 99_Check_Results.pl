use strict;
use warnings;

if (@ARGV < 1) {die "requires one or more LSF output files\n";}

my $CPU = 0;
my $Mem = 0;
my $Count = 0;

foreach my $file (@ARGV) {
	open(my $ifh, $file) or die $!;
	my $success = 0;
	while(<$ifh>) {
		if ($_ =~ /Successfully completed/) {
			$success = 1;
			$Count++;
		}
		if ($success && $_ =~ /CPU time :\s+([\d\.]+) sec/) {
			$CPU += $1;
		}
		if ($success && $_ =~ /Max Memory :\s+([\d\.]+) MB/) {
			my $m = $1;
			if ($m > $Mem) {$Mem = $m;}
		}
	} close($ifh);
	if ($success) {
		system("rm $file\n");
	}
}
print "\"Total :\" ".scalar(@ARGV)."\n\"Success:\" $Count\n\"Max Mem:\" $Mem\n\"Total CPU:\" $CPU\n";
