#!/bin/bash
RSEMdir=/nfs/users/nfs_t/ta6/RNASeqPipeline/software/RSEM-1.2.26
OUTDIR=/lustre/scratch108/compgen/team218/TA/STRIPED_GENOMES/RSEM/
REFname=GRCm38
GenomeGTF=/lustre/scratch108/compgen/team218/TA/genomebuilding/Mus_musculus.GRCm38.79.gtf
GenomeFASTA=/lustre/scratch108/compgen/team218/TA/genomebuilding/Mus_musculus.GRCm38.dna.primary_assembly.fa
BOWTIEpath=/nfs/users/nfs_t/ta6/RNASeqPipeline/software/bowtie2-2.2.6/
STARpath=/nfs/users/nfs_t/ta6/RNASeqPipeline/software/STAR-STAR_2.4.0j/bin/Linux_x86_64_static/

$RSEMdir/rsem-prepare-reference --gtf $GenomeGTF --bowtie2 --bowtie2-path $BOWTIEpath $GenomeFASTA $OUTDIR/$REFname
$RSEMdir/rsem-prepare-reference --gtf $GenomeGTF --star --star-path $STARpath $GenomeFASTA $OUTDIR/$REFname
