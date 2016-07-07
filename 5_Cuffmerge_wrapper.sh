#!/bin/bash
# Note: this may be called by 4_RSeQC_Multiple.sh, 4_DO_RSeQC_Multiple.sh
# Arguments:
# $1 = number of threads to run on
# $2 = file of files to merge
# $3 = reference gtf (optional)
# $4 = reference fasta (optional)

CUFFMERGE=/nfs/users/nfs_t/ta6/RNASeqPipeline/software/cufflinks-2.2.1.Linux_x86_64/cuffmerge
NUMTHREADS=$1
INPUTFILE=$2
REFgtf=$3
REFfasta=$4

# Add gtf_to_sam and other accessorty cufflinks scripts to my path
export PATH=$PATH:/nfs/users/nfs_t/ta6/RNASeqPipeline/software/cufflinks-2.2.1.Linux_x86_64/

if [ ! -f $CUFFMERGE ] ; then
  echo "Sorry Cuffmerge not available"
  exit 1
fi

if [ -z $NUMTHREADS ] ; then
  echo "Please set number of threads to run on, setting = 0 will get genome & rRNA gtf but not run cufflinks (ARG 1/4)"
  exit 1
fi

if [ $NUMTHREADS -lt 1 ] ; then
  echo "Number of threads must be at least 1."
  exit 1
fi

if [ -z $INPUTFILE ] ; then
  echo "Please set provide a file with a list of gtf files to merge (ARG 2/4)"
  exit 1
fi

ARGrefgtf=""
if [ ! -z $REFgtf ] ; then
  if [ -s $REFgtf ] ; then
    ARGrefgtf="-g $REFgtf"
  else
    echo "Reference GTF is empty or does not exist, will not be used";
  fi
fi

ARGreffa=""
if [ ! -z $REFfasta ] ; then
  if [ -s $REFfasta ] ; then
    ARGreffa="-s $REFfasta"
  else 
    echo "Reference FASTA is empty of does not exist, will not be used";
  fi
fi


# Cuffmerge options:
# -o outprefix->redirects stdout
# -g ref-gtf
# -p number of threads
# -s ref-sequence
$CUFFMERGE $ARGrefgtf $ARGreffa --num-threads $NUMTHREADS $INPUTFILE
