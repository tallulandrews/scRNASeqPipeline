use strict;
use warnings;

# Optionally takes a second arguement of a list of sample to exclude. -> this is untested

# Output:
# sample	totalreads	QCfailed	duplicates	multimap	uniquemap	unmapped	rRNA	read1/read2	+/-	non-splice	splice	GeneBodyskewness avgfragsize

if (@ARGV < 1) {die "Please provide a directory of RSeQC output files (and optionally a file of samples to exclude)\n";}

my %exclude = ();
if (defined($ARGV[1])) {
	open(my $ifh, $ARGV[1]) or die $!;
	while (<$ifh>) {
		chomp;
		my @record = split(/\s+/);
		foreach my $ele (@record) {
			$exclude{$ele} = 1;
		}
	} close($ifh);
}

my @files = glob("$ARGV[0]/RSEQC_*.output");
my %sample2output = ();



my @ordered_expected_keys = ("totalreads","QCfailed","duplicates","multimap","uniquemap","unmapped","rRNA", "read1/read2", "+/-", "non-splice", "splice", "GeneBodyskewness", "avgfragsize");

foreach my $file (@files) {
#	$file =~ /([ATGC]{5,})/;
	$file =~ /(sc\d_cell\d\d)/;
	my $sample = $1;
	if (exists($exclude{$sample})) {next;}
	open (my $ifh, $file) or die $!;
	my %outputs = ();
	while (<$ifh>) {
		if ($_ =~ /Total records:\s*(\d+)/) {
			$outputs{"totalreads"} = $1;
		}
		elsif ($_ =~ /Reads consumed by input gene list\):\s*(\d+)/) {
			$outputs{"rRNA"} = $1;
		}
		elsif ($_ =~ /QC failed:\s*(\d+)/) {
			$outputs{"QCfailed"} = $1;
		}
		elsif ($_ =~ /PCR duplicate:\s*(\d+)/) {
			$outputs{"duplicates"} = $1;
		}
		elsif ($_ =~ /Non primary hits\s*(\d+)/) {
			$outputs{"multimap"} += $1;
		}
		elsif ($_ =~ /mapq < mapq_cut \(non-unique\):\s*(\d+)/) {
			$outputs{"multimap"} += $1;
		}
		elsif ($_ =~ /mapq >= mapq_cut \(unique\):\s*(\d+)/) {
			$outputs{"uniquemap"} += $1;
		}
		elsif ($_ =~ /Unmapped reads:\s*(\d+)/) {
			$outputs{"unmapped"} = $1;
		}
		elsif ($_ =~ /Read-1:\s*(\d+)/) {
			$outputs{"read1"} = $1;
		}
		elsif ($_ =~ /Read-2:\s*(\d+)/) {
			$outputs{"read2"} = $1;
		}
		elsif ($_ =~ /Reads map to '\+':\s*(\d+)/) {
			$outputs{"+"} = $1;
		}
		elsif ($_ =~ /Reads map to '\-':\s*(\d+)/) {
			$outputs{"-"} = $1;
		}
		elsif ($_ =~ /Non-splice reads:\s*(\d+)/) {
			$outputs{"non-splice"} = $1;
		}
		elsif ($_ =~ /Splice reads:\s*(\d+)/) {
			$outputs{"splice"} = $1;
		}
		elsif ($_ =~ /Sample\s+Skewness/) {
			my $data = <$ifh>;
			$data =~ /\s+([-\.\d]+)/;
			$outputs{"GeneBodyskewness"} = $1;
		}
		else {
			#count number of tabs in line
			my @record = split(/\t/);
			if (scalar(@record) == 8 && $record[7] =~ /\d/) {
				$outputs{"sumfrag"} += $record[5]*$record[4];
				$outputs{"numfrag"} += $record[4];
			}
		}
	} close($ifh);
	if (exists($outputs{"read1"}) && exists($outputs{"read2"})) {
		$outputs{"read1/read2"} = $outputs{"read1"}/$outputs{"read2"};
	} else {
		$outputs{"read1/read2"} = "NA";
	}
	if (exists($outputs{"+"}) && exists($outputs{"-"})) {
		$outputs{"+/-"} = $outputs{"+"}/$outputs{"-"};
	} else {
		$outputs{"+/-"} = "NA";
	}
	if ((exists($outputs{"sumfrag"}) && exists($outputs{"numfrag"})) && $outputs{"numfrag"} > 0) {
		$outputs{"avgfragsize"} = $outputs{"sumfrag"}/$outputs{"numfrag"};
	} else {
		$outputs{"avgfragsize"} = "NA";
	}

	foreach my $key (@ordered_expected_keys){
		if (!exists($outputs{$key})) {
			die "No data for $key\n";
		}
		push(@{$sample2output{$sample}},$outputs{$key});
	}
}
 
print "sample\t".join("\t", @ordered_expected_keys)."\n";
foreach my $sample (keys(%sample2output)) {
	print "$sample\t".join("\t", @{$sample2output{$sample}})."\n";
}

# Combine Rscripts

