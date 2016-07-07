#!/usr/bin/perl

# Downloaded from: https://code.google.com/p/ea-utils/source/browse/trunk/clipper/gtf2bed on 9 April 2015
# Based on suggestion from: http://onetipperday.blogspot.com/2012/08/convert-bed-to-gtf.html

# Copyright (c) 2011 Erik Aronesty (erik@q32.com)
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
# 
# ALSO, IT WOULD BE NICE IF YOU LET ME KNOW YOU USED IT.

use Data::Dumper;
use Getopt::Long;


my $extended;
GetOptions("x"=>\$extended);

$in = shift @ARGV;

if (!defined($in) || $in eq "" || !-e $in) {die "No input file provided $!\n";}

my $in_cmd =($in =~ /\.gz$/ ? "gunzip -c $in|" : $in =~ /\.zip$/ ? "unzip -p $in|" : "$in") || die "Please provide valid gtf (or compressed gtf) file, Can't open $in: $!\n";
open IN, $in_cmd;

while (<IN>) {
	$gff = 2 if /^##gff-version 2/;
	$gff = 3 if /^##gff-version 3/;
	next if /^#/ && $gff;

	s/\s+$//;
	# 0-chr 1-src 2-feat 3-beg 4-end 5-scor 6-dir 7-fram 8-attr
	my @f = split /\t/;
# Tallulah's Modifications:
	($transid) = $f[8]=~ /transcript_id "([^"]+)"/;
	($geneid) = $f[8]=~ /gene_id "([^"]+)"/;
	($gene_type) = $f[8]=~ /gene_biotype "([^"]+)"/;
	($gene_name) = $f[8]=~ /gene_name "([^"]+)"/;
	($trans_type) = $f[8]=~ /transcript_biotype "([^"]+)"/;
	$id="${gene_name}__${geneid}__${transid}__${gene_type}.${trans_type}";
#	if ($gff) {
#        # most ver 2's stick gene names in the id field
#		($id) = $f[8]=~ /\bID="([^"]+)"/;
#        # most ver 3's stick unquoted names in the name field
#		($id) = $f[8]=~ /\bName=([^";]+)/ if !$id && $gff == 3;
#	} else {
#		($id) = $f[8]=~ /transcript_id "([^"]+)"/;
#	}
# End of Modifications ---

	next unless $id && $f[0];

	if ($f[2] eq 'exon') {
		die "no position at exon on line $." if ! $f[3];
        # gff3 puts :\d in exons sometimes
        $id =~ s/:\d+$// if $gff == 3;
		push @{$exons{$id}}, \@f;
		# save lowest start
		$trans{$id} = \@f if !$trans{$id};
	} elsif ($f[2] eq 'start_codon') {
		#optional, output codon start/stop as "thick" region in bed
		$sc{$id}->[0] = $f[3];
	} elsif ($f[2] eq 'stop_codon') {
		$sc{$id}->[1] = $f[4];
	} elsif ($f[2] eq 'miRNA' ) {
		$trans{$id} = \@f if !$trans{$id};
		push @{$exons{$id}}, \@f;
	}
}

for $id ( 
	# sort by chr then pos
	sort {
		$trans{$a}->[0] eq $trans{$b}->[0] ? 
		$trans{$a}->[3] <=> $trans{$b}->[3] : 
		$trans{$a}->[0] cmp $trans{$b}->[0]
	} (keys(%trans)) ) {
		my ($chr, undef, undef, undef, undef, undef, $dir, undef, $attr, undef, $cds, $cde) = @{$trans{$id}};
        my ($cds, $cde);
        ($cds, $cde) = @{$sc{$id}} if $sc{$id};

		# sort by pos
		my @ex = sort {
			$a->[3] <=> $b->[3]
		} @{$exons{$id}};

		my $beg = $ex[0][3];
		my $end = $ex[-1][4];
		
		if ($dir eq '-') {
			# swap
			$tmp=$cds;
			$cds=$cde;
			$cde=$tmp;
			$cds -= 2 if $cds;
			$cde += 2 if $cde;
		}

		# not specified, just use exons
		$cds = $beg if !$cds;
		$cde = $end if !$cde;

		# adjust start for bed
		--$beg; --$cds;
	
		my $exn = @ex;												# exon count
		my $exst = join ",", map {$_->[3]-$beg-1} @ex;				# exon start
		my $exsz = join ",", map {$_->[4]-$_->[3]+1} @ex;			# exon size

        my $gene_id;
        my $extend = "";
        if ($extended) {
    	    ($gene_id) = $attr =~ /gene_name "([^"]+)"/;
    	    ($gene_id) = $attr =~ /gene_id "([^"]+)"/ unless $gene_id;
            $extend="\t$gene_id";
        }
		# added an extra comma to make it look exactly like ucsc's beds
		print "$chr\t$beg\t$end\t$id\t0\t$dir\t$cds\t$cde\t0\t$exn\t$exsz,\t$exst,$extend\n";
}


close IN;
