#!/bin/bash
# This is just a copy of commands in 00_LIST_OF_BSUB_COMMANDS.sh so that I can run it separately from the rest of the pipeline.

OUTPUTDIR=/lustre/scratch108/compgen/team218/TA/RNASeqFilesQuantified/DeNovoTranscripts
mkdir -p $OUTPUTDIR
INPUTDIR=/lustre/scratch108/compgen/team218/TA/RNASeqFilesMapped/Deduplicated
INPUTFILES=($INPUTDIR/*.bam)
NUMFILES=${#INPUTFILES[@]}
MAXJOBS=$(($NUMFILES))

bsub -J"mappingwithstararrayjob[48-$MAXJOBS]%40" -R"select[mem>1000] rusage[mem=1000]" -M1000 -q normal -o output.%J.%I -e error.%J.%I /nfs/users/nfs_t/ta6/RNASeqPipeline/5_Cufflinks_wrapper.sh Mmus 1 $INPUTDIR $OUTPUTDIR

