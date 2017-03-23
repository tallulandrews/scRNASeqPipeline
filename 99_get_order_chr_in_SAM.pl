use strict;
use warnings;

if (@ARGV < 1) {die "Arguments: same file\n";}

my @chrs = ("NULL");
open (my $ifh, $ARGV[0]) or die $!;
while (<$ifh>) {
	if ($_ =~ /^@/) {next;}
	my @record = split(/\t/);
	my $chr = $record[2];
	my $i = scalar(@chrs) -1;
	if ($chr ne $chrs[$i]){
		push(@chrs, $chr);
	}
} close($ifh);

shift(@chrs); # remove NULL
print join("\n", @chrs);

