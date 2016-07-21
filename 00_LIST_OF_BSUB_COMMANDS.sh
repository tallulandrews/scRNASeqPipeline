#!/bin/bash
ORGANISM="Mmus"
RUNNINGDIR=`pwd`

#### Create GTF & FA for construct
/nfs/users/nfs_t/ta6/RNASeqPipeline/0_GBK2FASTA.pl
/nfs/users/nfs_t/ta6/RNASeqPipeline/software/cufflinks-2.2.1.Linux_x86_64/gffread --help

#-----------------------------------------------------------------
# Initial QC
# This is not generalized
# When & on what do I want to run this?
QCDIR=/lustre/scratch108/compgen/team218/TA/QualityControl
mkdir -p $QCDIR

#cd $QCDIR
#bsub -R"select[mem>150] rusage[mem=150]" -M150 -o fastqcout.%J -e fastqcout.%J -q normal /nfs/users/nfs_t/ta6/RNASeqPipeline/0_FASTQC.sh C6H8GANXX_C1_IB_8TFs_exp1_15s009116-2-1_Bergiers_lane615s009116E10_1_sequence.txt.gz

#cd $RUNNINGDIR
# These don't like running in parallel for some reason...
bsub -R"select[mem>10000] rusage[mem=10000]" -M10000 -q normal -o output.%J -e error.%J ../0_FASTQC_Streaming.sh  /lustre/scratch108/compgen/team218/TA/RNASeqFilesToMap *lane5*1.1.fq.gz Bergiers_lane5_end1 /lustre/scratch108/compgen/team218/TA/QualityControl/
bsub -R"select[mem>10000] rusage[mem=10000]" -M10000 -q normal -o output.%J -e error.%J ../0_FASTQC_Streaming.sh  /lustre/scratch108/compgen/team218/TA/RNASeqFilesToMap *lane5*2.1.fq.gz Bergiers_lane5_end2 /lustre/scratch108/compgen/team218/TA/QualityControl/
bsub -R"select[mem>10000] rusage[mem=10000]" -M10000 -q normal -o output.%J -e error.%J ../0_FASTQC_Streaming.sh  /lustre/scratch108/compgen/team218/TA/RNASeqFilesToMap *lane6*1.1.fq.gz Bergiers_lane6_end1 /lustre/scratch108/compgen/team218/TA/QualityControl/
bsub -R"select[mem>10000] rusage[mem=10000]" -M10000 -q normal -o output.%J -e error.%J ../0_FASTQC_Streaming.sh  /lustre/scratch108/compgen/team218/TA/RNASeqFilesToMap *lane6*2.1.fq.gz Bergiers_lane6_end2 /lustre/scratch108/compgen/team218/TA/QualityControl/
#-----------------------------------------------------------------

#Set up genome for mapping
WORKINGDIR=/lustre/scratch108/compgen/team218/TA/genomebuilding
GENOMEDIR=/lustre/scratch108/compgen/team218/TA/STRIPED_GENOMES
LOG="GenomeBuildingLog$ORG.tar.gz"

bsub -R"select[mem>35000] rusage[mem=35000]" -M35000 -q normal -o $WORKINGDIR/FarmJobOutput.%J -e $WORKINGDIR/FarmJobErrors.%J /nfs/users/nfs_t/ta6/RNASeqPipeline/0_BuildGenome.sh $WORKINGDIR $GENOMEDIR 1 125 $ORGANISM /nfs/users/nfs_t/ta6/Collaborations/Bergiers_Italy 
tar -zcf $LOG $WORKINGDIR # Or should I just delete it?
#-----------------------------------------------------------------

#Breakdown files for mapping 
#Note these are not particularly well designed (eg. everything is currently hard coded not passed as an argument)
# in particular the latter one tends to crash if my computer goes to sleep or something.....
# and the former one should really submit the jobs as a jobarray rather than in packs of 40 then waiting 5 minutes.
#perl 1_breakdown_all_files_parallel_not_general.pl #Calls 1_Breakdown_PairedEnds.pl
#perl 1_Compress_Broken_Down_FASTQ_and_Cell_Specific_Files_forQC.pl

