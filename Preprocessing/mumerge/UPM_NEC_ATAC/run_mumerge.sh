#!/bin/bash
#SBATCH --job-name=mumerge
#SBATCH --output=/scratch/Users/hoto7260/Resp_Env/UPM_NEC/e_and_o/mumerge_%j.out
#SBATCH --error=/scratch/Users/hoto7260/Resp_Env/UPM_NEC/e_and_o/mumerge_%j.out
#SBATCH --time=05:00:00
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
MY_TMP=/scratch/Users/hoto7260/Resp_Env/UPM_NEC/tmp

#################
## run muMerge ## (9442565)
#################
## Tfit 
python ${SRC}/mumerge.py -i /Users/hoto7260/projects/Resp_Env/UPM_NEC/mumerge/UPM_NEC_mumerge_meta_11.1.24.txt -o ${MY_TMP}/tfit_11.1.24 --save_sampids

mv ${MY_TMP}/* /Users/hoto7260/projects/Resp_Env/UPM_NEC/mumerge/out/
rmdir ${MY_TMP}
echo DONE!

