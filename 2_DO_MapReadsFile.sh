#!/bin/bash
# This is just a copy of commands in 00_LIST_OF_BSUB_COMMANDS.sh so that I can run it separately from the rest of the pipeline.

OUTPUTDIR=/lustre/scratch108/compgen/team218/TA/RNASeqFilesMapped/Beuttner_STAR
mkdir -p $OUTPUTDIR
INPUTDIR=/lustre/scratch108/compgen/team218/TA/RNASeqFilesToMap
INPUTFILES=($INPUTDIR/*)
NUMFILES=${#INPUTFILES[@]}
MAXJOBS=$(($NUMFILES/2))
bsub -J"mappingwithstararrayjob[1-$MAXJOBS]%30" -R"select[mem>30000] rusage[mem=30000]" -M30000 -q normal -o output.%J.%I /nfs/users/nfs_t/ta6/RNASeqPipeline/2_MapReadsFile.sh 1 $INPUTDIR $OUTPUTDIR /nfs/users/nfs_t/ta6/RNASeqPipeline/2_STAR_Parameters.txt Beuttner_STAR

