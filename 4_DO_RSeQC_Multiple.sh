#!/bin/bash
# Arguments:
# $1 = Organism under consideration
# $2 = input bam dir
# $3 = output directory

ORGANISM=$1
INPUTDIR=$2
OUTDIR=$3

if [ -z $ORGANISM ] ; then
  echo "Please set organism for reference annotations (ARG 1/3)"
  exit 1
fi

if [ -z $INPUTDIR ] ; then
  echo "$INPUTDIR does not exist. Please provide a directory of BAMfiles (ARG 2/3)"
  exit 1
fi

if [ -z $OUTDIR ] ; then
  echo "Please set a directory for the output files (ARG 3/3)"
  exit 1
fi

mkdir -p $OUTDIR


# Check relevant annotation/gene model files exist and have been converted to BED format -> prevent multiple jobs trying to write to the same place.
# This code is duplicated in 4_RSeQC_Multiple.sh so that it can be run safely on its own (specific/detailed analyses for particular files) or from this script for bulk analysis
MASKgtf=/lustre/scratch108/compgen/team218/TA/TemporaryFileDir/$ORGANISM-rRNAtRNAmtmRNAs-mask.gtf
MASKbed="${MASKgtf%.gtf}.bed"
REFGENOME="/lustre/scratch108/compgen/team218/TA/genomebuilding/Mus_musculus.GRCm38.79.gtf"
REFGENOMEbed="${REFGENOME%.gtf}.bed"

if [ ! -f $MASKbed ] ; then
  echo "Cannot find $MASKbed: attempting to make it."
  if [ ! -f $MASKgtf ] ; then
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



if [ ! -f $REFGENOMEbed ] ; then
  echo "Cannot find $REFGENOMEbed: attempting to make it."
  if [ ! -f $REFGENOME ] ; then
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

for INPUTFILE in $INPUTDIR/*.bam ; do
  OUTPREFIX=$(basename $INPUTFILE)
  OUTPREFIX=${OUTPREFIX%.bam}
  bsub -R"select[mem>1000] rusage[mem=1000]" -M1000 -q normal -o $OUTDIR/RSEQC_$OUTPREFIX.output /nfs/users/nfs_t/ta6/RNASeqPipeline/4_RSeQC_Multiple.sh $ORGANISM $INPUTFILE $OUTDIR/RSEQC_$OUTPREFIX 1
done
