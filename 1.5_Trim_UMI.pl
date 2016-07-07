use strict;
use warnings;

if (@ARGV < 3) {die "1.5_Trim_UMI.pl 5'Length 3'Length inputdir outputdir\n";}

my @files = glob("$ARGV[2]/*.fq");
my $tmpfile = "tmp.txt";
foreach my $file (@files) {
	$file =~ /([^\/]+\.fq)/;
	my $filename = $1;
	open(my $ifh, $file) or die $!;
	open(my $ofh, ">",$tmpfile) or die $!;

	while (<$ifh>) {
		if ($_ =~ /:/) {
			chomp;
			my @stuff = split(/\:/);
			my $UMI = $stuff[scalar(@stuff)-1];
			my $trimmed = substr($UMI, $ARGV[0], -$ARGV[1]);
			if ($ARGV[1] == 0) {
				$trimmed = substr($UMI, $ARGV[0]);
			}
			$stuff[scalar(@stuff)-1]=$trimmed;
			print $ofh (join(":",@stuff)."\n");
		} else {
			print $ofh ($_);
		}
	} close ($ifh); close ($ofh);
	system("mv $tmpfile $ARGV[3]/$filename");
}
