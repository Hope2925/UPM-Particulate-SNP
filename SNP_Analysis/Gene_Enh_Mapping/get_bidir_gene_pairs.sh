#!/bin/bash                                                                                                                                                                            

echo "SUBMITTING JOBS"

#I only consider one batch (all chroms) b/c non-chr1 finish so quickly (<1 min) and I have a 20second delay                                                                                                                                                                                         

CHROMID=(chr1 chr2 chr3 chr4 chr5 chr6 chr7 chr8 chr9 chr10 chr11 chr12 chr13 chr14 chr15 chr16 chr17 chr18 chr19 chr20 chr21 chr22 chr23 chrX chrY)

batch_script=/Users/hoto7260/projects/Resp_Env/All_B2B/bin/counting/get_bidir_pairs.sbatch

# loops through each chromosome id  
echo "STARTING"

for CHR in ${CHROMID[@]}; do

    echo Chromosome $CHR

    # now run the sbatch with the script 04_nascent_correlations.sbatch                                                                                                            
    sbatch --export=chromid=$CHR ${batch_script}

    sleep 5s

done