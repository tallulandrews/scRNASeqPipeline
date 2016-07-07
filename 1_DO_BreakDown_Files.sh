#!/bin/bash
# This is just a copy of commands in 00_LIST_OF_BSUB_COMMANDS.sh so that I can run it separately from the rest of the pipeline.
OUTPUTDIR=/lustre/scratch108/compgen/team218/TA/RNASeqFilesToMap/
mkdir -p $OUTPUTDIR
INPUTDIR=/nfs/team218/MH/2015-03-02-C6H8GANXX/2015-03-02-C6H8GANXX/
PATTERN="*exp2*_sequence.txt.gz"
INPUTFILES=($INPUTDIR/$PATTERN)
NUMFILES=${#INPUTFILES[@]}
MAXJOBS=$(($NUMFILES))
bsub -J"mappingwithstararrayjob[1-$MAXJOBS]%40" -R"select[mem>4000] rusage[mem=4000]" -M4000 -q normal -o output.%J.%I /nfs/users/nfs_t/ta6/RNASeqPipeline/1_BreakDown_Files_wrapper.sh 100000000 "$INPUTDIR" "$PATTERN" $OUTPUTDIR
