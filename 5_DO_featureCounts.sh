#!/bin/bash

INPUTDIR=/lustre/scratch108/compgen/team218/TA/Bergiers_Wafergen/BigFilesMappedDeDupped
INPUTFILES=($INPUTDIR/*.bam)
NUMFILES=${#INPUTFILES[@]}
MAXJOBS=$NUMFILES
OUTDIR=/lustre/scratch108/compgen/team218/TA/Bergiers_Wafergen/BigFilesMappedDedupedCounted
TMPDIR=/lustre/scratch108/compgen/team218/TA/Pipeline_RunningDir/FeatureCounts
mkdir -p $OUTDIR
ANNOTATIONgtf="/lustre/scratch108/compgen/team218/TA/genomebuilding/Bergiers_Transcripts.gtf"
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

bsub -J"featurecountsjobarray[1-$MAXJOBS]%100" -R"select[mem>5000] rusage[mem=5000]" -M5000 -q normal -o FCoutput.%J.%I /nfs/users/nfs_t/ta6/RNASeqPipeline/5_featureCounts_wrapper.sh $ANNOTATIONgtf $NUMTHREADS $INPUTDIR $TMPDIR $OUTDIR
