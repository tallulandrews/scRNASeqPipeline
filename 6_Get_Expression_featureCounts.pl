use strict;
use warnings;

if (@ARGV < 1) {die "Please provide directory of featurecounts output\n";}

my $dir = $ARGV[0];

my %Gene2ID2FragCount = ();
my @IDs = ();

foreach my $file (glob("$dir/*.fragmentcounts")) {
	my $ID = "ERR";
	if ($file =~ /([ATCG]{5,})A/) {
#	if ($file =~ /_([^_]+_Cell\d\d)/) {
		$ID = $1;
	} else {
		die "$file does not match\n";
	}	
	push(@IDs,$ID);
	open(my $ifh, $file) or die $!;
	while (<$ifh>) {
		chomp;
		if ($_ =~ /^#/ || $_ =~ /^Geneid/) {next;} #skip header & comments
		my @record=split(/\t/);
		my $gene = $record[0]; $gene =~ s/\s+//g;
		$Gene2ID2FragCount{$gene}->{$ID} = $record[6]; 
	} close ($ifh);
}

print join("\t",@IDs)."\n";
foreach my $gene (keys(%Gene2ID2FragCount)) {
	print "$gene";
	foreach my $ID (@IDs) {
		my $count = "NA";
		if (exists($Gene2ID2FragCount{$gene}->{$ID})) {
			$count = $Gene2ID2FragCount{$gene}->{$ID};
		} else { 
			$count = "0";
		}
		print "\t".$count;
	}
	print "\n";
}

my %ID2Unassigned = ();
foreach my $file (glob("$dir/*.fragmentcounts.summary")) {
	my $ID = "ERR";
	#if ($file =~ /_([^_]+_Cell\d\d)/) {
	if ($file =~ /([ATCG]{5,})A/) {
		$ID = $1;
	} else {
		die "$file does not match\n";
	}	
	open(my $ifh, $file) or die $!;
	<$ifh>; # header
	<$ifh>; #Assigned
	while (<$ifh>) {
		chomp;
		my @record=split(/\t/);
		$ID2Unassigned{$ID} += $record[1]
	} close ($ifh);
}

print "Unassigned_Various";
foreach my $ID (@IDs) {
	print "\t".$ID2Unassigned{$ID};
} 
print "\n";
