#!/bin/bash
#This should be flexible enough to get the commonly used genomes: human, mouse, fly, worm from ensembl, and have options to add genetic constructs that have been integrated into the system.

# Tallulah 07 April 2015 - added the option to just keep the GTF & Fasta files without running STAR by setting the number of threads to 0 (for getting the genome & annotations for Cufflinks later).
# Tallulah 31 March 2015 - updated to check all 5/6 arguments (which are required) have been set.
# Tallulah 26 Mar 2015 Not so obvious whether it is more efficient to get genomes from internal ensembl mirror or to download from ensembl ftp website? -> since only doing this once per organism/experiment ftp/rsync is probably fine?
# All bits tested but not all at once - Totally works now (13 Dec 2016)

# Arguments: 
#    $1 = working directory on /lustre/
#    $2 = striped genome directory on /lustre/
#    $3 = number of threads to run on, # if 0 does not run star
#    $4= readlength, 
#    $5 = organism [Hsap, Mmus, Dmel, Cele]; 
#    $6 = directory with constructs to be added (optional)

NUMTHREADS=$3
OVERHANG=$4-1 #read length-1
ORG=$5
ADDDIR=$6
ORGERR="please enter one of the following organism tags: Hsap, Mmus"
STAR=/nfs/users/nfs_t/ta6/RNASeqPipeline/software/STAR-STAR_2.4.0j/bin/Linux_x86_64_static/STAR
LUSTRE=$1
OUTDIR=$2



if [ ! -f "$STAR" ] ; then
  echo "Sorry STAR not available "
  exit 1
fi

if [ -z "$LUSTRE" ] ; then
  echo "Please set a directory for temporary working files (ARG 1/6)"
  exit 1
fi

if [ -z "$OUTDIR" ] ; then
  echo "Please set a directory for output (ARG 2/6)"
  exit 1
fi

if [ -z "$NUMTHREADS" ] ; then
  echo "Please set number of threads to use (ARG 3/6)"
  exit 1
fi

if [ -z "$OVERHANG" ] ; then
  echo "Please set length of RNASeq reads (ARG 4/6)"
  exit 1
fi

if [ -z "$ORG" ] ; then
  echo "Sorry no organism to work with (ARG 5/6)"
  echo $ORGERR
  exit 1
fi

# Make directories for output/temporary working files if they don't already exist
if [ ! -d "$OUTDIR" ] ; then
  mkdir -p $OUTDIR
  lfs setstripe $OUTDIR -c -1
fi

mkdir -p $LUSTRE

FA="";GTF="";
# Step 1: Get genome & annotations from Ensembl and put on lustre
if [ $ORG = "Hsap" ]; then
  # Genome fastas
  rsync -av rsync://ftp.ensembl.org/ensembl/pub/release-79/fasta/homo_sapiens/dna/Homo_sapiens.GRCh38.dna.primary_assembly.fa.gz $LUSTRE
  # Annotation GTFs
  rsync -av rsync://ftp.ensembl.org/ensembl/pub/release-79/gtf/homo_sapiens/Homo_sapiens.GRCh38.79.gtf.gz $LUSTRE
  FA=$LUSTRE/Homo_sapiens.GRCh38.dna.primary_assembly.fa.gz
  GTF=$LUSTRE/Homo_sapiens.GRCh38.79.gtf.gz
elif [ $ORG = "Mmus" ]; then
  # Genome fastas
  rsync -av rsync://ftp.ensembl.org/ensembl/pub/release-79/fasta/mus_musculus/dna/Mus_musculus.GRCm38.dna.primary_assembly.fa.gz $LUSTRE
  # Annotation GTFs
  rsync -av rsync://ftp.ensembl.org/ensembl/pub/release-79/gtf/mus_musculus/Mus_musculus.GRCm38.79.gtf.gz $LUSTRE
  FA=$LUSTRE/Mus_musculus.GRCm38.dna.primary_assembly.fa.gz 
  GTF=$LUSTRE/Mus_musculus.GRCm38.79.gtf.gz
else
  echo "$ORG not supported"
  echo $ORGERR
  exit 1
fi

# Step 2: Add genetic constructs from a directory
# Question? Should we add the genetic construct as an additional chromosome or try to place it correctly in the genome?
		# placing it in the genome would affect the locations of all other elements on that chromosome
		# expression from the construct should be independent of that of the surrounding genome so don't expect any 
		# reads to span to neighbouring genes -> depends on the construct 
		# what about things added to the tail of a native locus?  
		# Couldn't this be dealt with by adding the full new locus as a separate thing and somehow masking the native locus?

	# OK I think adding constructs as separate contigs is the best approach!
		# If I assume the constructs have been pre-formatted to be fasta & gtfs, 
		# can the fasta just be added to the stock & gtf just concatenated to the current one? 
		# -> yes as long as names are consistent across the files and not the same as any other chromosome/contig

gunzip $FA
FA=${FA%.*}
gunzip $GTF
GTF=${GTF%.*}
if [ ! -z "$ADDDIR" ] ; then
  echo "Adding files from $ADDDIR"
  cat $ADDDIR/*.fa >> $FA
  cat $ADDDIR/*.gtf >> $GTF
fi

if [ $NUMTHREADS -gt 0 ] ; then
  # Step 3: Run STAR on the finished genome & put output in striped directory.
  $STAR --runThreadN $NUMTHREADS --runMode genomeGenerate --genomeDir /lustre/scratch117/cellgen/team218/TA/STRIPED_GENOMES --genomeFastaFiles $FA --sjdbGTFfile $GTF --sjdbOverhang $OVERHANG --limitGenomeGenerateRAM 31000000000

  # Step 4: delete the Ensembl-derived files
#  rm $FA
#  rm $GTF
fi
