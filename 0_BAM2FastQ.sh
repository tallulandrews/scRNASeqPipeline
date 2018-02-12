#!/bin/bash
# Convert BAM file to paired, zipped, read files. Assumes paired-end sequencing
# Designed for LSF job-arrays

INPUTDIR=$1
OUTDIR=$2
#LSB_JOBINDEX=$3 # specify which file to run on

export REF_CACHE=/lustre/scratch117/cellgen/team218/TA/TemporaryFileDir
FILEStoMAP=($INPUTDIR/*.bam)
ARRAYINDEX=$(($LSB_JOBINDEX-1))
FILE=${FILEStoMAP[$ARRAYINDEX]}
SAMTOOLS=/nfs/users/nfs_t/ta6/RNASeqPipeline/software/CRAM/samtools-1.3.1/samtools
BEDTOOLS=/nfs/users/nfs_t/ta6/RNASeqPipeline/software/bedtools2/bin/bedtools
FASTQ1=$( basename $FILE )_1.fastq
FASTQ2=$( basename $FILE )_2.fastq

if [ ! -f $OUTDIR/$FASTQ1.gz ] || [ ! -f $OUTDIR/$FASTQ2.gz ] ; then

	#write all reads to fastq
	TMP=Tmp$LSB_JOBINDEX.bam
	TMP2=Tmp2_$LSB_JOBINDEX.bam
	$SAMTOOLS sort -n $FILE -o $TMP
	$SAMTOOLS view -b -F 256 $TMP -o $TMP2
	$BEDTOOLS bamtofastq -i $TMP2 -fq $OUTDIR/$FASTQ1 -fq2 $OUTDIR/$FASTQ2
	

	gzip $OUTDIR/$FASTQ1
	gzip $OUTDIR/$FASTQ2
	rm $TMP
	rm $TMP2

fi
