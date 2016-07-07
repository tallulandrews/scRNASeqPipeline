use strict;
use warnings;
# Currently replaces all estimated FPKMs which are not significantly bigger than 0 with 0. -> not as of (Feb 9 2016), also changed "not detected" genes from NA to 0.

if (@ARGV < 2) {die "Please supply a directory of Cufflinks Output and a name of a file for output\n";}

my $dir = $ARGV[0];
my $outfile = $ARGV[1];

# First get expression for all genes & store details for all Cuff-Genes
my %AllGenes = (); my %AllSamples = ();
my %Gene2Sample2FPKM = ();
my %Gene2Sample2Locus=();

my @files = glob("$dir/*_genes.fpkm_tracking");	
foreach my $file (@files) {
#	$file =~ /([ATCG]{5,})/;
	my $ID = "ERR";
	if ($file =~ /([^_]+_Cell\d\d)/) {
		$ID = $1;
	} else {
		die "$file does not match!";
	}
	$AllSamples{$ID}=1;
	open(my $ifh, $file) or die $!;
	<$ifh>; # header
	while (<$ifh>) {
		chomp;
		my @record = split(/\t/);
		my $gene = $record[0];
		my $locus = $record[6];
		my @locus1 = split(/[:]/,$locus); # having this split on "-" destroyes by construct gene name
		my @locus2 = split(/[-]/,$locus1[1]); # having this split on "-" destroyes by construct gene name
		my @locus_info = ($locus1[0],@locus2);
		$Gene2Sample2Locus{$gene}->{$ID}=\@locus_info;
		my $fpkm = $record[9];
#		if ($record[10] > 0) {
			#Significantly above 0
			$Gene2Sample2FPKM{$gene}->{$ID}=$fpkm;
#		} else {
#			#Not significantly above 0
#			$Gene2Sample2FPKM{$gene}->{$ID} = 0;
#		}
	} close ($ifh);
} 

