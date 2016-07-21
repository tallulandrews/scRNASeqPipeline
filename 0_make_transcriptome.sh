#!/bin/bash
STAR=/nfs/users/nfs_t/ta6/RNASeqPipeline/software/STAR-STAR_2.4.0j/bin/Linux_x86_64_static/STAR

FA=/lustre/scratch108/compgen/team218/TA/genomebuilding/Nascent_Transcripts.fa
GTF=/lustre/scratch108/compgen/team218/TA/genomebuilding/Nascent_Transcripts.gtf

bsub -R"select[mem>37000] rusage[mem=37000]" -M37000 -o buildtranscriptome.out -e buildtranscriptome.err $STAR --runMode genomeGenerate --genomeDir /lustre/scratch108/compgen/team218/TA/STRIPED_GENOMES/NeuronsLiora --genomeFastaFiles $FA --sjdbGTFfile $GTF --sjdbOverhang 20 --limitGenomeGenerateRAM 36000000000
