#!/bin/bash

export REF_CACHE=/lustre/scratch117/cellgen/team218/TA/TemporaryFileDir
SAMTOOLS=/nfs/users/nfs_t/ta6/RNASeqPipeline/software/CRAM/samtools-1.3.1/samtools

OUTDIR=$1
INPUTDIR=$2

FILEStoMAP=($INPUTDIR/*.bam)
ARRAYINDEX=$(($LSB_JOBINDEX-1))
INPUTBAM=${FILEStoMAP[$ARRAYINDEX]}
OUTFILE=$(basename $FILE).meta

$SAMTOOLS -H $INPUTBAM > $OUTDIR/$OUTFILE
