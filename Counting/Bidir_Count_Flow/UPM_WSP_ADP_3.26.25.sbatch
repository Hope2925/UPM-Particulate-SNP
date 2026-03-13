#!/bin/bash
#SBATCH --job-name=BidirCountFlow_WSP
#SBATCH --output=/scratch/Users/hoto7260/nextflow_out/Bidir_Count/e_and_o/UWA_%j.out
#SBATCH --error=/scratch/Users/hoto7260/nextflow_out/Bidir_Count/e_and_o/UWA_%j.out
#SBATCH --time=24:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --mem=1G
#SBATCH --partition highmem
#SBATCH --mail-type=FAIL,END
#SBATCH --mail-user=hoto7260@colorado.edu

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
 work_dir=/scratch/Users/hoto7260/nextflow_out/Bidir_Count/tmp
 rm -rf ${work_dir}
 
 ## Run your code
/scratch/Shares/dowell/dbnascent/pipeline_assets/nextflow run /Users/hoto7260/src/Bidir_Counting_Analysis/main.nf \
 --crams "/scratch/Users/hoto7260/nextflow_out/Nascent/ADP_smAECs_03-4-24/mapped/crams/" \
 --cons_file /Users/hoto7260/projects/Resp_Env/Comb_UPM_WSP_ADP/mumerge/out/UPM_WSP_ADP_tfit_MUMERGE.bed \
 -work-dir ${work_dir} \
 --outdir /scratch/Users/hoto7260/Resp_Env/Comb_UPM_WSP_ADP/ADP \
 --prefix CUWA_ADP \
 --date 3.26.25 \
 --count_type "MU_COUNTS" \
 --count_limit_bids 60 \
 --gene_put_file /Users/hoto7260/src/Bidir_Counting_Analysis/assets/hg38_refseq_diff53prime_with_putatives_fixnames_sort2.sorted.bed

 /scratch/Shares/dowell/dbnascent/pipeline_assets/nextflow run /Users/hoto7260/src/Bidir_Counting_Analysis/main.nf \
 --bams "/scratch/Users/hoto7260/nextflow_out/Nascent/WSP_B2B_03-4-24/mapped/bams/" \
 --cons_file /Users/hoto7260/projects/Resp_Env/Comb_UPM_WSP_ADP/mumerge/out/UPM_WSP_ADP_tfit_MUMERGE.bed \
 -work-dir ${work_dir} \
 --outdir /scratch/Users/hoto7260/Resp_Env/Comb_UPM_WSP_ADP/WSP \
 --prefix CUWA_WSP \
 --date 3.26.25 \
 --count_type "MU_COUNTS" \
 --count_limit_bids 60 \
 --gene_put_file /Users/hoto7260/src/Bidir_Counting_Analysis/assets/hg38_refseq_diff53prime_with_putatives_fixnames_sort2.sorted.bed


/scratch/Shares/dowell/dbnascent/pipeline_assets/nextflow run /Users/hoto7260/src/Bidir_Counting_Analysis/main.nf \
 --mmfiltbams "/scratch/Users/hoto7260/Resp_Env/UPM_smAECs/mapped/mmfiltbams/" \
 --cons_file /Users/hoto7260/projects/Resp_Env/Comb_UPM_WSP_ADP/mumerge/out/UPM_WSP_ADP_tfit_MUMERGE.bed \
 -work-dir ${work_dir} \
 --outdir /scratch/Users/hoto7260/Resp_Env/Comb_UPM_WSP_ADP/UPM \
 --prefix CUWA_UPM \
 --date 3.26.25 \
 --count_type "MU_COUNTS" \
 --count_limit_bids 60 \
 --gene_put_file /Users/hoto7260/src/Bidir_Counting_Analysis/assets/hg38_refseq_diff53prime_with_putatives_fixnames_sort2.sorted.bed


# --mmfiltbams /scratch/Users/hoto7260/Resp_Env/UPM_smAECs/mapped/mmfiltbams/ \
