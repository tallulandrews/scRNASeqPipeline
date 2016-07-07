#!/bin/bash
# This is just a copy of commands in 00_LIST_OF_BSUB_COMMANDS.sh so that I can run it separately from the rest of the pipeline.

OUTPUTDIR=/lustre/scratch108/compgen/team218/TA/RNASeqFilesQuantified/Buettner_RSEM
mkdir -p $OUTPUTDIR
INPUTDIR=/lustre/scratch108/compgen/team218/TA/RNASeqFilesToMap
INPUTFILES=($INPUTDIR/*)
NUMFILES=${#INPUTFILES[@]}
MAXJOBS=$(($NUMFILES/2))
bsub -J"mappingwithstararrayjob[1-$MAXJOBS]%30" -R"select[mem>30000] rusage[mem=30000] span[hosts=1]" -M30000 -n2 -q normal -o output.%J.%I /nfs/users/nfs_t/ta6/RNASeqPipeline/2-5_STAR-RSEM.sh $INPUTDIR $OUTPUTDIR Beuttner_STAR_RSEM 2
#bsub -J"mappingwithstararrayjob[1-$MAXJOBS]%30" -R"select[mem>10000] rusage[mem=10000] span[hosts=1]" -M10000 -n5 -q normal -o output.%J.%I /nfs/users/nfs_t/ta6/RNASeqPipeline/2-5_bowtie2-RSEM.sh $INPUTDIR $OUTPUTDIR Beuttner_bowtie2_RSEM 5

