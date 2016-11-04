#!/bin/bash
# This is just a copy of commands in 00_LIST_OF_BSUB_COMMANDS.sh so that I can run it separately from the rest of the pipeline.

#OUTPUTDIR=/lustre/scratch108/compgen/team218/TA/NeuronsEmmyLiora/FilesMapped
OUTPUTDIR=/lustre/scratch108/compgen/team218/TA/Bergiers_Wafergen/BigFilesMappedTranscriptome
mkdir -p $OUTPUTDIR
#INPUTDIR=/lustre/scratch108/compgen/team218/TA/NeuronsEmmyLiora/FilesUMITrimmed
INPUTDIR=/lustre/scratch108/compgen/team218/TA/Bergiers_Wafergen/BigFilesQCed
GENOMEDIR=/lustre/scratch108/compgen/team218/TA/STRIPED_GENOMES/Bergiers
INPUTFILES=($INPUTDIR/*)
NUMFILES=${#INPUTFILES[@]}
MAXJOBS=$(($NUMFILES))
#GENOMEDIR=/lustre/scratch108/compgen/team218/TA/STRIPED_GENOMES/NeuronsLiora/
bsub -J"mappingwithstararrayjob[1-$MAXJOBS]%100" -R"select[mem>35000] rusage[mem=35000]" -M35000 -q normal -o output.%J.%I /nfs/users/nfs_t/ta6/RNASeqPipeline/2_MapReadsFile_singleend.sh 1 $INPUTDIR $OUTPUTDIR /nfs/users/nfs_t/ta6/RNASeqPipeline/2_STAR_Parameters.txt $GENOMEDIR Bergiers_Trimmed_Waf375
