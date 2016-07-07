#!/bin/bash
# Tallulah 31 Mar 2015 : wrapper for Mapping Reads with TOPHAT -> to be called from a job-array bsub command.
# Note job array requires indexing to start at 1 but array indexing starts at 0
# Maps paired reads only!

# Arguments: 
#    $1 = number of threads to run on, 
#    $2 = directory of files to map
#    $3 = outputdirectory
#    $4 = genome base
#    $5 = Prefix

NUMTHREADS=$1
FILESTOMAPDIR=$2
OUTDIR=$3
TOPHAT=/nfs/users/nfs_t/ta6/RNASeqPipeline/software/tophat-2.1.0.Linux_x86_64/tophat2
GENOME=$4
PREFIX="$5-$LSB_JOBINDEX-"
WORKINGDIR=/lustre/scratch108/compgen/team218/TA/TemporaryFileDir/$PREFIX

#Check appropriate arguments
if [ ! -f "$TOPHAT" ] ; then
  echo "Sorry TOPHAT not available "
  exit 1
fi

if [ -z "$NUMTHREADS" ] ; then
  echo "Please set number of threads to use (ARG 1/4)"
  exit 1
fi

if [ -z "$FILESTOMAPDIR" ] ; then
  echo "Please include a directory of files to map (ARG 2/4)"
  exit 1
fi
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

if [ -z "$OUTDIR" ] ; then
  echo "Please include a directory for output (ARG 3/4)"
  exit 1
fi

if [ -z "$GENOME" ] ; then
  echo "Please include the base genome name (ARG 4/4)"
  exit 1
fi

if [ -z "$5" ] ; then
  echo "Warning: no file prefix included"
fi

#To fix failed jobs
if [ -d "$OUTDIR/$LSB_JOBINDEX" ]; then
#-----------------

# Make directory for output if necessary
if [ ! -d "$OUTDIR/$LSB_JOBINDEX" ] ; then
  mkdir -p $OUTDIR/$LSB_JOBINDEX
fi

NAME=${FILE1TOMAP##*/}
NAME=${NAME%.*}

echo "Job$LSB_JOBINDEX Mapping: $FILE1TOMAP $FILE2TOMAP\n"

# Run TOPHAT 
FILEnopath=`basename ${FILE1TOMAP%.fq.gz}`
cd $OUTDIR/$LSB_JOBINDEX
$TOPHAT $GENOME $FILE1TOMAP $FILE2TOMAP

mv $OUTDIR/$LSB_JOBINDEX/tophat_out/align_summary.txt $OUTDIR/$NAME.align_summary.txt
/usr/bin/samtools merge -n -f $OUTDIR/$NAME.sorted.aligned.bam $OUTDIR/$LSB_JOBINDEX/tophat_out/accepted_hits.bam $OUTDIR/$LSB_JOBINDEX/tophat_out/unmapped.bam
rm -r $OUTDIR/$LSB_JOBINDEX

#To fix failed jobs
fi
#-----------------
