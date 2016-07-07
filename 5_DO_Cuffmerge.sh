#!/bin/bash

OUTPUTDIR=/lustre/scratch108/compgen/team218/TA/RNASeqFilesQuantified/DeNovoTranscripts
mkdir -p $OUTPUTDIR
INPUTDIR=/lustre/scratch108/compgen/team218/TA/RNASeqFilesQuantified
INPUTFILE=$OUTPUTDIR/List_of_GTFs_to_merge.txt
REFgtf=/lustre/scratch108/compgen/team218/TA/genomebuilding/Mus_musculus.GRCm38.79.gtf
REFfa=/lustre/scratch108/compgen/team218/TA/genomebuilding/Mus_musculus.GRCm38.dna.primary_assembly.fa

ls $INPUTDIR/*_transcripts.gtf > $INPUTFILE

cd $OUTPUTDIR

readarray -t array < $INPUTFILE
for file in ${array[@]} ; do
  cat $file | sed "s/TNeo CDS/TNeoCDS/" > tempfile.tmp
  mv tempfile.tmp $file
done

bsub -R"select[mem>10000] rusage[mem=10000]" -M10000 -q normal -o output.%J -e error.%J /nfs/users/nfs_t/ta6/RNASeqPipeline/5_Cuffmerge_wrapper.sh 1 $INPUTFILE $REFgtf $REFfa

