#!/bin/bash
# Tallulah 31 Mar 2015 : wrapper for Mapping Reads with KALLISTO -> to be called from a job-array bsub command.
# Note job array requires indexing to start at 1 but array indexing starts at 0
# Maps paired reads only!

# Arguments: 
#    $1 = number of threads to run on, 
#    $2 = directory of files to map
#    $3 = outputdirectory

NUMTHREADS=$1
FILESTOMAPDIR=$2
OUTDIR=$3
INFILE=$4
KALLISTO=/nfs/users/nfs_t/ta6/RNASeqPipeline/software/kallisto_linux-v0.42.4/kallisto

#Check appropriate arguments
if [ ! -f "$KALLISTO" ] ; then
  echo "Sorry KALLISTO not available "
  exit 1
fi

if [ -z "$NUMTHREADS" ] ; then
  echo "Please set number of threads to use (ARG 1/4)"
  exit 1
fi

if [ -z "$FILESTOMAPDIR" ] ; then
  echo "Please include a directory of files to map (ARG 2/4)"
  exit 1
fi
FILEStoMAP=($FILESTOMAPDIR/*)
ARRAYINDEX=$((($LSB_JOBINDEX-1)*2))
FILE1TOMAP=${FILEStoMAP[$ARRAYINDEX]} #Note bash array indicies start at 0 but job array indices must start at 1!!!
FILE2TOMAP=${FILEStoMAP[$ARRAYINDEX+1]} #Note bash array indicies start at 0 but job array indices must start at 1!!!

NAME=${FILE1TOMAP##*/}
NAME=${NAME%.*}

if [ -z "$FILE1TOMAP" ] ; then
  echo "$ARRAYINDEX-th file in the $FILESTOMAPDIR does not exist."
  exit 1
fi

if [ -z "$FILE2TOMAP" ] ; then
  echo "$ARRAYINDEX+1-th file in the $FILESTOMAPDIR does not exist."
  exit 1
fi

if [ -z "$OUTDIR" ] ; then
  echo "Please include a directory for output (ARG 3/4)"
  exit 1
fi

if [ -z "$INFILE" ] ; then
  echo "Please include a transcript index file (ARG 4/4)"
  exit 1
fi

# Make directory for output if necessary
if [ ! -d "$OUTDIR" ] ; then
  mkdir -p $OUTDIR
fi
if [ ! -d "$OUTDIR/$LSB_JOBINDEX" ] ; then
  mkdir -p $OUTDIR/$LSB_JOBINDEX
fi

# bsub -R"select[mem>5000] rusage[mem=5000]" -M5000 -q normal -o test_kallisto_quant.out -e test_kallisto_quant.err /nfs/users/nfs_t/ta6/RNASeqPipeline/software/kallisto_linux-v0.42.4/kallisto quant --bias -b 100 --seed=1 --plaintext --threads=1 -i /lustre/scratch108/compgen/team218/TA/STRIPED_GENOMES/kallisto_index.idx /lustre/scratch108/compgen/team218/TA/RNASeqFilesToMap/G1_Cell01_1.fastq.gz /lustre/scratch108/compgen/team218/TA/RNASeqFilesToMap/G1_Cell01_2.fastq.gz -o /lustre/scratch108/compgen/team218/TA/TEST

# Run KALLISTO 
$KALLISTO quant --bias --plaintext --threads=$NUMTHREADS -i $INFILE -o $OUTDIR/$LSB_JOBINDEX $FILE1TOMAP $FILE2TOMAP 
mv $OUTDIR/$LSB_JOBINDEX/abundance.tsv $OUTDIR/$NAME.abundances.tsv
rm $OUTDIR/$LSB_JOBINDEX/run_info.json
rmdir $OUTDIR/$LSB_JOBINDEX

