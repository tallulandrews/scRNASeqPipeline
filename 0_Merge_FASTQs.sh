#!/bin/bash
# Merge read files for paired-end sequencing across two lanes, where files are ordered by lane, then cell, then read
FASTQDIR=$1
OUTDIR=$2
NCELLS=$3

#LSB_JOBINDEX=1 #Testing

# Maths
NFILES=$(($NCELLS*2))
INDEX1=$(($LSB_JOBINDEX-1))
INDEX2=$(($INDEX1+$NFILES))

FILES=($FASTQDIR/*.gz)
FILE1=${FILES[$INDEX1]}
FILE2=${FILES[$INDEX2]}

echo $FILE1
echo $FILE2
TAIL='_1.fq'
CELLID=$LSB_JOBINDEX;
if !((CELLID % 2)); then
	CELLID=$(($CELLID/2))
else 
	CELLID=$(( ($CELLID+1)/2 ))
fi

if [[ $FILE1 =~ _1.f ]] ; then
	OUTFILE=Cell$CELLID$TAIL
	zcat $FILE1 $FILE2 > $OUTDIR/$OUTFILE
else 
	TAIL='_2.fq'
	OUTFILE=Cell$CELLID$TAIL
	zcat $FILE1 $FILE2 > $OUTDIR/$OUTFILE
fi
echo $OUTFILE
gzip $OUTDIR/$OUTFILE
