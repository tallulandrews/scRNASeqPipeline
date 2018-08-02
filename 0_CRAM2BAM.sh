#!/bin/bash
CRAM_file=$1
BAM_dir=$2
WORK_dir=$3 # fast I/O location with space to store genome & temporary files

export REF_CACHE=$WORK_dir
SAMTOOLS=/nfs/users/nfs_t/ta6/RNASeqPipeline/software/CRAM/samtools-1.3.1/samtools

# Checks
USAGE="Usage: 0_CRAM2BAM.sh cram_file bam_dir work_dir\n
	\tArguments:\n
		\tcram_file = CRAM file or directory of CRAM files if running in job array\n
		\tbam_dir = directory to be filled with BAM files\n
		\twork_dir = fast I/O location with space to store genome\n"

if [ -z $CRAM_file ] || [ -z $BAM_dir ] || [ -z $WORK_dir ] ; then
  echo -e $USAGE
  exit 1
fi

if [ ! -f $SAMTOOLS ] ; then
  echo "$SAMTOOLS not available"
  exit 1
fi



# Get all CRAM files

if [ ! -z $LSB_JOBINDEX ]; then
  CRAMS=($CRAM_file/*.cram)
  INDEX=$(($LSB_JOBINDEX-1))
  FILE=${CRAMS[$INDEX]}
else 
  FILE=$CRAM_file
fi

NAME=`basename ${FILE%.cram}` #remove path and .cram suffix
cp $FILE $WORK_dir/$NAME.cram
$SAMTOOLS view -b -h $WORK_dir/$NAME.cram -o $BAM_dir/$NAME.bam
rm $WORK_dir/$NAME.cram


