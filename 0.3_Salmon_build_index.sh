#!/bin/bash

# Raw genome fasta and annotation gtf files
FA=/lustre/scratch108/compgen/team218/TA/genomebuilding/Mus_musculus.GRCm38.dna.primary_assembly.fa
GTF=/lustre/scratch108/compgen/team218/TA/genomebuilding/Mus_musculus.GRCm38.79.gtf

# Location for output
OUTDIR=/lustre/scratch108/compgen/team218/TA/STRIPED_GENOMES

# Location of required software
GFFREAD=/nfs/users/nfs_t/ta6/RNASeqPipeline/software/cufflinks-2.2.1.Linux_x86_64/gffread
SALMON=/nfs/users/nfs_t/ta6/RNASeqPipeline/software/Salmon-0.7.2_linux_x86_64/bin/salmon 

# Extract transcriptome fasta
$GFFREAD $GTF -g $FA -w $OUTDIR/Transcripts.fasta

# Build index (single thread) for optimal mapping performance
$SALMON index -i $OUTDIR/salmon_index -t $OUTDIR/Transcripts.fasta --perfectHash -p 1