@files = glob("$ARGV[0]/RSEQC_*.GC_plot.r");
my $plotcmd = "";
my @datacmds = ();
my @bincounts = (0)x100;
my $pdfcmd="pdf(\"$ARGV[0]/RSEQC_GC_plot_Combined.pdf\")\n";
foreach my $file (@files) {

#	$file =~ /([ATCG]{5,})/; my $sample = $1;
	$file =~ /(sc\d_cell\d\d)/; my $sample = $1;
	if (exists($exclude{$sample})) {next;}

	open (my $ifh, $file) or die $!;
	<$ifh>; #pdfcmd
	my $data = <$ifh>;
# Data is originally  "rep(c(),times=c())" how to process this? -> split the two c()'s and interate for ($i ...) through each of them.
	my @stuff = split(/[\(\)]/,$data);
	my @values = split(",",$stuff[2]);
	my @times = split(",",$stuff[4]);
	if (scalar(@values) != scalar(@times)) {die "Does not compute: Not same number of values as times\n";}
	for (my $i =0; $i < scalar(@values); $i++) {
		my $index = int($values[$i]);
# floor each data point to nearest integer, add 1 to that index of @bincounts
		$bincounts[$index]+=$times[$i];
	}
	$plotcmd=<$ifh>;# need new plot command
	<$ifh>;
	close($ifh);
}
open(my $ofh, ">", "$ARGV[0]/RSEQC_GC_plot_Combined.r") or die $!;
print $ofh $pdfcmd;
print $ofh "data=c(".join(",",@bincounts).")\n";
print $ofh "xes=barplot(data/sum(data), space=0, col=\"white\",ylab=\"Density of Reads\", border=\"blue\", main=\"\", xlab=\"GCcontent (%)\")\n";
print $ofh "axis(1,at=xes,labels=1:100,col=\"white\")\n";
print $ofh "dev.off()\n";
close($ofh);

@files = glob("$ARGV[0]/RSEQC_*.geneBodyCoverage.r");
$plotcmd = "matplot(data,type='l', xlab=\"Gene body percentile (5'->3')\", ylab=\"Coverage\",lwd=0.8,col=colours)\n";
@datacmds = ();
my $colourcmd = "colours=colorRampPalette(c(\"#7fc97f\",\"#beaed4\",\"#fdc086\",\"#ffff99\",\"#386cb0\",\"#f0027f\"))(".scalar(@files).")\n";
$pdfcmd="pdf(\"$ARGV[0]/RSEQC_geneBodyCoverage_plot_Combined.pdf\")\n";
foreach my $file (@files) {
#	$file =~ /([ATCG]{5,})/; my $sample = $1;
	$file =~ /(sc\d_cell\d\d)/; my $sample = $1;
	if (exists($exclude{$sample})) {next;}

	open (my $ifh, $file) or die $!;
	my $data = <$ifh>;
	$data =~ /(c\(.+\))/;
	push(@datacmds, $1);
	close($ifh);
}
open($ofh, ">", "$ARGV[0]/RSEQC_geneBodyCoverage_plot_Combined.r") or die $!;
print $ofh $pdfcmd;
print $ofh "data=cbind(".join(",",@datacmds).")\n";
print $ofh $colourcmd;
print $ofh $plotcmd;
print $ofh "dev.off()\n";
close($ofh);

# Use average at each point for each line over all samples!
@files = glob("$ARGV[0]/RSEQC_*.junctionSaturation_plot.r");
my $xcmd = "x=c(5,10,15,20,25,30,35,40,45,50,55,60,65,70,75,80,85,90,95,100)";
$pdfcmd="pdf(\"$ARGV[0]/RSEQC_junctionSaturation_plot_Combined.pdf\")";
my $legendcmd = "legend(5,40, legend=c(\"All junctions\",\"known junctions\", \"novel junctions\"),col=c(\"blue\",\"red\",\"green\"),lwd=1,pch=1)";
my %data = ();
foreach my $file (@files) {
#	$file =~ /([ATCG]{5,})/; my $sample = $1;
	$file =~ /(sc\d_cell\d\d)/; my $sample = $1;
	if (exists($exclude{$sample})) {next;}

	open (my $ifh, $file) or die $!;
	<$ifh>;<$ifh>; #pdf cmd, xes
	my $y = <$ifh>; $y =~ s/y=c\(//; $y =~s/\)//;
	my @yes = split(/,/,$y);
	for (my $i = 0; $i < scalar(@yes); $i++) {$data{"y"}->[$i] += $yes[$i];}

	my $z = <$ifh>; $z =~ s/z=c\(//; $z =~s/\)//;
	my @zes = split(/,/,$z);
	for (my $i = 0; $i < scalar(@zes); $i++) {$data{"z"}->[$i] += $zes[$i];}

	my $w = <$ifh>; $w =~ s/w=c\(//; $w =~s/\)//;
	my @wes = split(/,/,$w);
	for (my $i = 0; $i < scalar(@wes); $i++) {$data{"w"}->[$i] += $wes[$i];}

	close($ifh);
}
#plot(x,z/1000,xlab='percent of total reads',ylab='Number of splicing junctions (x1000)',type='o',col='blue',ylim=c(n,m))
#points(x,y/1000,type='o',col='red')
#points(x,w/1000,type='o',col='green')

open($ofh, ">", "$ARGV[0]/RSEQC_junctionSaturation_plot_Combined.r") or die $!;
print $ofh "x=c(5,10,15,20,25,30,35,40,45,50,55,60,65,70,75,80,85,90,95,100)\n";
print $ofh "y=c(".join(",", @{$data{"y"}}).")/".scalar(@files)."\n";
print $ofh "z=c(".join(",", @{$data{"z"}}).")/".scalar(@files)."\n";
print $ofh "w=c(".join(",", @{$data{"w"}}).")/".scalar(@files)."\n";
print $ofh "m=max(y,z,w)/1000\nn=min(y,z,w)/1000\n";
print $ofh $pdfcmd."\n";
print $ofh "plot(x,z/1000,xlab='percent of total reads',ylab='Number of splicing junctions (x1000)',type='o',col='blue',ylim=c(n,m))\npoints(x,y/1000,type='o',col='red')\npoints(x,w/1000,type='o',col='green')\n";
print $ofh $legendcmd."\n";

print $ofh "dev.off()\n";
close($ofh);
