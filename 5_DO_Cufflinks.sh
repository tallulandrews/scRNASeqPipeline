#!/bin/bash
# This is just a copy of commands in 00_LIST_OF_BSUB_COMMANDS.sh so that I can run it separately from the rest of the pipeline.

OUTPUTDIR=/lustre/scratch108/compgen/team218/TA/RNASeqFilesQuantified/Buettner_Cufflinks
mkdir -p $OUTPUTDIR
INPUTDIR=/lustre/scratch108/compgen/team218/TA/RNASeqFilesMapped/Beuttner_Tophat/Beuttner_Tophat2_dedup/Deduplicated
INPUTFILES=($INPUTDIR/*.bam)
NUMFILES=${#INPUTFILES[@]}
MAXJOBS=$(($NUMFILES))

bsub -J"mappingwithstararrayjob[1-$MAXJOBS]%40" -R"select[mem>5000] rusage[mem=5000]" -M5000 -q normal -o output.%J.%I -e error.%J.%I /nfs/users/nfs_t/ta6/RNASeqPipeline/5_Cufflinks_wrapper.sh Mmus 1 $INPUTDIR $OUTPUTDIR /lustre/scratch108/compgen/team218/TA/genomebuilding/Mus_musculus.GRCm38.79.gtf
