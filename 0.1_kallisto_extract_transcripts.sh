#!/bin/bash
#This should be flexible enough to get the commonly used genomes: human, mouse, fly, worm from ensembl, and have options to add genetic constructs that have been integrated into the system.

# Tallulah 07 April 2015 - added the option to just keep the GTF & Fasta files without running GFFREAD by setting the number of threads to 0 (for getting the genome & annotations for Cufflinks later).
# Tallulah 31 March 2015 - updated to check all 5/6 arguments (which are required) have been set.
# Tallulah 26 Mar 2015 Not so obvious whether it is more efficient to get genomes from internal ensembl mirror or to download from ensembl ftp website? -> since only doing this once per organism/experiment ftp/rsync is probably fine?
# All bits tested but not all at once

# Arguments: 
#    $1 = working directory on /lustre/
#    $2 = striped genome directory on /lustre/
#    $3 = number of threads to run on, # if 0 does not run star
#    $4= readlength, 
#    $5 = organism [Hsap, Mmus, Dmel, Cele]; 
#    $6 = directory with constructs to be added (optional)

FA=/lustre/scratch108/compgen/team218/TA/genomebuilding/Mus_musculus.GRCm38.dna.primary_assembly.fa
GTF=/lustre/scratch108/compgen/team218/TA/genomebuilding/Mus_musculus.GRCm38.79.gtf
OUTDIR=/lustre/scratch108/compgen/team218/TA/STRIPED_GENOMES
GFFREAD=/nfs/users/nfs_t/ta6/RNASeqPipeline/software/cufflinks-2.2.1.Linux_x86_64/gffread
KALLISTO=/nfs/users/nfs_t/ta6/RNASeqPipeline/software/kallisto_linux-v0.42.4/kallisto

echo "$GFFREAD $GTF -g $FA -w $OUTDIR/Transcripts.fasta"
echo "$KALLISTO index -i $OUTDIR/kallisto_index.idx $OUTDIR/Transcripts.fasta"

