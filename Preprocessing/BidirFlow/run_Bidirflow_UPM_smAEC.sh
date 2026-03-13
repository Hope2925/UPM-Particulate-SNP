#!/bin/bash
#SBATCH --job-name=bidirflow
#SBATCH --output=/scratch/Users/hoto7260/nextflow_out/Bidir/e_and_o/BidirHOPE_UPM_%j.out
#SBATCH --error=/scratch/Users/hoto7260/nextflow_out/Bidir/e_and_o/BidirHOPE_UPM_%j.out
#SBATCH --time=90:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=2
#SBATCH --mem=5G
#SBATCH --partition long
#SBATCH --mail-type=ALL
#SBATCH --mail-user=hoto7260@colorado.edu

module load samtools/1.8
module load bedtools/2.28.0
module load openmpi/1.6.4
module load gcc/7.1.0
module load python/3.6.3
module load R/4.4.0

SRC=/Users/hoto7260/Flows/Bidirectional-Flow
NF_EXE=/scratch/Shares/dowell/dbnascent/pipeline_assets/nextflow
NF_EXE=/Users/hoto7260/src/nextflow 
## Clear the wokring directory
rm -rf /scratch/Users/hoto7260/nextflow_out/Bidir/tmp3/*

 ## Run your code
${NF_EXE} run ${SRC}/main_hope.nf -profile hg38 \
 --crams "/scratch/Users/hoto7260/nextflow_out/Nascent/UPM_smAECs_07-23-24/mapped/crams/undone/*.sorted.cram" \
 --workdir /scratch/Users/hoto7260/nextflow_out/Bidir/tmp3/ \
 --singleEnd \
 --outdir /scratch/Users/hoto7260/nextflow_out/Bidir/UPM_smAECs_07-23-24 \
 --tfit_3prime \
 --tfit_split_model \
 --savebg
 
# tfit_3prime: # this is my added parameter to say you want to use the 3' end of reads for Tfit analysis
# tfit_split_model: # this runs the Tfit split model (splits 5kb and 10kb regions for faster and more efficient runs, and gets prelim regions)
# savebg: # This saves the bedgraphs (otherwise will delete them as intermediaate files

