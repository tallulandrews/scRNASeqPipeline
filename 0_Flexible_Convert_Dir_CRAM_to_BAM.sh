#!/bin/bash
# Designed for LSF job arrays

export REF_CACHE=/lustre/scratch117/cellgen/team218/TA/TemporaryFileDir
SAMTOOLS=/nfs/users/nfs_t/ta6/RNASeqPipeline/software/CRAM/samtools-1.3.1/samtools
#LSB_JOBINDEX=$3 # specify which file to run on
FILEINDEX=$LSB_JOBINDEX
DIR=$1
OUTDIR=$2
FILE="$DIR/*_$FILEINDEX.cram"

#LANE8="/warehouse/team218_wh01/MH/LBHsLiverData/21698/Lane8/21698_8_$FILEINDEX.cram"

OUTDIR=/lustre/scratch117/cellgen/team218/TA/LiverOrganoids/BAMS

FILE1=$(basename $FILE)

cp $FILE $OUTDIR/$FILE1

$SAMTOOLS view -b -h $OUTDIR/$FILE1 -o $OUTDIR/$FILE1.bam

rm $OUTDIR/$FILE1
