#!/bin/bash
# NOT TESTED

INPUTDIR=/lustre/scratch108/compgen/team218/TA/RNASeqFilesMapped/Beuttner_STAR/Beuttner_STAR_dedup/Deduplicated/
OUTDIR=/lustre/scratch108/compgen/team218/TA/RNASeqFilesQuantified/Buettner_FeatureCounts
mkdir -p $OUTDIR
ANNOTATIONgtf="/lustre/scratch108/compgen/team218/TA/genomebuilding/Mus_musculus.GRCm38.79.gtf"
featureCOUNT=/nfs/users/nfs_t/ta6/RNASeqPipeline/software/subread-1.4.6-p2-Linux-x86_64/bin/featureCounts
NUMTHREADS=1

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

if [ ! $NUMTHREADS -gt 0 ] ; then
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


for INPUTBAM in $INPUTDIR/*.bam ; do
  OUTPUTFILE=$(basename "${INPUTBAM%.bam}.fragmentcounts")
  $featureCOUNT -O -M -Q 30 -T $NUMTHREADS -p -a $ANNOTATIONgtf -o $OUTDIR/$OUTPUTFILE $INPUTBAM #allow multimap
  #$featureCOUNT -T $NUMTHREADS -p -a $ANNOTATIONgtf -o $OUTDIR/$OUTPUTFILE $INPUTBAM #No multimap
  rm temp*
done
