#!/bin/bash
# This is just a copy of commands in 00_LIST_OF_BSUB_COMMANDS.sh so that I can run it separately from the rest of the pipeline.

INDEXFILE=/lustre/scratch108/compgen/team218/TA/STRIPED_GENOMES/kallisto_index.idx
OUTPUTDIR=/lustre/scratch108/compgen/team218/TA/RNASeqFilesQuantified/Buettner_Kallisto
mkdir -p $OUTPUTDIR
INPUTDIR=/lustre/scratch108/compgen/team218/TA/RNASeqFilesToMap/
INPUTFILES=($INPUTDIR/*)
NUMFILES=${#INPUTFILES[@]}
MAXJOBS=$(($NUMFILES/2))
bsub -J"mappingwithstararrayjob[1-$MAXJOBS]%30" -R"select[mem>5000] rusage[mem=5000]" -M5000 -q normal -o output.%J.%I /nfs/users/nfs_t/ta6/RNASeqPipeline/2-5.1_kallisto_quant.sh 1 $INPUTDIR $OUTPUTDIR $INDEXFILE Bergiers_Vivo

