#!/bin/bash
# Initial QC
INPUTDIR=$1 #directory of inputfiles
OUTPUTDIR=$2 #directory for outputfiles
TRIMMER=/nfs/users/nfs_t/ta6/RNASeqPipeline/software/Trimmomatic-0.36/trimmomatic-0.36.jar
# There is also the -o for an appropriate output directory

if [ -z "$INPUTDIR" ] ; then
  echo "Please provide an input directory of fastq files (Argument 1/2)"
  exit 1
fi
if [ -z "$OUTPUTDIR" ] ; then
  echo "Please provide a directory for outputfiles (Argument 2/2)"
  exit 1
fi

if [ ! -f "$TRIMMER" ] ; then
  echo "Sorry $TRIMMER not available "
  exit 1
fi

mkdir -p $OUTPUTDIR
FILES=($INPUTDIR/*.fq)
ARRAYINDEX=$((($LSB_JOBINDEX-1)))
INPUTFILE=${FILES[$ARRAYINDEX]}
FILEnopath=`basename ${INPUTFILE%.fq}`
OUTPUTFILE="$OUTPUTDIR/TRIMMED-$FILEnopath.fq"

export _JAVA_OPTIONS="-Xmx1000M -XX:MaxHeapSize=1000m"
#java -jar $TRIMMER SE -phred33 $INPUTFILE $OUTPUTFILE ILLUMINACLIP:/nfs/users/nfs_t/ta6/RNASeqPipeline/software/Trimmomatic-0.36/adapters/NexteraPE-PE.fa:2:30:10 LEADING:3 TRAILING:3 SLIDINGWINDOW:4:20 MINLEN:20
java -jar $TRIMMER SE -phred33 $INPUTFILE $OUTPUTFILE ILLUMINACLIP:/nfs/users/nfs_t/ta6/RNASeqPipeline/software/Trimmomatic-0.36/adapters/NexteraPE-PE.fa:2:30:10 LEADING:3 TRAILING:3 SLIDINGWINDOW:4:20 MINLEN:50
