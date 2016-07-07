#!/bin/bash
# Arguments:
# $1 = BAM file to map
# $2 = is paired end?
# $3 = number of threads to run on (default = 1)
RSEMdir=/nfs/users/nfs_t/ta6/RNASeqPipeline/software/RSEM-1.2.26/
TEMPdir=/lustre/scratch108/compgen/team218/TA/Pipeline_RunningDir/RSEM/TMP
BAMfile=$1
paired=$2
REFname=/lustre/scratch108/compgen/team218/TA/STRIPED_GENOMES/RSEM/GRCm38
BASEname=${BAMfile##*/}
PREFIX=${BASEname%%.*}
BAMfileOut=$TEMPdir/Out$BASEname
BAMfiltered=$TEMPdir/Filtered$BASEname
BAMfixed=$TEMPdir/Fixed$BASEname
BAMsorted=$TEMPdir/Sorted$BASEname
THREADS=$3

if [ -z "$THREADS" ] ; then
  THREADS=1
fi

mkdir -p $TEMPdir/$PREFIX

samtools view -b -f 2 $BAMfile > $BAMfiltered # read mapped in proper pair
samtools sort -n $BAMfiltered $BAMsorted

#/nfs/users/nfs_t/ta6/RNASeqPipeline/software/subread-1.4.6-p2-Linux-x86_64/bin/utilities/subtools -i $BAMsorted.bam -o $BAMsorted --informat BAM --outformat BAM --sort byname

#$RSEMdir/convert-sam-for-rsem $BAMsorted $BAMfixed

#echo "validate file"
#$RSEMdir/rsem-sam-validator $BAMsorted 

#$RSEMdir/convert-sam-for-rsem $BAMsorted.bam $BAMfileOut -T $TEMPdir/$PREFIX


#if [ $paired ] ; then
echo "$RSEMdir/rsem-calculate-expression --bam --paired-end --num-threads $THREADS --single-cell-prior --temporary-folder $TEMPdir --no-bam-output $BAMsorted.bam $REFname $PREFIX"
#else
#  $RSEMdir/rsem-calculate-expression --bam --num-threads $THREADS --single-cell-prior --temporary-folder $TEMPdir --no-bam-output $BAMfileTmp $REFname $PREFIX
#fi

#rm $BAMfileTmp
