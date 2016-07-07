#!/bin/bash
# Initial QC
FASTQFILE=$1
FASTQC=/nfs/users/nfs_t/ta6/RNASeqPipeline/software/FastQC/fastqc
LIMITFILE=/nfs/users/nfs_t/ta6/RNASeqPipeline/0_FASTQC_limits.txt
# There is also the -o for an appropriate output directory

if [ ! -f "$FASTQFILE" ] ; then
  echo "Sorry $FASTQFILE does not exist "
  exit 1
fi

if [ ! -f "$FASTQC" ] ; then
  echo "Sorry FASTQC not available "
  exit 1
fi

export _JAVA_OPTIONS="-Xmx100M -XX:MaxHeapSize=100m"
$FASTQC -l $LIMITFILE --quiet $FASTQFILE 


#If you want to run fastqc on a stream of data to be read from standard input then you
#can do this by specifing 'stdin' as the name of the file to be processed and then 
#streaming uncompressed fastq format data to the program.  For example:

#zcat *fastq.gz | fastqc stdin
#zcat C*.gz | /nfs/users/nfs_t/ta6/RNASeqPipeline/software/FastQC/fastqc -o placeforoutputfiles/ stdin

# ^^ This is probably the best approach to use in many of my cases since this allows on the fly combining of various files without storing duplicated data.
