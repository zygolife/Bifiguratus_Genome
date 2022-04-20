#!/usr/bin/bash -l
#SBATCH -p batch 
module load canu

mkdir -p logs

IFS=,
SAMPLES=nanopore_samples.csv
OUTDIR=asm/canu
INDIR=input/nanopore
mkdir -p $OUTDIR
while read STRAIN NANOPORE ILLUMINA
do
    canu -p $STRAIN -d $OUTDIR/$STRAIN genomeSize=45m useGrid=true -nanopore $INDIR/$NANOPORE
done < $SAMPLES

