#!/bin/bash
# Tallulah 31 Mar 2015 : wrapper for Mapping Reads with STAR -> to be called from a job-array bsub command.
# Note job array requires indexing to start at 1 but array indexing starts at 0
# Maps paired reads only!

## Haven't tested since moved genomedir out of parameterfile

# Arguments: 
#    $1 = directory of files to map
#    $2 = outputdirectory
#    $3 = Prefix
#    $4 = Method

FILESTOMAPDIR=$1
OUTDIR=$2
PREFIX=$3
METHOD=$4
DIST_THRESH=0
UMITOOLS=/nfs/users/nfs_t/ta6/RNASeqPipeline/software/dedup_umi.py

#Check appropriate arguments
if [ ! -f "$UMITOOLS" ] ; then
  echo "Sorry UMI-tools not available "
  exit 1
fi

if [ -z "$FILESTOMAPDIR" ] ; then
  echo "Please include a directory of files to map (ARG 1/3)"
  exit 1
fi
MYFILES=($FILESTOMAPDIR/*.bam)
ARRAYINDEX=$((($LSB_JOBINDEX-1)))
MYFILE=${MYFILES[$ARRAYINDEX]} #Note bash array indicies start at 0 but job array indices must start at 1!!!
echo $FILESTOMAPDIR
echo $ARRAYINDEX
echo ${#MYFILES[@]}
echo $MYFILE
if [ -z "$MYFILE" ] ; then
  echo "$MYFILE the $ARRAYINDEX-th file in the $FILESTOMAPDIR does not exist."
  exit 1
fi

if [ -z "$OUTDIR" ] ; then
  echo "Please include a directory for output (ARG 2/3)"
  exit 1
fi

if [ -z "$PREFIX" ] ; then
  echo "Warning: no file prefix included"
fi

# Make directory for output if necessary
if [ ! -d "$OUTDIR" ] ; then
  mkdir -p $OUTDIR
fi

# Run STAR 
FILEnopath=`basename ${MYFILE%.bam}`
/usr/bin/python $UMITOOLS $MYFILE $DIST_THRESH $OUTDIR/$PREFIX-$FILEnopath.bam $METHOD
