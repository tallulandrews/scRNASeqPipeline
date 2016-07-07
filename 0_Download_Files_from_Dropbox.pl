use strict;
use warnings;
#system("wget "LINK" > index.txt");
my %files = ();
open(my $ifh, "index.txt") or die $!;
while (<$ifh>) {
	if ($_ =~ /\.gz/) {
		while($_ =~ s/href="(.*?\.gz)/Done/){
#			print $1."\n"; 
			$files{$1} = 1;
		}
	}
} close($ifh);

foreach my $file (keys(%files)) {
	system("wget $file")
}
