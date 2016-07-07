use strict;
use warnings;

if (scalar(@ARGV) < 1 || $ARGV[0] !~ /gbk$/) {die "Did not provide GBK file."}

my @sequence = ();
my $name = "";
my $file = $ARGV[0];

open (my $ifh, $file) or die $!;
my $seq_started = 0;
while (<$ifh>) {
	if ($_ =~ /^LOCUS/) {
		my @record = split(/\s+/);
		$name = $record[1];
	} elsif ($_ =~ /^ORIGIN/) {
		$seq_started = 1;
		next;
	} elsif ($_ =~ /^\/\//) {
		last;
	}
	if ($seq_started) {
		chomp;
		my $seq = $_;
		$seq =~ s/\s//g; #remove all whitespace
		$seq =~ s/\d//g; #remove all base numbers
		push(@sequence, $seq);
	}
} close($ifh);

$file =~ s/gbk$/fa/;
open (my $ofh, ">", $file) or die $!;
print $ofh ">$name\n";
foreach my $seq (@sequence) {print $ofh $seq."\n";}
close($ofh);

