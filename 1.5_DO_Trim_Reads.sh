#!/bin/bash
# This is just a copy of commands in 00_LIST_OF_BSUB_COMMANDS.sh so that I can run it separately from the rest of the pipeline.

OUTPUTDIR=/lustre/scratch108/compgen/team218/TA/Bergiers_Wafergen/BigFilesQCed
mkdir -p $OUTPUTDIR
INPUTDIR=/lustre/scratch108/compgen/team218/TA/Bergiers_Wafergen/BigFilesToMap
INPUTFILES=($INPUTDIR/*)
NUMFILES=${#INPUTFILES[@]}
MAXJOBS=$(($NUMFILES))
bsub -J"mappingwithstararrayjob[1-$MAXJOBS]%100" -R"select[mem>1000] rusage[mem=1000]" -M1000 -q normal -o output.%J.%I /nfs/users/nfs_t/ta6/RNASeqPipeline/1.5_Trim_Reads.sh $INPUTDIR $OUTPUTDIR
