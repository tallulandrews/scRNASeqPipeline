#!/bin/bash
# Tallulah 3 Nov 2016 : wrapper for Mapping Reads with SALMON -> to be called from a job-array bsub command.
# Note job array requires indexing to start at 1 but array indexing starts at 0
# Maps paired reads only!

# Arguments: 
#    $1 = number of threads to run on, 
#    $2 = directory of files to map
#    $3 = outputdirectory
#    $4 = transcript index file (see 0.3_Salmon_build_index.sh)
#    $5 = annotation gtf (map transcripts to genes)

NUMTHREADS=$1
FILESTOMAPDIR=$2
OUTDIR=$3
INFILE=$4
ANNFILE=$5
SALMON=/nfs/users/nfs_t/ta6/RNASeqPipeline/software/Salmon-0.7.2_linux_x86_64/bin/salmon

#Check appropriate arguments
if [ ! -f "$SALMON" ] ; then
  echo "Sorry SALMON not available "
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

NAME=${FILE1TOMAP##*/}
NAME=${NAME%.*}

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

if [ -z "$INFILE" ] ; then
  echo "Please include a transcript index file (ARG 4/4)"
  exit 1
fi

# Make directory for output if necessary
if [ ! -d "$OUTDIR" ] ; then
  mkdir -p $OUTDIR
fi
if [ ! -d "$OUTDIR/$LSB_JOBINDEX" ] ; then
  mkdir -p $OUTDIR/$LSB_JOBINDEX
fi

# Run SALMON 
$SALMON quant -i $INFILE -o $OUTDIR/$LSB_JOBINDEX -1 $FILE1TOMAP -2 $FILE2TOMAP -p $NUMTHREADS -l A -g $ANNFILE --seqBias --gcBias --posBias -q
mv $OUTDIR/$LSB_JOBINDEX/quant.sf $OUTDIR/$NAME.quant.sf
mv $OUTDIR/$LSB_JOBINDEX/quant.genes.sf $OUTDIR/$NAME.quant.genes.sf
rm -r $OUTDIR/$LSB_JOBINDEX
