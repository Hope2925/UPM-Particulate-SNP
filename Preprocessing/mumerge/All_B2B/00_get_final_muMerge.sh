#!/bin/bash


##########################
# EDIT THE FOLLOWING
##########################
source activate Rjupyter
module load bedtools
#module load R/4.1.3
SRC=/Users/hoto7260/src/Bidir_Counting_Analysis
WD=/scratch/Users/hoto7260/Resp_Env/All_B2B
INPUT_DIR=/scratch/Users/hoto7260/Resp_Env/All_B2B/out/mumerge
# Whether or not you want to maintain the sample ids in the final files
S_IDS=TRUE
# files
TFIT=${INPUT_DIR}/B2B_tfit_MUMERGE.bed
DREG=${INPUT_DIR}/B2B_dREG_MUMERGE.bed
# prefix
PREFIX=AllB2B
DATE=05-13-24
# TODO: allow multiple windows to be done at the same time
# fixed window you want to have (0= just use confidence intervals, 1=just mu, 300= 150± mu)
WINDOW=50


##########################
# STARTING THE CODE
##########################
# make an overlaps directory if it doesn't already exist
mkdir -p ${WD}/overlaps
OVER_OUT=${WD}/overlaps/overlaps_${PREFIX}_${DATE}.bed
echo "====== Getting overlaps between Tfit & dREG: ", ${TFIT}, ${DREG}
# Get the overlaps between the Tfit muMerge
bedtools intersect -wo -a ${TFIT} -b ${DREG} > ${OVER_OUT}
head ${OVER_OUT}
echo "Saved at" ${OVER_OUT}

echo "====== Getting the final muMerge file"
# move output to the beds folder
mkdir ${WD}/beds/
OUT_PREFIX=${WD}/beds/${PREFIX}_${DATE}
Rscript ${SRC}/bin/get_final_muMerge.r ${OVER_OUT} ${TFIT} ${DREG} ${OUT_PREFIX} ${WINDOW} ${S_IDS}
echo "\nFinal files saved with prefix" ${OUT_PREFIX}
ls -lh ${OUT_PREFIX}*

## perform bedtools sort
bedtools sort -i ${OUT_PREFIX}_MUMERGE_${WINDOW}bpwin_tfit,dreg.bed > ${OUT_PREFIX}_MUMERGE_${WINDOW}bpwin_tfit,dreg.sorted.bed
wc -l ${OUT_PREFIX}_MUMERGE_${WINDOW}bpwin_tfit,dreg.bed
wc -l ${OUT_PREFIX}_MUMERGE_${WINDOW}bpwin_tfit,dreg.sorted.bed
rm ${OUT_PREFIX}_MUMERGE_${WINDOW}bpwin_tfit,dreg.bed


echo "DONE!"
date
