#!/bin/bash
# This is just a copy of commands in 00_LIST_OF_BSUB_COMMANDS.sh so that I can run it separately from the rest of the pipeline.

OUTPUTDIR=/lustre/scratch108/compgen/team218/TA/RNASeqFilesMapped/Beuttner_Tophat
mkdir -p $OUTPUTDIR
INPUTDIR=/lustre/scratch108/compgen/team218/TA/RNASeqFilesToMap
INPUTFILES=($INPUTDIR/*)
NUMFILES=${#INPUTFILES[@]}
MAXJOBS=$(($NUMFILES/2))
GENOME=/lustre/scratch108/compgen/team218/TA/STRIPED_GENOMES/bowtie2_build
bsub -J"mappingwithstararrayjob[1-$MAXJOBS]%50" -R"select[mem>6000] rusage[mem=6000] span[hosts=1]" -M6000 -n5 -q long -o output.%J.%I /nfs/users/nfs_t/ta6/RNASeqPipeline/2.2_MapReads_Tophat.sh 5 $INPUTDIR $OUTPUTDIR $GENOME Beuttner_Tophat

