#!/bin/bash

export REF_CACHE=/lustre/scratch117/cellgen/team218/TA/TemporaryFileDir
CRAMTOOLS=/nfs/users/nfs_t/ta6/RNASeqPipeline/software/CRAM/cramtools-3.0/cramtools-3.0.jar
SAMTOOLS=/nfs/users/nfs_t/ta6/RNASeqPipeline/software/CRAM/samtools-1.3.1/samtools
FILEINDEX=$LSB_JOBINDEX
LANE6="/warehouse/team218_wh01/MH/LBHsLiverData/21698/Lane6/21698_6_$FILEINDEX.cram"
LANE7="/warehouse/team218_wh01/MH/LBHsLiverData/21698/Lane7/21698_7_$FILEINDEX.cram"
LANE8="/warehouse/team218_wh01/MH/LBHsLiverData/21698/Lane8/21698_8_$FILEINDEX.cram"

OUTDIR=/lustre/scratch117/cellgen/team218/TA/LiverOrganoids/BAMS

FILE1=$(basename $LANE6)
FILE2=$(basename $LANE7)
FILE3=$(basename $LANE8)

cp $LANE6 $OUTDIR/$FILE1
cp $LANE7 $OUTDIR/$FILE2
cp $LANE8 $OUTDIR/$FILE3

$SAMTOOLS view -b -h $OUTDIR/$FILE1 -o $OUTDIR/$FILE1.bam
$SAMTOOLS view -b -h $OUTDIR/$FILE2 -o $OUTDIR/$FILE2.bam
$SAMTOOLS view -b -h $OUTDIR/$FILE3 -o $OUTDIR/$FILE3.bam

#$SAMTOOLS merge $OUTDIR/Cell$FILEINDEX.bam $OUTDIR/$FILE1.bam $OUTDIR/$FILE2.bam $OUTDIR/$FILE3.bam 

rm $OUTDIR/$FILE1
rm $OUTDIR/$FILE2
rm $OUTDIR/$FILE3



#export _JAVA_OPTIONS="-Xmx100M -XX:MaxHeapSize=100m"
#java -jar $CRAMTOOLS bam -I $OUTDIR/$FILE1 -O $OUTDIR/$FILE1.cram.bam

#alias cramtools='java -jar cramtools-2.0.jar'
#cramtools bam -I 9233_8#168_1.cram -O 9233_8#168_1.cram.bam
#cramtools fastq -I 9233_8#168_1.cram | head
#samtools view 9233_8#168_1.cram.bam | head
