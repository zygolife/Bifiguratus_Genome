#!/usr/bin/bash -l
#SBATCH -p short -N 1 -n 2 --mem 4gb --out logs/stats.log

module load AAFTF

IFS=,
NANOPORE=nanopore_samples.csv
SAMPLES=samples.csv
INDIR=asm
OUTDIR=genomes

mkdir -p $OUTDIR
cat $NANOPORE | while read STRAIN NANOPORE ILLUMINA
do
    rsync -a $INDIR/canu/$STRAIN/$STRAIN.contigs.fasta $OUTDIR/$STRAIN.canu.fasta
    rsync -a $INDIR/flye/$STRAIN/assembly.fasta $OUTDIR/$STRAIN.flye.fasta
    rsync -a $INDIR/NECAT/$STRAIN/$STRAIN/6-bridge_contigs/polished_contigs.fasta $OUTDIR/$STRAIN.necat.fasta
    for type in canu flye 
    do
    	rsync -a $INDIR/medaka/$STRAIN/$type.polished.fasta $OUTDIR/$STRAIN.${type}.medaka.fasta
	rsync -a $INDIR/pilon/$STRAIN/$type.pilon.fasta $OUTDIR/$STRAIN.$type.pilon.fasta 
	if [[ -s $OUTDIR/$STRAIN.$type.fasta ]]; then
	    if [[ ! -f $OUTDIR/$STRAIN.$type.stats.txt || $OUTDIR/$STRAIN.$type.fasta -nt $OUTDIR/$STRAIN.$type.stats.txt ]]; then
		AAFTF assess -i $OUTDIR/$STRAIN.$type.fasta -r $OUTDIR/$STRAIN.$type.stats.txt
	    fi
	fi
	# copy medka
	polishtype=medaka
	rsync -a $INDIR/$polishtype/$STRAIN/$type.polished.fasta $OUTDIR/$STRAIN.$type.$polishtype.fasta
		
	# copy pilon
	polishtype=pilon
	if [[ ! -f $OUTDIR/$STRAIN.$type.$polishtype.fasta || $INDIR/$polishtype/$STRAIN/$type.$polishtype.fasta -nt $OUTDIR/$STRAIN.$type.$polishtype.fasta ]]; then
	    AAFTF sort -i $INDIR/$polishtype/$STRAIN/$type.$polishtype.fasta -o $OUTDIR/$STRAIN.$type.$polishtype.fasta
	fi
	
	for polishtype in medaka pilon
	do
	    if [[ -s $OUTDIR/$STRAIN.${type}.$polishtype.fasta ]]; then
		if [[ ! -f $OUTDIR/$STRAIN.$type.$polishtype.stats.txt || $OUTDIR/$STRAIN.$type.$polishtype.fasta -nt $OUTDIR/$STRAIN.$type.$polishtype.stats.txt ]]; then
                    AAFTF assess -i $OUTDIR/$STRAIN.$type.$polishtype.fasta -r $OUTDIR/$STRAIN.$type.$polishtype.stats.txt
		fi
	    fi
	done
    done
    type=necat
    if [[ ! -f $OUTDIR/$STRAIN.$type.stats.txt || $OUTDIR/$STRAIN.$type.fasta -nt $OUTDIR/$STRAIN.$type.stats.txt ]]; then
    	AAFTF assess -i $OUTDIR/$STRAIN.$type.fasta -r $OUTDIR/$STRAIN.$type.stats.txt
    fi
done

cat $SAMPLES | while read STRAIN ILLUMINA FAMILY PHYLUM
do
    for type in AAFTF shovill
    do
	rsync -a $INDIR/$type/$STRAIN.sorted.fasta $OUTDIR/$STRAIN.$type.fasta
	if [[ ! -f $OUTDIR/$STRAIN.$type.stats.txt || $OUTDIR/$STRAIN.$type.fasta -nt $OUTDIR/$STRAIN.$type.stats.txt ]]; then
    	    AAFTF assess -i $OUTDIR/$STRAIN.$type.fasta -r $OUTDIR/$STRAIN.$type.stats.txt
	fi
    done
done
