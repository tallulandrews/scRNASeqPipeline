use strict;
use warnings;

if (scalar(@ARGV) < 1 || $ARGV[0] !~ /gbk$/) {die "Did not provide GBK file."}

my $sequence = "";
my $chrname = "";
my $file = $ARGV[0];

open (my $ifh, $file) or die $!;
my $seq_started = 0;
my $st = 0;
my $end = 0;
my $name = "";
my %Items = ();
my $geneid = 0;
my %Gene_info=();
while (<$ifh>) {
	if ($_ =~/Promoter/) {
		$geneid++;
	}
	if ($_ =~ /feature\s+(\d+)\.\.(\d+)/){
		$st = $1;
		$end = $2;
	}
	if ($_ =~ /\/label=(.+)\s+$/) {
		$name=$1;
		$name =~ s/\s//g;
		$Items{$geneid}->{"$st\t$end"} = $name;
		if (!exists($Gene_info{$geneid}->{"st"}) || $st < $Gene_info{$geneid}->{"st"}) {
			$Gene_info{$geneid}->{"st"} = $st;
		}
		if (!exists($Gene_info{$geneid}->{"end"}) || $end > $Gene_info{$geneid}->{"end"}) {
			$Gene_info{$geneid}->{"end"} = $end;
		}
	}
		
	if ($_ =~ /^LOCUS/) {
		my @record = split(/\s+/);
		$chrname = $record[1];
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
		$sequence .= $seq;
	}
} close($ifh);

$file =~ s/gbk$/gtf/;
open (my $ofh, ">", $file) or die $!;
foreach my $gene (sort(keys(%Items))) {
	print $ofh "$chrname\tGBK\tgene\t".$Gene_info{$gene}->{"st"}."\t".$Gene_info{$gene}->{"end"}."\t.\t+\t.\tgene_id \"Gene$gene\"; transcript_id \"Transcript$gene\"; gene_name \"Gene$gene\"; gene_source \"GBK\";\n";
	my $exon_num=0;
	foreach my $exon (sort(keys(%{$Items{$gene}}))) {
		$exon_num++;
		print $ofh "$chrname\tGBK\texon\t$exon\t.\t+\t.\tgene_id \"Gene$gene\"; transcript_id \"Transcript$gene\"; exon_number \"$exon_num\"; gene_name \"Gene$gene\"; transcript_name \"Transcript$gene\"; gene_source \"GBK\"; exon_name \"".$Items{$gene}->{$exon}."\";\n";
	}
}
close($ofh);

$file =~ s/gtf$/fa/;
open ($ofh, ">", $file) or die $!;
print $ofh ">$chrname\n$sequence";
close($ofh);

