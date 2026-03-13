#!/bin/bash
#SBATCH --job-name=mumerge
#SBATCH --output=/scratch/Users/hoto7260/Resp_Env/All_B2B/e_and_o/mumerge_%j.out
#SBATCH --error=/scratch/Users/hoto7260/Resp_Env/All_B2B/e_and_o/mumerge_%j.out
#SBATCH --time=05:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=8
#SBATCH --mem=2G
#SBATCH --partition short
#SBATCH --mail-type=FAIL,END
#SBATCH --mail-user=hoto7260@colorado.edu

###########################
## activate environments ##
###########################
source activate /Users/hoto7260/miniconda3/envs/python39
module load bedtools
bedtools -version
#conda list
SRC=/Users/hoto7260/src/mumerge/mumerge


#################
## run muMerge ## 
#################
## Tfit 
python ${SRC}/mumerge.py -i /Users/hoto7260/projects/Resp_Env/All_B2B/bin/mumerge/All_B2B_mumerge_tfit_meta_all.txt -o /scratch/Users/hoto7260/Resp_Env/All_B2B/out/mumerge/B2B_tfit --verbose --save_sampids

## dREG 
python ${SRC}/mumerge.py -i /Users/hoto7260/projects/Resp_Env/All_B2B/bin/mumerge/All_B2B_mumerge_dreg_meta_all.txt -o /scratch/Users/hoto7260/Resp_Env/All_B2B/out/mumerge/B2B_dREG --verbose --save_sampids

echo DONE!
