#!/bin/bash
# This is just a copy of commands in 00_LIST_OF_BSUB_COMMANDS.sh so that I can run it separately from the rest of the pipeline.

INDEXFILE=/lustre/scratch108/compgen/team218/TA/STRIPED_GENOMES/salmon_index
OUTPUTDIR=/lustre/scratch108/compgen/team218/TA/RNASeqFilesQuantified/Buettner_Salmon
GTFFILE=/lustre/scratch108/compgen/team218/TA/genomebuilding/Mus_musculus.GRCm38.79.gtf
mkdir -p $OUTPUTDIR
INPUTDIR=/lustre/scratch108/compgen/team218/TA/RNASeqFilesToMap/
INPUTFILES=($INPUTDIR/*)
NUMFILES=${#INPUTFILES[@]}
MAXJOBS=$(($NUMFILES/2))
bsub -J"mappingwithstararrayjob[1-$MAXJOBS]%50" -R"select[mem>5000] rusage[mem=5000] span[hosts=1]" -M5000 -n2 -q normal -o output.%J.%I /nfs/users/nfs_t/ta6/RNASeqPipeline/2-5.2_Salmon_quant.sh 1 $INPUTDIR $OUTPUTDIR $INDEXFILE $GTFFILE

