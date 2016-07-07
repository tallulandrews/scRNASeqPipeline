#!/bin/bash
# This is just a copy of commands in 00_LIST_OF_BSUB_COMMANDS.sh so that I can run it separately from the rest of the pipeline.

OUTPUTDIR=/lustre/scratch108/compgen/team218/TA/NeuronsEmmyLiora/FilesMapped
mkdir -p $OUTPUTDIR
INPUTDIR=/lustre/scratch108/compgen/team218/TA/NeuronsEmmyLiora/FilesUMITrimmed
INPUTFILES=($INPUTDIR/*)
NUMFILES=${#INPUTFILES[@]}
MAXJOBS=$(($NUMFILES))
bsub -J"mappingwithstararrayjob[1-$MAXJOBS]%100" -R"select[mem>30000] rusage[mem=30000]" -M30000 -q normal -o output.%J.%I /nfs/users/nfs_t/ta6/RNASeqPipeline/2_MapReadsFile_singleend.sh 1 $INPUTDIR $OUTPUTDIR /nfs/users/nfs_t/ta6/RNASeqPipeline/2_STAR_Parameters.txt NeuronsEmmy_Trimmed
