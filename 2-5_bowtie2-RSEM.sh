#!/bin/bash
# Assume paired end
# Arguments:
# $1 = directory of fastq files to map/quantify
# $2 = output directory for final quantification file
# $3 = prefix
# $4 = number of threads to run on (optional)
RSEM=/nfs/users/nfs_t/ta6/RNASeqPipeline/software/RSEM-1.2.26/rsem-calculate-expression
BOWTIE=/nfs/users/nfs_t/ta6/RNASeqPipeline/software/bowtie2-2.2.6/
#REFname=/lustre/scratch108/compgen/team218/TA/STRIPED_GENOMES/RSEM/GRCm38
REFname=/lustre/scratch108/compgen/team218/TA/STRIPED_GENOMES/RSEM/GRCm38
FILESTOMAPDIR=$1
OUTDIR=$2
PREFIX="$3-$LSB_JOBINDEX-"
THREADS=$4
WORKINGDIR=/lustre/scratch108/compgen/team218/TA/TemporaryFileDir/$PREFIX

if [ -z "$THREADS" ] ; then
  THREADS=1
fi
if [ ! -f "$RSEM" ] ; then
  echo "Sorry RSEM not available "
  exit 1
fi
if [ -z "$FILESTOMAPDIR" ] ; then
  echo "Please include a directory of files to map (ARG 1/4)"
  exit 1
fi
if [ -z "$OUTDIR" ] ; then
  echo "Please include a directory for outputfile (ARG 2/4)"
  exit 1
fi
if [ -z "$3" ] ; then
  echo "Please include a prefix for output (ARG 3/4)"
  exit 1
fi

# Get fastq files
FILEStoMAP=($FILESTOMAPDIR/*)
ARRAYINDEX=$((($LSB_JOBINDEX-1)*2))
FILE1TOMAP=${FILEStoMAP[$ARRAYINDEX]} #Note bash array indicies start at 0 but job array indices must start at 1!!!
FILE2TOMAP=${FILEStoMAP[$ARRAYINDEX+1]} #Note bash array indicies start at 0 but job array indices must start at 1!!!

if [ -z "$FILE1TOMAP" ] ; then
  echo "$ARRAYINDEX-th file in the $FILESTOMAPDIR does not exist."
  exit 1
fi

if [ -z "$FILE2TOMAP" ] ; then
  echo "$ARRAYINDEX+1-th file in the $FILESTOMAPDIR does not exist."
  exit 1
fi
# Make directory for output if necessary
if [ ! -d "$OUTDIR" ] ; then
  mkdir -p $OUTDIR
fi

$RSEM --bowtie2 --bowtie2-path $BOWTIE --no-bam-output --single-cell-prior --temporary-folder $WORKINGDIR --paired-end -p $THREADS $FILE1TOMAP $FILE2TOMAP $REFname $OUTDIR/$PREFIX
