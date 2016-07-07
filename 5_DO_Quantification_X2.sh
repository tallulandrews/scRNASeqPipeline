#!/bin/bash
# NOT TESTED

OUTPUTDIR=/lustre/scratch108/compgen/team218/TA/RNASeqFilesQuantified/Bergiers_Vivo
mkdir -p $OUTPUTDIR
INPUTDIR=/lustre/scratch108/compgen/team218/TA/RNASeqFilesMapped/Bergiers_Vivo/Deduplicated
INPUTFILES=($INPUTDIR/Bergiers_Vivo*.bam)
NUMFILES=${#INPUTFILES[@]}
MAXJOBS=$(($NUMFILES))

NEWANNOTATIONgtf="/lustre/scratch108/compgen/team218/TA/genomebuilding/Mus_musculus.GRCm38.79.gtf"

#bsub -J"mappingwithstararrayjob[1-$MAXJOBS]%20" -R"select[mem>1000] rusage[mem=1000]" -M1000 -q normal -o output.%J.%I -e error.%J.%I /nfs/users/nfs_t/ta6/RNASeqPipeline/5_Cufflinks_wrapper.sh Mmus 1 $INPUTDIR $OUTPUTDIR $NEWANNOTATIONgtf


#Only run these one at a time because they create a huge amount of temporary files
bsub -J"mappingwithstararrayjob[1-$MAXJOBS]%1" -R"select[mem>10000] rusage[mem=10000]" -M10000 -q normal -o FCountoutput.%J.%I -e FCounterror.%J.%I /nfs/users/nfs_t/ta6/RNASeqPipeline/5_featureCounts_wrapper.sh $NEWANNOTATIONgtf 1 $INPUTDIR

