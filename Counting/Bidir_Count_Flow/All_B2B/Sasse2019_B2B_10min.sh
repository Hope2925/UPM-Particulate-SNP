#!/bin/bash
#SBATCH --job-name=Sasse2019_B2B
#SBATCH --output=/scratch/Users/hoto7260/nextflow_out/Bidir_Count/e_and_o/Sasse2019B2B_%j.out
#SBATCH --error=/scratch/Users/hoto7260/nextflow_out/Bidir_Count/e_and_o/Sasse2019B2B_%j.out
#SBATCH --time=24:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=10
#SBATCH --mem=500G
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
work_dir=/scratch/Users/hoto7260/nextflow_out/Bidir_Count/tmp2/
rm -rf ${work_dir}
mkdir ${work_dir}
 
 ## Run your code

NXF_DEBUG=1 /scratch/Shares/dowell/dbnascent/pipeline_assets/nextflow run ${SRC_DIR}/main.nf \
 --mmfiltbams "/scratch/Users/hoto7260/nextflow_out/Bidir_Count/CUWA/Sasse2019B2B_10min/mmfiltbams/*.bam" \
 --cons_file ~/projects/Resp_Env/Comb_UPM_WSP_ADP/mumerge/out/UPM_WSP_ADP_tfit_MUMERGE.bed \
 -work-dir ${work_dir} \
 --outdir /scratch/Users/hoto7260/nextflow_out/Bidir_Count/CUWA/Sasse2019B2B_10min/ \
 --prefix Sasse2019B2B \
 --date 9.8.25 \
 --count_limit_bids 80 \
 --gene_order_file "/scratch/Shares/dowell/genomes/hg38/hg38.chrom.sizes" \
 --gene_put_file /Users/hoto7260/src/Bidir_Counting_Analysis/assets/hg38_refseq_diff53prime_with_putatives_fixnames_sort2.sorted.bed
 #--savemmfiltbams "FALSE"