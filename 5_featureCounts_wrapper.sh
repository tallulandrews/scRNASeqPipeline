#!/bin/bash
# Arguments:
# $1 = Annotation GTF file
# $2 = number of threads to run on
# $3 = input BAM to run on (only required if number of threads > 0)
# $4 = workingdir
# $5 = outputdir
# This runs fast & efficiently, not on cluster took < 10 minutes to count one of the dedupped merged files.
# But should run this on the complete annotations after cufflinks de novo transcript assembly.

featureCOUNT=/nfs/users/nfs_t/ta6/RNASeqPipeline/software/subread-1.4.6-p2-Linux-x86_64/bin/featureCounts
ANNOTATIONgtf=$1
NUMTHREADS=$2
INPUTDIR=$3
WORKINGDIR=$4/$LSB_JOBINDEX
OUTDIR=$5
FILEStoMAP=($INPUTDIR/*.bam)
ARRAYINDEX=$(($LSB_JOBINDEX-1))
INPUTBAM=${FILEStoMAP[$ARRAYINDEX]}
echo "Inputfile: $INPUTBAM"



if [ ! -f $featureCOUNT ] ; then
  echo "Sorry featureCounts not available"
  exit 1
fi

if [ -z $ANNOTATIONgtf ] || [ ! -f $ANNOTATIONgtf ] ; then
  echo "Please provide an annotation GTF file (ARG 1/3)"
  exit 1
fi

if [ -z $NUMTHREADS ] ; then
  echo "Please set number of threads to run on (ARG 2/3)"
  exit 1
fi

if [ $NUMTHREADS -gt 0 ] ; then
  if [ -z $INPUTBAM ] || [ ! -f $INPUTBAM ] ; then
    echo "$INPUTBAM does not exist. Please provide existing sorted BAM file (ARG 3/3)"
    exit 1
  fi
else
  echo "Error: number of threads must be > 0"
  exit 1
fi

# featureCounts options:
# -t 'string' : specify the feature type to count reads for, default='exon'
# -g 'string' : specify the attribute used to group features into meta-features, default='gene_id'
# -f : read summarization performed at the feature level instead of the meta-feature level
# -O : reads can match more than one feature/metafeature
# -M : multi-mapping can be counted multiple times (once for each of their mapping locations
#    alternatively
# --primary : only primary alignments will be counted
# -Q ## : minimum mapping quality (default = 0, 30 = consistent with RSeQC)
# -T ## : number of threads to run on (default =1)
# -R : output read counting assignments of each read into a .featureCounts file
# --ignoreDup : ignores any reads marked as duplicates
# -p : fragments rather than reads counted for paired-end data.
# -d ## : minimum fragment/template legnth (default: 50) -> only if using -P parameter too
# -D ## : maximum fragment/template length (default 600) -> only if using -P parameter too
# -B : only reads with both ends mapping considered
# -C : reads with ends mapping to different Chrs excluded
mkdir -p $WORKINGDIR
cd $WORKINGDIR

OUTPUTFILE=$(basename "${INPUTBAM%.bam}.fragmentcounts")
$featureCOUNT -O -M -T $NUMTHREADS -a $ANNOTATIONgtf -o $OUTDIR/$OUTPUTFILE $INPUTBAM #yes multimap, single end, no quality threshold
#$featureCOUNT -O -M -T $NUMTHREADS -a $ANNOTATIONgtf -o $OUTDIR/$OUTPUTFILE $INPUTBAM #allow multimap, single end, no quality threshold
#$featureCOUNT -O -M -Q 30 -T $NUMTHREADS -p -a $ANNOTATIONgtf -o $OUTDIR/$OUTPUTFILE $INPUTBAM #allow multimap
#$featureCOUNT -Q 30 -T $NUMTHREADS -p -a $ANNOTATIONgtf -o $OUTDIR/$OUTPUTFILE $INPUTBAM #no multimap
rm temp*
cd ..
rmdir $WORKINGDIR
