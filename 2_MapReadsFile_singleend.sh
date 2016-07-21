#!/bin/bash
# Tallulah 31 Mar 2015 : wrapper for Mapping Reads with STAR -> to be called from a job-array bsub command.
# Note job array requires indexing to start at 1 but array indexing starts at 0
# Maps paired reads only!

# Arguments: 
#    $1 = number of threads to run on, 
#    $2 = directory of files to map
#    $3 = outputdirectory
#    $4 = STAR Parameters file
#    $5 = STAR Genome directory
#    $6 = Prefix

NUMTHREADS=$1
FILESTOMAPDIR=$2
OUTDIR=$3
STAR=/nfs/users/nfs_t/ta6/RNASeqPipeline/software/STAR-STAR_2.4.0j/bin/Linux_x86_64_static/STAR
PARAMFILE=$4
PREFIX="$6-$LSB_JOBINDEX-"
WORKINGDIR=/lustre/scratch108/compgen/team218/TA/Pipeline_RunningDir/STAR/$PREFIX
GENOME=$5

#Check appropriate arguments
if [ ! -f "$STAR" ] ; then
  echo "Sorry STAR not available "
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
ARRAYINDEX=$((($LSB_JOBINDEX-1)))
FILE1TOMAP=${FILEStoMAP[$ARRAYINDEX]} #Note bash array indicies start at 0 but job array indices must start at 1!!!

if [ -z "$FILE1TOMAP" ] ; then
  echo "$ARRAYINDEX-th file in the $FILESTOMAPDIR does not exist."
  exit 1
fi

if [ -z "$OUTDIR" ] ; then
  echo "Please include a directory for output (ARG 3/4)"
  exit 1
fi

if [ -z "$PARAMFILE" ] ; then
  echo "Please include a parameter file (ARG 4/4)"
  exit 1
fi

if [ -z "$5" ] ; then
  echo "Warning: no file prefix included"
fi

# Make directory for output if necessary
if [ ! -d "$OUTDIR" ] ; then
  mkdir -p $OUTDIR
fi

# Run STAR 
if [[ $FILE1TOMAP =~ \.gz$ ]] ; then
    FILEnopath=`basename ${FILE1TOMAP%.fq.gz}`
    $STAR --runThreadN $NUMTHREADS --runMode alignReads --readFilesIn $FILE1TOMAP --genomeDir $GENOME --readFilesCommand zcat --parametersFiles $PARAMFILE --outFileNamePrefix $OUTDIR/$FILEnopath --outTmpDir $WORKINGDIR
else
    FILEnopath=`basename ${FILE1TOMAP%.fq}`
    $STAR --runThreadN $NUMTHREADS --runMode alignReads --readFilesIn $FILE1TOMAP --genomeDir $GENOME --parametersFiles $PARAMFILE --outFileNamePrefix $OUTDIR/$FILEnopath --outTmpDir $WORKINGDIR
fi
