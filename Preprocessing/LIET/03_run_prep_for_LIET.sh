#!/bin/bash


# INPUT_DIR=/scratch/Users/hoto7260/Resp_Env/Comb_UPM_WSP_ADP/LIET/LIET_input/
# srr_list=${INPUT_DIR}/SRR_list.txt
# annfile=${INPUT_DIR}/LIETinput_CUWA_8500SIG_05.8.25.txt
# PAD_FILE=${INPUT_DIR}/Pad_file_CUWA_8500SIG_05.8.25.txt
# BGS=/scratch/Users/hoto7260/Resp_Env/Comb_UPM_WSP_ADP/LIET/LIET_input/bedgraphs
# WD=/scratch/Users/hoto7260/Resp_Env/Comb_UPM_WSP_ADP/LIET

# ann_name=CUWA_UniqPadded_05.8.25
# bash 02_LIET_prep_annsplit.sh ${srr_list} ${annfile} ${BGS} ${WD} "BGS_done" ${ann_name} "PAD_FILE=${PAD_FILE}"


## Repeating for UPM and WSP
INPUT_DIR=/scratch/Users/hoto7260/Resp_Env/Comb_UPM_WSP_ADP/LIET/LIET_input/
srr_list=${INPUT_DIR}/UPMWSP_SRR_list.txt
annfile=${INPUT_DIR}/LIETinput_CUWA_missed8631SIG_05.14.25.sorted.txt
PAD_FILE=${INPUT_DIR}/Pad_file_05.14.25.txt
BGS=/scratch/Users/hoto7260/Resp_Env/Comb_UPM_WSP_ADP/LIET/LIET_input/bedgraphs
WD=/scratch/Users/hoto7260/Resp_Env/Comb_UPM_WSP_ADP/LIET

ann_name=CUWA_missed_UniqPadded_05.14.25
bash 02_LIET_prep_annsplit.sh ${srr_list} ${annfile} ${BGS} ${WD} "BGS_done" ${ann_name} "PAD_FILE=${PAD_FILE}"


## New for ADP
INPUT_DIR=/scratch/Users/hoto7260/Resp_Env/Comb_UPM_WSP_ADP/LIET/LIET_input/
srr_list=${INPUT_DIR}/ADP_SRR_list.txt
annfile=${INPUT_DIR}/LIETinput_CUWA_15000SIG_05.14.25.sorted.txt
PAD_FILE=${INPUT_DIR}/Pad_file_05.14.25.txt
BGS=/scratch/Users/hoto7260/Resp_Env/Comb_UPM_WSP_ADP/LIET/LIET_input/bedgraphs
WD=/scratch/Users/hoto7260/Resp_Env/Comb_UPM_WSP_ADP/LIET

ann_name=CUWA_full_UniqPadded_05.14.25
bash 02_LIET_prep_annsplit.sh ${srr_list} ${annfile} ${BGS} ${WD} "BGS_done" ${ann_name} "PAD_FILE=${PAD_FILE}"

