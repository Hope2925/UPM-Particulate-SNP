#!/bin/bash
#SBATCH --job-name=superbam
#SBATCH --output=/scratch/Users/hoto7260/nextflow_out/Bidir/e_and_o/BidirHOPE_%j.out
#SBATCH --error=/scratch/Users/hoto7260/nextflow_out/Bidir/e_and_o/BidirHOPE_%j.out
#SBATCH --time=120:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=32
#SBATCH --mem=40G
#SBATCH --partition long
#SBATCH --mail-type=ALL
#SBATCH --mail-user=hoto7260@colorado.edu

module load samtools/1.8
module load bedtools/2.28.0
module load openmpi/1.6.4
module load gcc/7.1.0
module load python/3.6.3
module load R/3.6.1



# /Users/hoto7260/src/nextflow run /Users/hoto7260/Flows/Bidirectional-Flow/main_hope.nf -profile hg38 \
#  --bams "/scratch/Users/hoto7260/TF_bid/Length/Depth/data/bams/test/*bam" \
#  --workdir "/scratch/Users/hoto7260/nextflow_out/Bidir/tmp/" \
#  --singleEnd \
#  --outdir "/scratch/Users/hoto7260/nextflow_out/Bidir/Length_02-20-24/" \
#  --tfit_3prime \
#  --tfit_split_model \
#  --savebg 
 
 ## Clear the wokring directory
 rm -rf /scratch/Users/hoto7260/nextflow_out/Bidir/tmp/*
 
 ## Run your code
 /Users/hoto7260/src/nextflow run /Users/hoto7260/Flows/Bidirectional-Flow/main_hope.nf -profile hg38 \
 --crams "/scratch/Users/hoto7260/nextflow_out/Nascent/ADP_smAECs_03-4-24/mapped/crams/*cram" \
 --workdir "/scratch/Users/hoto7260/nextflow_out/Bidir/tmp/" \
 --singleEnd \
 --outdir "/scratch/Users/hoto7260/nextflow_out/Bidir/ADP_smAECs_03-04-24/" \
 --tfit_3prime \
 --tfit_split_model \
 --savebg 



#  --outdir "/scratch/Users/hoto7260/nextflow_out/Bidir/Length_02-15-24/"