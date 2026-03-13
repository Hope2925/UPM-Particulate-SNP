#!/bin/bash
#SBATCH --job-name=Get_BidirGene_pairs
#SBATCH --output=/scratch/Users/hoto7260/Resp_Env/All_B2B/e_and_o/GBidirPairs_%j.out
#SBATCH --error=/scratch/Users/hoto7260/Resp_Env/All_B2B/e_and_o/GBidirPairs_%j.out
#SBATCH --time=24:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=30
#SBATCH --mem=500G # ensures I take up the whole node
#SBATCH --partition short
#SBATCH --mail-type=FAIL,END
#SBATCH --mail-user=hoto7260@colorado.edu


module purge
module load R/4.4.0

SRC=/Users/hoto7260/src/bidir_gene_pairs/R/nascent_correlations_nometa.R
OUT_PATH=/scratch/Users/hoto7260/Resp_Env/All_B2B/bidir_gene_pairs/
mkdir -p ${OUT_PATH}
TPM=/Users/hoto7260/projects/Resp_Env/All_B2B/bin/counting/TPM_B2B_tREGene.txt
TISSUE="Beas2B"
#TPM=/Users/hoto7260/projects/Resp_Env/All_B2B/bin/counting/TPM_smAEC_tREGene.txt
#TISSUE="smAEC"
#TPM=/Users/hoto7260/projects/Resp_Env/All_B2B/bin/counting/TPM_B2BsmAEC_tREGene.txt
#TISSUE="Beas2BsmAEC"

echo 'BEGIN: Correlations...................'

#set variables                                                                                                                                                                         
CHROM=$chromid

#run script                                                                                                                                                                            
Rscript --vanilla ${SRC} --tpms ${TPM} --chr_id ${CHROM} -c 30 --tissue ${TISSUE} --out ${OUT_PATH} 

echo 'DONE: Matrix pearson correlation......'


