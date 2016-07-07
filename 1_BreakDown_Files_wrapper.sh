#!/bin/bash

if [ -z "$1" ] ; then
  echo "Please set maximum number of reads per file (ARG 1/4)"
  exit 1
fi
if [ -z $2 ] ; then
  echo "Please set input file directory (ARG 2/4)"
  exit 1
fi
if [ -z $3 ] ; then
  echo "Please set a pattern for inputfiles (ARG 3/4)"
  exit 1
fi
if [ -z "$4" ] ; then
  echo "Please set a directory for output files (ARG 4/4)"
  exit 1
fi

OUTPUTDIR=$4
INPUTFILES=($2/$3)
ARRAYINDEX=$((($LSB_JOBINDEX-1)))

perl /nfs/users/nfs_t/ta6/RNASeqPipeline/1_BreakDown_PairedEnds.pl $LSB_JOBINDEX $1 $OUTPUTDIR ${INPUTFILES[$ARRAYINDEX]}
