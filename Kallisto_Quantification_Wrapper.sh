#!/bin/bash
# Note job array requires indexing to start at 1 but array indexing starts at 0
# Maps paired reads only!

USAGE="Usage: Kallisto_Quantification_Wrapper.sh index threads file1 file2 outdir\n
	\tArguments:\n
	\tfile1 = either fastq for read1 or if running in jobarray directory of fasta files\n
	\tfile2 = either fastq for read2 or if running in jobarray \"NULL\" or for single-end\n
	\tindex = kallisto index (see: Kallisto_Build_Index.sh)\n
	\tthreads = number of cpus to use\n
	\toutdir = directory for output (default: current working directory)\n"

KALLISTO=/nfs/users/nfs_t/ta6/RNASeqPipeline/software/kallisto_linux-v0.42.4/kallisto
JOB_INDEX=$LSB_JOBINDEX # for array jobs, index starts at 1.

FILE1=$1
FILE2=$2
KALLISTO_INDEX=$3
NUMTHREADS=$4
OUTDIR=$5

#Check appropriate arguments
if [ ! -f "$KALLISTO" ] ; then
  echo "Error: kallisto not available "
  exit 1
fi

if [ -z "$NUMTHREADS" ] ; then
  echo -e $USAGE
  exit 1
fi

if [ -z "$KALLISTO_INDEX" ] ; then
  echo -e $USAGE
  exit 1
fi

if [ -z "$FILE1" ] ; then
  echo -e $USAGE
  exit 1
fi

# allow running in unpaired mode
#if [ -z "$FILE2" ] ; then 
#  echo -e $USAGE
#  exit 1
#fi

if [ -z "$OUTDIR" ] ; then
  OUTDIR=./
fi

# Set-up for either array job or for loop
if [ $FILE2 == "NULL" ] && [ $JOB_INDEX -gt 0 ]; then
	echo "ArrayJob"
	echo $JOB_INDEX
	FILEStoMAP=($FILE1/*)
	ARRAYINDEX=$((($JOB_INDEX-1)*2))
	FILE1=${FILEStoMAP[$ARRAYINDEX]} #Bash array indicies start at 0
	FILE2=${FILEStoMAP[$ARRAYINDEX+1]} #Bash array indicies start at 0 
fi

if [ ! -d "$OUTDIR" ] ; then
  mkdir -p $OUTDIR
fi

if [ -z "$FILE1" ] || [ ! -f "$FILE1" ] ; then
  echo "$FILE1 does not exist."
  exit 1
fi

# allow running in unpaired mode
#if [ -z "$FILE2" ] || [ ! -f "$FILE2" ] ; then
#  echo "$FILE2 does not exist."
#  exit 1
#fi

NAME=${FILE1##*/}
NAME=${NAME%.*}
WORKDIR=$OUTDIR/$NAME

# Make directory for temporary output
if [ ! -d "$WORKDIR" ] ; then
  mkdir -p $WORKDIR
fi

# Run KALLISTO 
if [ -f $FILE2 ] ; then
  $KALLISTO quant --bias --plaintext --threads=$NUMTHREADS -i $KALLISTO_INDEX -o $WORKDIR $FILE1 $FILE2
else 
  $KALLISTO quant --single --fragment-length=100 --sd=20 --bias --plaintext --threads=$NUMTHREADS -i $KALLISTO_INDEX -o $WORKDIR $FILE1
fi
mv $WORKDIR/abundance.tsv $OUTDIR/$NAME.kallisto.abundances.tsv
rm $WORKDIR/run_info.json
rmdir $WORKDIR

