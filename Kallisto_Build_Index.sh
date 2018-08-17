#!/bin/bash
# Build Kallisto Index from a reference fasta and gtf.
USAGE="Usage: Kallisto_Build_Index.sh ref.fa ref.gtf outdir\n
	\tArguments:\n
	\t ref.fa = reference fasta file\n
	\t ref.gtf = reference GTF file\n
	\t outdir = directory for output\n"

# Locations of required software
GFFREAD=/nfs/users/nfs_t/ta6/RNASeqPipeline/software/cufflinks-2.2.1.Linux_x86_64/gffread
KALLISTO=/nfs/users/nfs_t/ta6/RNASeqPipeline/software/kallisto_linux-v0.42.4/kallisto

# Raw genome fasta and annotation gtf
FA=$1
GTF=$2

# Location for output files
OUTDIR=$3

# Checks
if [ ! -f $GFFREAD ] ; then
  echo "Error: gffread not available"
  exit 1
fi

if [ ! -f $KALLISTO ] ; then
  echo "Error: kallisto not available"
  exit 1
fi

if [ -z $FA ] || [ ! -f $FA ] ; then
  echo -e $USAGE
  exit 1
fi

if [ -z $GTF ] || [ ! -f $GTF ] ; then
  echo -e $USAGE
  exit 1
fi


if [ -z $OUTDIR ] ; then
  OUTDIR=./
fi

# Extract transcriptome fasta using gffread
$GFFREAD $GTF -g $FA -w $OUTDIR/Transcripts.fasta

# Index the extracted transcriptome
$KALLISTO index -i $OUTDIR/kallisto_index.idx $OUTDIR/Transcripts.fasta

