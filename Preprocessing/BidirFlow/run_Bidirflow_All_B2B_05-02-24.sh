#!/bin/bash
#SBATCH --job-name=superbam
#SBATCH --output=/scratch/Users/hoto7260/nextflow_out/Bidir/e_and_o/BidirHOPE_%j.out
#SBATCH --error=/scratch/Users/hoto7260/nextflow_out/Bidir/e_and_o/BidirHOPE_%j.out
#SBATCH --time=180:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=42
#SBATCH --mem=50G
#SBATCH --partition long
#SBATCH --mail-type=ALL
#SBATCH --mail-user=hoto7260@colorado.edu

module load samtools/1.8
module load bedtools/2.28.0
module load openmpi/1.6.4
module load gcc/7.1.0
module load python/3.6.3
module load R/3.6.1

 
 ## Clear the wokring directory
 rm -rf /scratch/Users/hoto7260/nextflow_out/Bidir/tmp/*
 
 ## Get the temporary spot to store the crams
cp /Shares/dbnascent/Gally2020gain/crams/SRR12482692* /scratch/Users/hoto7260/tmp/crams/
cp /Shares/dbnascent/Gally2020gain/crams/SRR12482693* /scratch/Users/hoto7260/tmp/crams/
cp /Shares/dbnascent/Sasse2019nascent/crams/* /scratch/Users/hoto7260/tmp/crams/

# check plenty of crams
ls /scratch/Users/hoto7260/tmp/crams/

ls /scratch/Users/hoto7260/tmp/crams/ | wc -l
 
 ## Run your code
 /Users/hoto7260/src/nextflow run /Users/hoto7260/Flows/Bidirectional-Flow/main_hope.nf -profile hg38 \
 --crams "/scratch/Users/hoto7260/tmp/crams/*cram" \
 --workdir "/scratch/Users/hoto7260/nextflow_out/Bidir/tmp/" \
 --singleEnd \
 --outdir "/scratch/Users/hoto7260/nextflow_out/Bidir/All_B2B/" \
 --tfit_3prime \
 --tfit_split_model \
 --savebg 
 
# clear the temporary crams directory
rm /scratch/Users/hoto7260/tmp/crams/*



