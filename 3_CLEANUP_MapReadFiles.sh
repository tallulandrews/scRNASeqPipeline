#!/bin/bash
# Copy of commands in 00_LIST_OF_BSUB_COMMANDS.sh to break it down into steps.
# Run this after mapping is finished.

# These must be consistent with 2_DO_MapReadsFile.sh
OUTPUTDIR=/lustre/scratch108/compgen/team218/TA/Bergiers_Wafergen/BigFilesMappedTranscriptome
TAG="Trimmed50-Bergiers_Waf375"

rm $OUTPUTDIR/*Log.progress.out

perl /nfs/users/nfs_t/ta6/RNASeqPipeline/3_Compile_Mapping_Statistics.pl $OUTPUTDIR > /lustre/scratch108/compgen/team218/TA/Bergiers_Wafergen/$TAG.mapped_summary.out

tar -cvzf $OUTPUTDIR/$TAG.ParameterLogfiles.tar.gz  $OUTPUTDIR/*Log.out
tar -cvzf $OUTPUTDIR/$TAG.SpliceJunctionfiles.tar.gz  $OUTPUTDIR/*SJ.out.tab
tar -cvzf $OUTPUTDIR/$TAG.FinalLogfiles.tar.gz  $OUTPUTDIR/*Log.final.out
rm $OUTPUTDIR/*Log.out
rm $OUTPUTDIR/*SJ.out.tab
rm $OUTPUTDIR/*Log.final.out
