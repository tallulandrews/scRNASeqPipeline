#!/bin/bash

if [ -z $1 ] ; then
  echo "Please set input file (ARG 1/3)"
  exit 1
fi
if [ -z $2 ] ; then
  echo "Please set an output prefix (ARG 2/3)"
  exit 1
fi
if [ -z $3 ] ; then
  echo "Please set an max memory limit (ARG 3/3)"
  exit 1
fi

samtools sort -m $3 $1 $2
rm $1
