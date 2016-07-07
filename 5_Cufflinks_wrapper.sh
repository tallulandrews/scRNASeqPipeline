#!/bin/bash
# Note: this may be called by 4_RSeQC_Multiple.sh, 4_DO_RSeQC_Multiple.sh
# Arguments:
# $1 = organism: either Mmus or Hsap 
# $2 = number of threads to run on
# $3 = input BAM to run on (only required if number of threads > 0)
# $4 = outputdir (optional, default = /lustre/scratch108/compgen/team218/TA/RNASeqFilesQuantified).
# $5 = gtf file. -> if provided allows faux reads, if not provided gets genome one and does not use faux-reads

CUFFLINKS=/nfs/users/nfs_t/ta6/RNASeqPipeline/software/cufflinks-2.2.1.Linux_x86_64/cufflinks
ORGANISM=$1
NUMTHREADS=$2
INPUTDIR=$3
OUTDIR=$4
ANNOTATIONgtf=$5
TEMPDIR=/lustre/scratch108/compgen/team218/TA/TemporaryFileDir
FILEStoMAP=($INPUTDIR/*.bam)
ARRAYINDEX=$(($LSB_JOBINDEX-1))
INPUTBAM=${FILEStoMAP[$ARRAYINDEX]}
echo "Inputfile: $INPUTBAM"

if [ ! -f $CUFFLINKS ] ; then
  echo "Sorry Cufflinks not available"
  exit 1
fi

if [ -z $ORGANISM ] ; then
  echo "Please set organism for reference annotations (ARG 1/4)"
  exit 1
fi

if [ -z $NUMTHREADS ] ; then
  echo "Please set number of threads to run on, setting = 0 will get genome & rRNA gtf but not run cufflinks (ARG 2/4)"
  exit 1
fi

if [ $NUMTHREADS -gt 0 ] ; then
  if [ -z $INPUTBAM ] || [ ! -f $INPUTBAM ] ; then
    echo "$INPUTBAM, jobindex $LSB_JOBINDEX, array index $ARRAYINDEX of $INPUTDIR does not exist. Please provide a directory containing BAMfiles (ARG 3/4)"
    exit 1
  fi
fi

if [ -z $OUTDIR ] ; then
  OUTDIR=/lustre/scratch108/compgen/team218/TA/RNASeqFilesQuantified
fi
if [ -z $LSB_JOBINDEX ] ; then
  LSB_JOBINDEX=7
fi

SEED=$((100+$LSB_JOBINDEX))
echo "rgenerator seed: $SEED"

FAUXREADS=""

# Get stuff for cufflinks:
# gtf if not already present, get genome fasta if not already present (basically run Build genome without actually running STAR.
if [ -z $ANNOTATIONgtf ] ; then
  echo "Using mapping-genome annotations"
  GENOMEDIR=/lustre/scratch108/compgen/team218/TA/genomebuilding
  GENOMEfa=$GENOMEDIR/*.fa
  GENOMEgtf=$GENOMEDIR/*.gtf
  ANNOTATIONgtf=$GENOMEgtf
  FAUXREADS="--no-faux-reads"

#  if [ ! -s $GENOMEfa ] ; then
#    /nfs/users/nfs_t/ta6/RNASeqPipeline/0_BuildGenome.sh $GENOMEDIR $TEMPDIR 0 125 $ORGANISM /nfs/users/nfs_t/ta6/Collaborations/Bergiers_Italy
#  fi
#  if [ ! -s $GENOMEgtf ] ; then
#    /nfs/users/nfs_t/ta6/RNASeqPipeline/0_BuildGenome.sh $GENOMEDIR $TEMPDIR 0 125 $ORGANISM /nfs/users/nfs_t/ta6/Collaborations/Bergiers_Italy
#  fi
fi
  # get rRNA, mitochondial transcripts, tRNAs to mask -> hummmmm....... how best to do this? -> use grep to select the relevant lines from the existing .gtf is fast and ensures compatibility between the two gtf files and with the .fa file.
MASKgtf=$TEMPDIR/$ORGANISM-rRNAtRNAmtmRNAs-mask.gtf
if [ ! -f $MASKgtf ] ; then
  grep -E 'rRNA|tRNA|^MT' /lustre/scratch108/compgen/team218/TA/genomebuilding/*.gtf > $MASKgtf
fi


if [ ! -s $GENOMEfa ] ; then
  echo "Failed to find or make $GENOMEfa"
  exit 1;
fi
if [ ! -s $GENOMEgtf ] ; then
  echo "Failed to find or make $GENOMEgtf"
  exit 1;
fi
if [ ! -f $MASKgtf ] ; then
  echo "Failed to find or make $MASKgtf"
  exit 1;
fi
if [ ! -s $MASKgtf ] ; then
  echo "Warning: Mask ($MASKgtf) is empty, continuing anyway..."
fi



# Cufflinks options:
# --GTF-guide <reference_annotation.gtf>
# --mask-file <mask.gtf>
# --frag-bias-correct <genome.fa>
# --multi-read-correct
# --quiet
# --no-update-check
# -o <outputdirectory>
# --num-threads <number of threads used during analysis>
# --seed <random # generator seed>
# --max-intron-length 1000000 #keep consistent with STAR parameters
# --min-intron-length 20 #keep consistent with STAR parameters
# --max-multiread-fraction <maximum fraction of allowed multireads per transcript> #default is 0.75
# --library-type <one of supported types> #default is fr-unstranded

#To fix failed jobs
#if [ -d "$OUTDIR/JOB$LSB_JOBINDEX" ]; then
#-----------------

if [ $NUMTHREADS -gt 0 ] ; then
  OUTDIR=$OUTDIR/JOB$LSB_JOBINDEX
  mkdir -p $OUTDIR

  # Get rid of S thing from STAR.
  TMPSAM=Temp$LSB_JOBINDEX.out.sam
  samtools view -h -o $TEMPDIR/$TMPSAM $INPUTBAM

  awk 'BEGIN {OFS="\t"} {split($6,C,/[0-9]*/); split($6,L,/[SMDIN]/); if (C[2]=="S") {$10=substr($10,L[1]+1); $11=substr($11,L[1]+1)}; if (C[length(C)]=="S") {L1=length($10)-L[length(L)-1]; $10=substr($10,1,L1); $11=substr($11,1,L1); }; gsub(/[0-9]*S/,"",$6); print}' $TEMPDIR/$TMPSAM > $TEMPDIR/noS.$TMPSAM

  NEWINPUTBAM=$TEMPDIR/noS.Temp$LSB_JOBINDEX.out.bam
  samtools view -bS $TEMPDIR/noS.$TMPSAM > $NEWINPUTBAM
  rm $TEMPDIR/$TMPSAM
  rm $TEMPDIR/noS.$TMPSAM

  # de novo assembly command
#  $CUFFLINKS --GTF-guide $ANNOTATIONgtf --frag-bias-correct $GENOMEfa --mask-file $MASKgtf --multi-read-correct --max-intron-length 1000000 --min-intron-length 20 -o $OUTDIR --quiet --no-update-check --no-faux-reads --seed $SEED --num-threads $NUMTHREADS $NEWINPUTBAM
  $CUFFLINKS --GTF-guide $ANNOTATIONgtf --mask-file $MASKgtf --multi-read-correct --max-intron-length 1000000 --min-intron-length 20 -o $OUTDIR --quiet --no-update-check $FAUXREADS --seed $SEED --num-threads $NUMTHREADS $NEWINPUTBAM
  rm $NEWINPUTBAM
  perl  /nfs/users/nfs_t/ta6/RNASeqPipeline/5_TidyCufflinks.pl $OUTDIR $INPUTBAM

  if [ -f $TEMPDIR/noS.$TMPSAM ]; then
    rm $TEMPDIR/noS.$TMPSAM
  fi
fi
#To fix failed jobs
#fi
#-----------------
