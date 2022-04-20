#!/usr/bin/bash -l

#SBATCH --nodes 1 --ntasks 24 --mem 24G -p short -J readcount --out logs/bbcount.%a.log --time 2:00:00
module load BBMap
hostname
MEM=24
CPU=$SLURM_CPUS_ON_NODE
N=${SLURM_ARRAY_TASK_ID}

if [ ! $N ]; then
    N=$1
    if [ ! $N ]; then
        echo "Need an array id or cmdline val for the job"
        exit
    fi
fi

INDIR=input/illumina
SAMPLEFILE=samples.csv
BASE=$(sed -n ${N}p $SAMPLEFILE | cut -f2 -d,)
FULL=$(sed -n ${N}p $SAMPLEFILE | cut -f1 -d,)

ASM=genomes
OUTDIR=mapping_report
SORTED=$(realpath $ASM/${FULL}.sorted.fasta)

LEFT=$(ls $INDIR/${BASE}_R1_001.fastq.gz)
LEFT=$(realpath $LEFT)
RIGHT=$(ls $INDIR/${BASE}_R2_001.fastq.gz)
RIGHT=$(realpath $RIGHT)
echo "$LEFT $RIGHT"
mkdir -p $OUTDIR
if [ ! -s $OUTDIR/${BASE}.bbmap_covstats.txt ]; then
	mkdir -p N$N.$$.bbmap
	pushd N$N.$$.bbmap
	bbmap.sh -Xmx${MEM}g ref=$SORTED in=$LEFT in2=$RIGHT covstats=../$OUTDIR/${BASE}.bbmap_covstats.txt  statsfile=../$OUTDIR/${BASE}.bbmap_summary.txt
	popd
	rm -rf N$N.$$.bbmap
fi
SORTED=$(realpath $ASM/${BASE}.sorted_shovill.fasta)
BASE=${BASE}_shovill
if [ ! -s $OUTDIR/${BASE}.bbmap_covstats.txt ]; then
        mkdir -p N$N.$$.bbmap
        pushd N$N.$$.bbmap
        bbmap.sh -Xmx${MEM}g ref=$SORTED in=$LEFT in2=$RIGHT covstats=../$OUTDIR/${BASE}.bbmap_covstats.txt  statsfile=../$OUTDIR/${BASE}.bbmap_summary.txt
        popd
        rm -rf N$N.$$.bbmap
fi
