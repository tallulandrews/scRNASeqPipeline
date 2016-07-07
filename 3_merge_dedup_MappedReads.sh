#!/bin/bash
# Coppied commands from 00_LIST_OF_BSUB_COMMANDS.sh

# These must be consistent with 2_DO_MapReadsFile.sh
OUTPUTDIR=/lustre/scratch108/compgen/team218/TA/RNASeqFilesMapped/Beuttner_Tophat/
TAG="Beuttner_Tophat2_dedup"
SCRIPT=/nfs/users/nfs_t/ta6/RNASeqPipeline/4_MergeBAMs.pl

if [ ! -f $SCRIPT ] ; then
  echo "$SCRIPT not available"
  exit 1
fi

if [ -z $TAG ] ; then
  echo "No project tag"
  exit 1
fi

if [ -z $OUTPUTDIR ] ; then
  echo "No directory of sorted mapped read bam files"
  exit 1
fi

# Do I want to do this in here?
perl $SCRIPT $OUTPUTDIR $TAG

MappedDedupDIR=$OUTPUTDIR/$TAG/Deduplicated
MappedWdupDIR=$OUTPUTDIR/$TAG/WithDuplicates
mkdir -p $MappedDedupDIR
mkdir -p $MappedWdupDIR
mv $OUTPUTDIR/*dedup* $MappedDedupDIR
mv $OUTPUTDIR/*sorted*.bam $MappedWdupDIR
#tar -cvzf $OUTPUTDIR/Bergiers_exp2_mapping_output.tar.gz $OUTPUTDIR/Bergiers*exp2*
#rm $OUTPUTDIR/Bergiers_lane*.bam

