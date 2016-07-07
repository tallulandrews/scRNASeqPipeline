#!/bin/bash
# Arguments:
# $1 = Organism under consideration
# $2 = input bam
# $3 = output prefix
# $4 = full analysis? [0/1], 1=do all six analyses, 0=only do basic stats & rRNA content

ORGANISM=$1
INPUTBAM=$2
OUTPREFIX=$3
MAP_QUALITY=30 #default=30 on Phred scale

if [ -z $ORGANISM ] ; then
  echo "Please set organism for reference annotations (ARG 1/4)"
  exit 1
fi

if [ -z $INPUTBAM ] || [ ! -f $INPUTBAM ] ; then
  echo "$INPUTBAM does not exist. Please provide existing sorted BAM file (ARG 2/4)"
  exit 1
fi

if [ -z $OUTPREFIX ] ; then
  echo "Please set a prefix for the output files (ARG 3/4)"
  exit 1
fi

if [ -z $4 ] ; then
  echo "Please set type of analysis: 0 = basic stats & rRNA content only, 1 = full analysis (ARG 4/4)"
  exit 1
fi

# Check relevant annotation/gene model files exist and have been converted to BED format
# This code is duplicated in 4_DO_RSeQC_Multiple.sh
MASKgtf=/lustre/scratch108/compgen/team218/TA/TemporaryFileDir/$ORGANISM-rRNAtRNAmtmRNAs-mask.gtf
MASKbed="${MASKgtf%.gtf}.bed"
REFGENOME="/lustre/scratch108/compgen/team218/TA/genomebuilding/Mus_musculus.GRCm38.79.gtf"
REFGENOMEbed="${REFGENOME%.gtf}.bed"

if [ ! -s $MASKbed ] ; then
  echo "Cannot find $MASKbed: attempting to make it."
  if [ ! -s $MASKgtf ] ; then
    /nfs/users/nfs_t/ta6/RNASeqPipeline/5_Cufflinks_wrapper.sh $ORGANISM 0
  fi  
  if [ ! -s $MASKgtf ] ; then
    echo "Cannot find or make $MASKgtf\n"
    exit 1
  fi  
# Convert to bed format
  perl /nfs/users/nfs_t/ta6/RNASeqPipeline/4_Convert_GTF2BED_customized_for_Ensembl.pl $MASKgtf > $MASKbed
  if [ ! -s $MASKbed ] ; then
    echo "Failed to make $MASKbed\n"
    exit 1
  fi  
fi

if [ ! -s $REFGENOMEbed ] ; then
  echo "Cannot find $REFGENOMEbed: attempting to make it."
  if [ ! -s $REFGENOME ] ; then
    /nfs/users/nfs_t/ta6/RNASeqPipeline/5_Cufflinks_wrapper.sh $ORGANISM 0
  fi  
  if [ ! -s $REFGENOME ] ; then
    echo "Cannot find or make $REFGENOME\n"
    exit 1
  fi  
# Convert to bed format
  perl /nfs/users/nfs_t/ta6/RNASeqPipeline/4_Convert_GTF2BED_customized_for_Ensembl.pl $REFGENOME > $REFGENOMEbed
  if [ ! -s $REFGENOMEbed ] ; then
    echo "Failed to make $REFGENOMEbed\n"
    exit 1
  fi
fi


# RUN RSeQC analysis
# get python path
bash

echo $INPUTBAM
python /nfs/users/nfs_t/ta6/RNASeqPipeline/software/RSeQC-2.6.1/scripts/split_bam.py -i $INPUTBAM -r $MASKbed -o $OUTPREFIX
python /nfs/users/nfs_t/ta6/RNASeqPipeline/software/RSeQC-2.6.1/scripts/bam_stat.py -i $INPUTBAM -q $MAP_QUALITY 
if [ $4 -gt 0 ] ; then 
  if [ ! -f $INPUTBAM.bai ] ; then
    samtools index $INPUTBAM
  fi
  python /nfs/users/nfs_t/ta6/RNASeqPipeline/software/RSeQC-2.6.1/scripts/geneBody_coverage.py -i $INPUTBAM -r $REFGENOMEbed -o $OUTPREFIX #requires BAM indexing file *.bam.bai -> index using samtools
  # -m 20 = minimum intron size (keeping consistent with STAR ENCODE parameters)
  python /nfs/users/nfs_t/ta6/RNASeqPipeline/software/RSeQC-2.6.1/scripts/junction_saturation.py -i $INPUTBAM -r $REFGENOMEbed -o $OUTPREFIX -m 20 -q $MAP_QUALITY
  python /nfs/users/nfs_t/ta6/RNASeqPipeline/software/RSeQC-2.6.1/scripts/read_GC.py -i $INPUTBAM -o $OUTPREFIX -q $MAP_QUALITY
#  python /nfs/users/nfs_t/ta6/RNASeqPipeline/software/RSeQC-2.6.1/scripts/RNA_fragment_size.py -i $INPUTBAM -r $REFGENOMEbed -q $MAP_QUALITY  #requires BAM indexing file *.bam.bai, output takes up lot of memory & similar to what I will probably get from fragment counting software so not very important
fi

rm $OUTPREFIX*.bam