OUTPUTDIR=/lustre/scratch108/compgen/team218/TA/RNASeqFilesToMap/
mkdir -p $OUTPUTDIR
INPUTDIR=/nfs/team218/MH/2015-03-02-C6H8GANXX/2015-03-02-C6H8GANXX/
PATTERN="*exp2*_sequence.txt.gz"
INPUTFILES=($INPUTDIR/$PATTERN)
NUMFILES=${#INPUTFILES[@]}
MAXJOBS=$(($NUMFILES))
bsub -J"mappingwithstararrayjob[1-$MAXJOBS]%40" -R"select[mem>4000] rusage[mem=4000]" -M4000 -q normal -o output.%J.%I /nfs/users/nfs_t/ta6/RNASeqPipeline/1_BreakDown_Files_wrapper.sh 100000000 "$INPUTDIR" "$PATTERN2" $OUTPUTDIR

#-----------------------------------------------------------------
#Map all FastQfiles using job array
# Note job array requires indexing to start at 1 but array indexing starts at 0
# 2_MapReadsFile.sh arguments: NThreads, directory of files to map, directory for output, STAR Parameter file, outputfile prefix
# things I must test for this bit: (1) memory allocation is sufficient, (2) indices include all the files in the directory, 
# This set found in 2_DO_MapReadsFile.sh

OUTPUTDIR=/lustre/scratch108/compgen/team218/TA/RNASeqFilesMapped/
mkdir -p $OUTPUTDIR
INPUTDIR=/lustre/scratch108/compgen/team218/TA/RNASeqFilesToMap/
INPUTFILES=($INPUTDIR/*)
NUMFILES=${#INPUTFILES[@]}
MAXJOBS=$(($NUMFILES/2))
TAG="Bergiers_Exp1"
bsub -J"mappingwithstararrayjob[1-$MAXJOBS]%40" -R"select[mem>30000] rusage[mem=30000]" -M30000 -q normal -o output.%J.%I /nfs/users/nfs_t/ta6/RNASeqPipeline/2_MapReadsFile.sh 1 $INPUTDIR $OUTPUTDIR /nfs/users/nfs_t/ta6/RNASeqPipeline/2_STAR_Parameters.txt $TAG
#%40 restricts it to running 40 elements at the same time, from the 100 element job array. all outputfiles will have the same job id (%J) but different indexes (%I)

# STAR Output files: 
	# Log.out = stuff about defining parameters & reading in genome, should be identical except for input files for all jobs
	# Log.progress.out = speed & proportion mapped/unmapped at various points while running (not particularly useful once job has finished)
	# Log.final.out = summary statistics after all reads have been attempted to be mapped.
	# SJ.out.tab = table of identified splice junctions.

#-----------------------------------------------------------------
#Summarize mapping output!, %mapped, %uniquely mapped, etc...
# This set found in 3_CLEANUP_MapReadFiles.sh
perl /nfs/users/nfs_t/ta6/RNASeqPipeline/3_Compile_Mapping_Statistics.pl $OUPUTDIR > /nfs/users/nfs_t/ta6/RNASeqPipeline/$TAG.mapped_summary.out
rm $OUTPUTDIR/*.Log.progress.out
tar -cvzf $OUTPUTDIR/ParameterLogfiles.tar.gz  $OUTPUTDIR/*Log.out
tar -cvzf $OUTPUTDIR/SpliceJunctionfiles.tar.gz  $OUTPUTDIR/*SJ.out.tab
tar -cvzf $OUTPUTDIR/FinalLogfiles.tar.gz  $OUTPUTDIR/*Log.final.out
rm $OUTPUTDIR/*Log.out
rm $OUTPUTDIR/*SJ.out.tab
rm $OUTPUTDIR/*Log.final.out

#-----------------------------------------------------------------
#Combine & sort using samtools -> on largest bam used 2000Mb & took 105 sec (2 Apr 2014)
# Not necessary now changed STAR parameters to do the sorting.
perl 3_SortBAMs.pl #all hard coded at the moment not flexible. Runs each job on cluster

#bsub -R"select[mem>3000] rusage[mem=3000]" -M3000 -q normal -o testsamtoolssort.%J samtools sort -m 3000000000 Bergiers_lane515s009116E9_exp1_1:N:0:AAGAGGCAAAGGAGTA_1.1Aligned.out.bam Bergiers_lane515s009116E9_exp1_1:N:0:AAGAGGCAAAGGAGTA_1.1Aligned.out.sorted

#-----------------------------------------------------------------
# This set (merge & reorganize) found in 3_merge_dedup_MappedReads.sh
#Merge & de-dup
bsub -q normal -o MergeBAMs_job.output perl 4_MergeBAMS.pl $OUTPUTDIR $TAG

# Reorganize files
MappedDedupDIR=$OUTPUTDIR/Deduplicated
MappedWdupDIR=$OUTPUTDIR/WithDuplicates
mkdir -p $MappedDedupDIR
mkdir -p $MappedWdupDIR
mv $OUTPUTDIR/*dedup* $MappedDedupDIR
mv $OUTPUTDIR/*sorted.bam $MappedWdupDIR
tar -cvzf Bergiers_exp1_mapping_output.tar.gz $OUTPUTDIR/Bergiers*exp1*
rm $OUTPUTDIR/Bergiers_lane*
# ----------------------------------------------------------------

#QC with RSeQC - sample command to test is working
python /nfs/users/nfs_t/ta6/RNASeqPipeline/software/RSeQC-2.6.1/scripts/clipping_profile.py -i Bergiers_exp1_TAGGCATGCTCTCTAT.sorted.dedupped.bam -o test
# rRNA/mt-mRNA content 
bsub -q normal -o RSeQC.output perl 4_RSeQC.pl #As add further tests to be done make this parallelized 
bsub -R"select[mem>1000] rusage[mem=1000]" -M1000 -q normal -o /lustre/scratch108/compgen/team218/TA/TEST/RSEQC_test.output /nfs/users/nfs_t/ta6/RNASeqPipeline/4_RSeQC_Multiple.sh Mmus /lustre/scratch108/compgen/team218/TA/RNASeqFilesMapped/Deduplicated/Bergiers_exp1_TCCTGAGCTCTCTCCG.sorted.dedupped.bam /lustre/scratch108/compgen/team218/TA/TEST/RSEQC_test 1

# Now used 4_DO_RSeQC_Multiple.sh

#-----------------------------------------------------------------
# de novo transcript assembly using all data:
bsub -q normal -o mergingallbams.out samtools merge /lustre/scratch108/compgen/team218/TA/RNASeqFilesMapped/Deduplicated/All.dedupped.bam /lustre/scratch108/compgen/team218/TA/RNASeqFilesMapped/Deduplicated/*.bam
# took ~2h to complete

#quantify transcripts using cufflinks & feature count

# Cufflinks on everything on 10 processors used just over 10GB and on normal queue got about halfway done (12h limit). 
bsub  -R"select[mem>20000] rusage[mem=20000] span[ptile=10]" -M20000 -n 10 -q long -o cufflinkseverything.output -e cufflinkseverything.error /nfs/users/nfs_t/ta6/RNASeqPipeline/software/cufflinks-2.2.1.Linux_x86_64/cufflinks --GTF-guide /lustre/scratch108/compgen/team218/TA/genomebuilding/Mus_musculus.GRCm38.79.gtf --frag-bias-correct /lustre/scratch108/compgen/team218/TA/genomebuilding/Mus_musculus.GRCm38.dna.primary_assembly.fa --mask-file /lustre/scratch108/compgen/team218/TA/TemporaryFileDir/Mmus-rRNAtRNAmtmRNAs-mask.gtf --multi-read-correct --max-intron-length 1000000 --min-intron-length 20 -o /lustre/scratch108/compgen/team218/TA/RNASeqFilesQuantified --quiet --no-update-check --seed 100 --num-threads 10 --no-faux-reads /lustre/scratch108/compgen/team218/TA/RNASeqFilesMapped/Deduplicated/All.dedupped.bam
#-----------------------------------------------------------------
# Expression Level Quantification
bsub  -R"select[mem>1500] rusage[mem=1500]" -M1500 -q normal -o Cuffoutput.%J -e Cufferror.%J /nfs/users/nfs_t/ta6/RNASeqPipeline/software/cufflinks-2.2.1.Linux_x86_64/cufflinks --GTF-guide $Somecombinedannotationfile --frag-bias-correct /lustre/scratch108/compgen/team218/TA/genomebuilding/Mus_musculus.GRCm38.dna.primary_assembly.fa --mask-file /lustre/scratch108/compgen/team218/TA/TemporaryFileDir/Mmus-rRNAtRNAmtmRNAs-mask.gtf --multi-read-correct --max-intron-length 1000000 --min-intron-length 20 -o /lustre/scratch108/compgen/team218/TA/RNASeqFilesQuantified --quiet --no-update-check --seed $somerandomseed --num-threads 1 $Cellbasedbamfile

bsub 5_featureCounts_warpper.sh $Somecombinedannotationfile 1 $Cellbasedbamfile


# RSEM
bsub -R"select[mem>10000] rusage[mem=10000]" -M10000 -q normal -o RSEMbuildref.%J.out -e RSEMbuildref.%J.err /nfs/users/nfs_t/ta6/RNASeqPipeline/5_RSEM_build_refrence.sh
