#!/bin/bash
# Convert BAM file to paired, zipped, read files. Assumes paired-end sequencing
BAM_file=$1
OUT_dir=$2
WORK_dir=$3

export REF_CACHE=$WORK_dir
SAMTOOLS=/nfs/users/nfs_t/ta6/RNASeqPipeline/software/CRAM/samtools-1.3.1/samtools
BEDTOOLS=/nfs/users/nfs_t/ta6/RNASeqPipeline/software/bedtools2/bin/bedtools

USAGE="Usage: 0_BAM2FastQ.sh bam_file out_dir work_dir\n
	Assumes paired-end reads.
	\tArguments:\n
		\tbam_file = BAM file or directory of BAM files if running in job array\n
		\tout_dir = directory for FastQ files\n
		\twork_dir = fast I/O location with space to store genome\n"

if [ -z $BAM_file ] || [ -z $BAM_dir ] || [ -z $WORK_dir ] ; then
  echo -e $USAGE
  exit 1
fi

if [ ! -f $SAMTOOLS ] ; then
  echo "$SAMTOOLS not available"
  exit 1
fi

if [ ! -f $BEDTOOLS ] ; then
  echo "$BEDTOOLS not available"
  exit 1
fi

# Get CRAM files
if [ ! -z $LSB_JOBINDEX ]; then
  BAMS=($BAM_file/*.bam)
  INDEX=$(($LSB_JOBINDEX-1))
  FILE=${BAMS[$INDEX]}
else
  FILE=$BAM_file
fi

NAME=`basename ${FILE%.bam}` # remove path and .bam suffix

FASTQ1=${NAME}_1.fq
FASTQ2=${$NAME}_2.fq

#write all reads to fastq
TMP=$WORK_dir/Tmp$NAME.bam
TMP2=$WORK_dir/Tmp2_$NAME.bam
$SAMTOOLS sort -n $FILE -o $TMP
$SAMTOOLS view -b -F 256 $TMP -o $TMP2 # remove secondary alignments
$BEDTOOLS bamtofastq -i $TMP2 -fq $OUT_dir/$FASTQ1 -fq2 $OUT_dir/$FASTQ2

gzip $OUT_dir/$FASTQ1
gzip $OUT_dir/$FASTQ2
rm $TMP
rm $TMP2