print STDERR "Done reading FPKMs\n";
# Now read in genome annotations
my %chr2exon2locus = ();
my %exon2gene = ();
my %chr2gene2locus = ();
my %transcript2gene = ();
my %Addedchr = ();
open (my $ifh, "/lustre/scratch108/compgen/team218/TA/genomebuilding/Mus_musculus.GRCm38.79.gtf") or die $!;
while (<$ifh>) {
	if ($_ =~ /^#/) {next;}
	my $geneid = "ERROR";
	if ($_ =~ /gene_id "(.+?)"/) {
		$geneid=$1;
	} else {
		die "No gene id!\n";
	}
	
	my @record = split(/\t/);
	my $locus =[$record[0],$record[3],$record[4]]; #anonymous array ref
	if ($record[1] eq "CLC" || $record[1] eq "ERCC") {
		$Addedchr{$record[0]} = 1;
		if (!exists($chr2gene2locus{$locus->[0]}->{$geneid}) ||
		    $chr2gene2locus{$locus->[0]}->{$geneid}->[2]-$chr2gene2locus{$locus->[0]}->{$geneid}->[1] < $locus->[2]-$locus->[1]) {
			$chr2gene2locus{$locus->[0]}->{$geneid} = $locus;
		}
		
	}
	if ($record[2] =~ /gene/i) {
		#gene
		$chr2gene2locus{$locus->[0]}->{$geneid} = $locus;
	} elsif ($_ =~ /exon_id "(.+?)"/) {
		#exon
#		$chr2exon2locus{$locus->[0]}->{$1} = $locus;
#		$exon2gene{$1}=$geneid;
	} elsif ($_ =~ /transcript_id "(.+?)"/) {
		#transcript
		$transcript2gene{$1}=$geneid;
	}
	
} close ($ifh);
print STDERR "Done reading Annotations\n";
# Second create a mapping for Cuff-GeneIDs to reference genes as much as possible
#	Rules: 
#		SCRAPPED: if an Cuff-Transcript exon perfectly matches a reference exon, assign the Cuff-GeneID to that gene - this is much more complicated to figure out because requires knowing transcript details rather than just gene locus
#		if the Cuff-Transcript overlaps a reference gene by at least 80% (reciprocal), assign the Cuff-GeneID to that gene
#		if the Cuff-Transcript overlaps the tail of a reference gene (extends past the reference 3' by < 10% of total reference length), assign the Cuff-GeneID to that gene
#		if the Cuff-Transcript is on an added Chr assign the Cuff-GeneID to any gene on that Chr with a +ve overlap
#		Keep the assigned gene with the largest overlap with the Cuff-Transcript.
# 9 Feb 2016 Edits: 
#		only require 80% olap of Cuff transcript not reciprocal 
#		change tail-condition to 50% of the Cuff-transcript olapping the gene locus
#		change "quality" of match from absolute olap to % of glocus olapped.
my $cuffsreplaced=0;

foreach my $g (keys(%Gene2Sample2Locus)) {
	if ($g !~ /CUFF/) {next;}
	foreach my $sample (keys(%{$Gene2Sample2Locus{$g}})) {
		my $currlocus = $Gene2Sample2Locus{$g}->{$sample};
		my $chr = $currlocus->[0];
		my %new_gene_ids = ();
		foreach my $gene (keys(%{$chr2gene2locus{$chr}})) {
			my $glocus = $chr2gene2locus{$chr}->{$gene};
			my $olap = olap($chr2gene2locus{$chr}->{$gene},$currlocus);
			if ($olap <= 0 ) {next;}
			if (exists($Addedchr{$chr})) {
				$new_gene_ids{$gene}=$olap/($glocus->[2]-$glocus->[1]);
			} elsif ($olap/($currlocus->[2]-$currlocus->[1]) >= 0.8) {
#			} elsif ($olap/($currlocus->[2]-$currlocus->[1]) >= 0.8 && $olap/($glocus->[2]-$glocus->[1]) >= 0.8) {
				$new_gene_ids{$gene}=$olap/($glocus->[2]-$glocus->[1]);
			} elsif ($currlocus->[1] < $glocus->[2] && $currlocus->[1] >= $glocus->[1] && (($currlocus->[2]-$currlocus->[1])-$olap)/($currlocus->[2]-$currlocus->[1]) < 0.5) {
#			} elsif ($currlocus->[1] < $glocus->[2] && $currlocus->[1] >= $glocus->[1] && (($currlocus->[2]-$currlocus->[1])-$olap)/($glocus->[2]-$glocus->[1]) < 0.1) {
				$new_gene_ids{$gene}=$olap/($glocus->[2]-$glocus->[1]);
			}
		}
		if (scalar(keys(%new_gene_ids)) == 0) {next;}
		my $bestolap = my_max(values(%new_gene_ids));
		my @bestmatches = ();
		foreach my $id (keys(%new_gene_ids)) { if ($new_gene_ids{$id} == $bestolap) {push(@bestmatches, $id);}}
		my $newgeneid = join(":", @bestmatches);
		
		$cuffsreplaced++;

		$Gene2Sample2FPKM{$newgeneid}->{$sample} += $Gene2Sample2FPKM{$g}->{$sample};
		delete($Gene2Sample2FPKM{$g}->{$sample});
			
	}
}
print STDERR "Cufflinks genes replaced = $cuffsreplaced\n";

sub my_max {
	my $max = shift(@_);
	foreach my $ele (@_) {if ($ele > $max) {$max = $ele;}}
	return($max);
}

sub olap {
	# Number of bases which overlap between two loci
	my ($locus1, $locus2) = @_;
	if ($locus1->[0] ne $locus2->[0]) {print STDERR "Loci on different chromosomes";return -1;} #on differ chromos
	my $olap = 0;
	# maximum of the minimum of the ends-maximum of the starts
	if ($locus1->[1] < $locus2->[1]) {
		#1 starts before 2
		if ($locus1->[2] < $locus2->[2]) {
			# 1 ends before 2
			$olap = $locus1->[2]-$locus2->[1];
		} else {
			#2 ends before 1
			$olap = $locus2->[2]-$locus2->[1];
		}
	} else {
		#2 starts before 1
		if ($locus1->[2] < $locus2->[2]) {
			# 1 ends before 2
			$olap=$locus1->[2]-$locus1->[1];
		} else {
			#2 ends before 1
			$olap=$locus2->[2]-$locus1->[1];
		}
	}
	if ($olap < 0) {$olap=0;}
	return $olap;
}


#my @files = glob("/lustre/scratch108/compgen/team218/TA/RNASeqFilesQuantified/*_isoforms.fpkm_tracking");	
#my %GeneID2SampleID2TranscriptID = ();
#my %Trans2ID2FPKM = ();
#foreach my $file (@files) {
#	$file =~ /([ATCG]{5,})/;
#	my $ID = $1;
#	open(my $ifh, $file) or die $!;
#	<$ifh>; # header
#	while (<$ifh>) {
#		chomp;
#		my @record = split(/\t/);
#		my $transcript = $record[0];
#		my $gene = $record[3];
#		$GeneID2SampleID2TranscriptID{$gene}->{$ID}->{$transcript}=1;
#		if ($record[10] > 0) {
#			#Significantly above 0
#			$Trans2ID2FPKM{$transcript}->{$ID} = $record[9];
#		} 
#	} close ($ifh);
#} 


#my @files = glob("/lustre/scratch108/compgen/team218/TA/RNASeqFilesQuantified/*_transcripts.gtf");    
#my %GeneID2SampleID2ParentalGeneID = (); #Parent is a reference transcript that this transcript overlaps the 3' end of (suggesting it is a fragment of the complete transcript)
#foreach my $file (@files) {
#        $file =~ /([ATCG]{5,})/;
#        my $ID = $1; 
#	my $parentgeneid="";
#	my @parentgenerecord = ();
#        open(my $ifh, $file) or die $!; 
#        while (<$ifh>) {
#                chomp;
#                my @record = split(/\t/);
#		if ($record[2] ne "transcript") {next;}
#		my $extrastuff = pop(@record);
#		$extrastuff =~ /gene_id "(.+?)"/;
#		my $geneid=$1;
#                my $transcript = $record[0];
#                my $gene = $record[3];
#                $GeneID2SampleID2TranscriptID{$gene}->{$ID}->{$transcript}=1;
#                if ($record[10] > 0) {
#                        #Significantly above 0
#                        $Trans2ID2FPKM{$transcript}->{$ID} = $record[9];
#                }   
#        } close ($ifh);
#} 


open (my $ofh, ">", $outfile) or die $!;
my @IDs = sort(keys(%AllSamples));
print $ofh "Gene\t".join("\t",@IDs)."\n";

foreach my $gene (keys(%Gene2Sample2FPKM)) {
	if ($gene =~ /CUFF/) {next;}
	print $ofh "$gene";
	foreach my $ID (@IDs) {
                 my $count = "NA";
                 if (exists($Gene2Sample2FPKM{$gene}->{$ID})) {
                         $count = $Gene2Sample2FPKM{$gene}->{$ID};
                 } else {
                         $count = "0";
                 }
                 print $ofh "\t".$count;
         }
         print $ofh "\n";
}
close($ofh);
