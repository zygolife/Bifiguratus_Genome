#!/bin/bash -l
#SBATCH --nodes 1 --ntasks 16 --mem 48gb -J shovill --out logs/AAFTF_shovill.%a.log -p batch --time 64:00:00

# this load $SCRATCH variable
module load workspace/scratch
MEM=48
CPU=$SLURM_CPUS_ON_NODE
if [ -z $CPU ]; then
 CPU=2
fi

N=${SLURM_ARRAY_TASK_ID}

if [ -z $N ]; then
    N=$1
    if [ -z $N ]; then
        echo "Need an array id or cmdline val for the job"
        exit
    fi
fi

OUTDIR=input

SAMPLEFILE=samples.csv
ASM=asm/shovill
MINLEN=500
WORKDIR=working_AAFTF

IFS=, # set the delimiter to be ,
sed -n ${N}p $SAMPLEFILE | while read STRAIN BASE FAMILY PHYLUM
do
    ASMFILE=$ASM/${STRAIN}.spades.fasta
    VECCLEAN=$ASM/${STRAIN}.vecscreen.fasta
    PURGE=$ASM/${STRAIN}.sourpurge.fasta
    CLEANDUP=$ASM/${STRAIN}.rmdup.fasta
    PILON=$ASM/${STRAIN}.pilon.fasta
    SORTED=$ASM/${STRAIN}.sorted.fasta
    STATS=$ASM/${STRAIN}.sorted.stats.txt
    STATS=$ASM/${STRAIN}.sorted.stats.txt
    LEFT=$WORKDIR/${BASE}_filtered_1.fastq.gz
    RIGHT=$WORKDIR/${BASE}_filtered_2.fastq.gz

    if [ ! -f $ASMFILE ]; then    
	if [ ! -f $LEFT ]; then
	    echo "Cannot find LEFT $LEFT or RIGHT $RIGHT - did you run"
	    echo "$INDIR/${BASE}_R1.fq.gz $INDIR/${BASE}_R2.fq.gz"
	    exit
	fi
	module load shovill
	shovill --cpu $CPU --ram $MEM --outdir $WORKDIR/shovill_${BASE} \
		--R1 $LEFT --R2 $RIGHT --nocorr --depth 90 --tmpdir $SCRATCH --minlen $MINLEN
	module unload shovill
	if [ -f $WORKDIR/shovill_${BASE}/contigs.fa ]; then
	    rsync -av $WORKDIR/shovill_${BASE}/contigs.fa $ASMFILE
	else	
	    echo "Cannot find $WORKDIR/shovill_${BASE}/contigs.fa"
	fi
	
	if [ -s $ASMFILE ]; then
	    rm -rf $WORKDIR/shovill_${BASE}
	else
	    echo "SPADES must have failed, exiting"
	    exit
	fi
    fi
    module load AAFTF
    
    if [ ! -f $VECCLEAN ]; then
	AAFTF vecscreen -i $ASMFILE -c $CPU -o $VECCLEAN 
    fi
    
    if [ ! -f $PURGE ]; then
	AAFTF sourpurge -i $VECCLEAN -o $PURGE -c $CPU --phylum $PHYLUM --left $LEFT  --right $RIGHT
    fi
    
    if [ ! -f $CLEANDUP ]; then
	AAFTF rmdup -i $PURGE -o $CLEANDUP -c $CPU -m $MINLEN
    fi
    
    if [ ! -f $PILON ]; then
	AAFTF pilon -i $CLEANDUP -o $PILON -c $CPU --left $LEFT  --right $RIGHT 
    fi
    
    if [ ! -f $PILON ]; then
	echo "Error running Pilon, did not create file. Exiting"
	exit
    fi
    
    if [ ! -f $SORTED ]; then
	AAFTF sort -i $PILON -o $SORTED
    fi
    
    if [ ! -f $STATS ]; then
	AAFTF assess -i $SORTED -r $STATS
    fi
done
