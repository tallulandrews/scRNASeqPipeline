Mapping Reads to ERCC Control Sequences with BioScope 1.2.1 
------------------------------------------------------------

This document describes how to use BioScope 1.2.1 to map the results
of a SOLiD run containing ERCC control sequences against the ERCC
reference using the BioScope Whole Transcriptome Pipeline.

Once a SOLiD run containing ERCC control sequences is finished, the
results must be mapped and counted against the ERCC reference files.
This can be accomplished in two ways using BioScope 1.2.1, by
combining the ERCC references with the genome references or by mapping
directly to the ERCC references.  

Both methods are described below.


Prerequisites
-------------

BioScope 1.2.1 is required to map against the ERCC references.  If you
have an older version of BioScope, upgrade to 1.2.1 before proceeding.  

Two ERCC references are required for mapping and counting:

ERCC92.fa 
  This multi-fasta file contains the reference sequences and IDs for
  each ERCC control sequence.   

ERCC92.gtf 
  This feature file contains feature entries for each ERCC control
  sequence.  This is used as the exon reference in the Whole
  Transcriptome pipeline. 

Both ERCC reference files can be downloaded from:
  www.appliedbiosystems.com.


Method 1: Mapping ERCCs Directly to the ERCC References
--------------------------------------------------------

1. Run BioScope 1.2.1 whole transcriptome analysis as directed in the 
   BioScope documentation.  Use ERCC92.fa for the genome reference and
   ERCC92.gtf for the exon reference.

2. When the BioScope run completes, you will find the ERCC counts in
   the last 92 lines of the countagresult.txt file. 


Method 2: Combining the ERCC References with the Genomic References 
-------------------------------------------------------------------

Combining the references allows you to map to both the ERCCs and the
genome reference at the same time.  This is accomplished by appending
the ERCC references to the genome references. 

Follow these steps to combine the references:

1. Prepare your genome and feature references for use with BioScope
   1.2.1.  For human references, you might have two reference files:

   human.fa - the multi-fasta file contain the human reference genome 
   refGene.gtf - the exon reference file for each exon in refseq   

2. Append the ERCC references to the genome and feature references.
   If your genome reference is human.fa and your exon reference is
   refGene.gtf then you could use the following UNIX commands from a
   Bash shell to append the files (note that $ is the command prompt):    

  $ cat ERCC92.fa >> human.fa 
  $ cat ERCC92.gtf >> refGene.gtf

3. Run BioScope 1.2.1 whole transcriptome analysis as directed in the
   BioScope documentation.

4. When the BioScope run completes, you will find the ERCC counts in
   the last 92 lines of the countagresult.txt file. 


Post-Processing: Extracting Counts to a Tab-delimited File
----------------------------------------------------------

You can use the following UNIX commands from a Bash shell to parse the
results into a tab delimited table (ERCC.counts) of ERCC name, raw
read count and RPKM:

  $ tail -n 92 countagresult.txt | cut -f9 | cut -d';' -f1 | sed 's/gene_id\|"\| //g' > gene_id
  $ tail -n 92 countagresult.txt | cut -f6 > raw_count
  $ tail -n 92 countagresult.txt | cut -f9 | cut -d';' -f3 | sed 's/RPKM\|"\| //g' > RPKM
  $ paste gene_id raw_count RPKM > ERCC.counts
  $ rm gene_id raw_count RPKM


