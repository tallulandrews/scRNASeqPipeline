#!/bin/bash
# This is just a copy of commands in 00_LIST_OF_BSUB_COMMANDS.sh so that I can run it separately from the rest of the pipeline.

OUTPUTDIR=/lustre/scratch108/compgen/team218/TA/Bergiers_Wafergen/BigFilesMappedDeDupped
mkdir -p $OUTPUTDIR
INPUTDIR=/lustre/scratch108/compgen/team218/TA/Bergiers_Wafergen/BigFilesMappedTranscriptome
INPUTFILES=($INPUTDIR/*.bam)
NUMFILES=${#INPUTFILES[@]}
MAXJOBS=$(($NUMFILES))
bsub -J"mappingwithstararrayjob[1-$MAXJOBS]%100" -R"select[mem>5000] rusage[mem=5000]" -M5000 -q normal -o umi-tools.out.%J.%I -e umi-tools.err.%J.%I /nfs/users/nfs_t/ta6/RNASeqPipeline/3_UmiDedup.sh $INPUTDIR $OUTPUTDIR Rerum_DirAdj_transcriptome directional-adjacency

#    methods:
#    options_method = "directional-adjacency"
#    options_method = "adjacency"
#    options_method = "unique"

