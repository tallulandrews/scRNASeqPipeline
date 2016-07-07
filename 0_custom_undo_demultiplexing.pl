use strict;
use warnings;

open (my $ifh, "/lustre/scratch108/compgen/team218/TA/Bergiers_Wafergen/wta98_embl2.metadata") or die $!;
my %Name2Barcode = ();
while (<$ifh>) {
        if ($_ =~/^#/) {next;}
        my @record = split(/\s+/);
        my $name = "R".$record[6]."C".$record[7];
	$Name2Barcode{$name} = $record[0];
} close($ifh);


my @files1 = glob("/lustre/scratch108/compgen/team218/TA/Bergiers_Dropbox/*_1.txt");
my @files2 = glob("/lustre/scratch108/compgen/team218/TA/Bergiers_Dropbox/*_2.txt");

if (scalar(@files1) != scalar(@files2)) {die "Must have equal number of read1 & read2 files\n";}

my $unassigned1 = "";
my $unassigned2 = "";
my $out1 = "lane1_Waf375_1.fq";
my $out2 = "lane1_Waf375_2.fq";
open(my $ofh1, ">", $out1) or die $!;
open(my $ofh2, ">", $out2) or die $!;

for(my $i = 0; $i < scalar(@files1); $i++) {
	open(my $ifh1, $files1[$i]) or die $!;
	open(my $ifh2, $files2[$i]) or die $!;
	
	my $barcode = "";
	if ($files1[$i] =~ /sample(R\d+C\d+)_/) {
		my $name=$1;
		if (exists($Name2Barcode{$name})) {
			$barcode = $Name2Barcode{$name};
		} else {
			die "$name has no barcode\n";
		}
	} else {
		if ($files1[$i] =~/unassigned/i){
			$unassigned1 = $files1[$i];
			$unassigned2 = $files2[$i];
			next;
		}
		die "$files1[$i] does not match\n";
	}

	while(<$ifh1>) {
	        my $file1line = $_;
	        my $file2line = <$ifh2>;
	        if ($file1line =~ /^@/) {
	                my @thing1 = split(/\s+/,$file1line);
	                my @thing2 = split(/\s+/,$file2line);
	                my $readname = $thing1[0];
	                if ($readname ne $thing2[0]) {die "file1 & file2 readnames don't match!\n";}
			my $barcodeseq = <$ifh1>;
			$barcodeseq = $barcode.$barcodeseq;
	                my $read = <$ifh2>;
			<$ifh1>;<$ifh2>; #+'s
                        my $file1qual = <$ifh1>;
			$file1qual =  'E' x length($barcode) . $file1qual;
                        my $file2qual = <$ifh2>;
			print $ofh1 "$readname\n$barcodeseq+\n$file1qual";
			print $ofh2 "$readname\n$read+\n$file2qual";
		}
	}
	close($ifh1);
	close($ifh2);
} 
close ($ofh1); close($ofh2);
system("cat $unassigned1 >> $out1");
system("cat $unassigned2 >> $out2");
print "Successfully Completed\n";
