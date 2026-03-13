#!/bin/bash
#SBATCH --job-name=mumerge
#SBATCH --output=/scratch/Users/hoto7260/Resp_Env/Comb_UPM_WSP_ADP/e_and_o/mumerge_%j.out
#SBATCH --error=/scratch/Users/hoto7260/Resp_Env/Comb_UPM_WSP_ADP/e_and_o/mumerge_%j.out
#SBATCH --time=04:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=8
#SBATCH --mem=2G
#SBATCH --partition short
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=hoto7260@colorado.edu

###########################
## activate environments ##
###########################
source activate /Users/hoto7260/miniconda3/envs/python39
module load bedtools
bedtools -version
#conda list
SRC=/Users/hoto7260/src/mumerge/mumerge
MY_TMP=/scratch/Users/hoto7260/Resp_Env/Comb_UPM_WSP_ADP/tmp
mkdir -p ${MY_TMP}
#################
## run muMerge ## (9442565)
#################
## Tfit 
python ${SRC}/mumerge.py -i /Users/hoto7260/projects/Resp_Env/Comb_UPM_WSP_ADP/mumerge/Comb_mumerge_tfit_meta_all.txt -o ${MY_TMP}/UPM_WSP_ADP_tfit --save_sampids

mv ${MY_TMP}/* /Users/hoto7260/projects/Resp_Env/Comb_UPM_WSP_ADP/mumerge/out
rmdir ${MY_TMP}
echo DONE!