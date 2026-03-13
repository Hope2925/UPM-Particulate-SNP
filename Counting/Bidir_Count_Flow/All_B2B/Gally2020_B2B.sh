#!/bin/bash
#SBATCH --job-name=Gally2020_B2B
#SBATCH --output=/scratch/Users/hoto7260/nextflow_out/Bidir_Count/e_and_o/Gally2020B2B_%j.out
#SBATCH --error=/scratch/Users/hoto7260/nextflow_out/Bidir_Count/e_and_o/Gally2020B2B_%j.out
#SBATCH --time=03:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=10
#SBATCH --mem=30G
#SBATCH --partition short
#SBATCH --mail-type=FAIL,END
#SBATCH --mail-user=hoto7260@colorado.edu

## EDIT THIS PATH ##
SRC_DIR=~/src/Bidir_Counting_Analysis


module load samtools/1.8
module load bedtools/2.28.0
module load openmpi/1.6.4
module load gcc/7.1.0
module load subread/1.6.2
module load R/4.4.0

source activate /Users/hoto7260/miniconda3/envs/python39
# python 3.9.17
# numpy  1.25.2
# pandas 2.0.3
 
## Clear the wokring directory
work_dir=/scratch/Users/hoto7260/nextflow_out/Bidir_Count/tmp/
rm -rf ${work_dir}
mkdir ${work_dir}
 
 ## Run your code

NXF_DEBUG=1 /scratch/Shares/dowell/dbnascent/pipeline_assets/nextflow run ${SRC_DIR}/main.nf \
 --crams "/scratch/Users/hoto7260/tmp/crams/" \
 --cons_file ~/projects/Resp_Env/Comb_UPM_WSP_ADP/mumerge/out/UPM_WSP_ADP_tfit_MUMERGE.bed \
 -work-dir ${work_dir} \
 --outdir /scratch/Users/hoto7260/nextflow_out/Bidir_Count/CUWA/Gally2020B2B/ \
 --prefix Gally2020B2B \
 --date 9.8.25 \
 --count_limit_bids 30 \
 --savemmfiltbams "FALSE"