#!/bin/bash
# Initial QC
FASTQFILEDIR=$1
FASTQFILEPATTERN=$2
OUTNAME=$3 #outputfilenames
OUTPUTDIR=$4 #directory for outputfiles
FASTQC=/nfs/users/nfs_t/ta6/RNASeqPipeline/software/FastQC/fastqc
LIMITFILE=/nfs/users/nfs_t/ta6/RNASeqPipeline/0_FASTQC_limits.txt
# There is also the -o for an appropriate output directory

if [ -z "$FASTQFILEDIR" ] ; then
  echo "Please provide a directory of fastq files (Argument 1/4)"
  exit 1
fi
if [ -z "$FASTQFILEPATTERN" ] ; then
  echo "Please provide a pattern to select fastq files with (Argument 2/4) "
  exit 1
fi

if [ -z "$OUTNAME" ] ; then
  echo "Please provide name for output files (Argument 3/4) "
  exit 1
fi

if [ -z "$OUTPUTDIR" ] ; then
  echo "Please provide a directory to put output in (Argument 4/4) "
  exit 1
fi

if [ ! -f "$FASTQC" ] ; then
  echo "Sorry FASTQC not available "
  exit 1
fi

mkdir -p $OUTPUTDIR

export _JAVA_OPTIONS="-Xmx10000M -XX:MaxHeapSize=10000m"
#zcat $FASTQFILEDIR/$FASTQFILEPATTERN | $FASTQC -l $LIMITFILE --quiet $FASTQFILE -o $OUTPUTDIR stdin
cat $FASTQFILEDIR/$FASTQFILEPATTERN | $FASTQC -l $LIMITFILE --quiet $FASTQFILE -o $OUTPUTDIR stdin
mv $OUTPUTDIR/stdin_fastqc.html $OUTPUTDIR/FASTQC_$OUTNAME.html
mv $OUTPUTDIR/stdin_fastqc.zip $OUTPUTDIR/FASTQC_$OUTNAME.zip
