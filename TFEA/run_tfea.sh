#!/bin/bash
#SBATCH --job-name=TFEA
#SBATCH --mail-type=FAIL,END
#SBATCH --mail-user=hoto7260@colorado.edu
#SBATCH --ntasks=50
#SBATCH -N 1
#SBATCH -p short 
#SBATCH --mem=50gb
#SBATCH --time=08:00:00 
#SBATCH --output=/scratch/Users/hoto7260/Resp_Env/Comb_UPM_WSP_ADP/e_and_o/TFEA_%j.out
#SBATCH --error=/scratch/Users/hoto7260/Resp_Env/Comb_UPM_WSP_ADP/e_and_o/TFEA_%j.out


#################################################
############  SET UP VARIABLES  #################
#################################################
#dir=/scratch/Users/dara6367/PRO-seq_interspecies-nutlin/Bidirectional-Flow
outdir=/scratch/Users/hoto7260/Resp_Env/Comb_UPM_WSP_ADP/ADP/TFEA/out
outdir=/scratch/Users/hoto7260/Resp_Env/Comb_UPM_WSP_ADP/UPM/TFEA/out
outdir=/scratch/Users/hoto7260/Resp_Env/Comb_UPM_WSP_ADP/WSP/TFEA/out
label_use=ADP
label_use=UPM
label_use=WSP
fimo_motifs=/scratch/Users/hoto7260/assets/H12CORE_meme_format.meme
fimo_pval=/scratch/Users/hoto7260/assets/PVAL_CUTOFF_ESTIMATES_H12_noback.CORE.CUWA.txt
fimo_back=/scratch/Users/hoto7260/assets/enhancer_background_flat
genomefasta=/scratch/Shares/dowell/genomes/hg38/hg38.fa
input_dir=/scratch/Users/hoto7260/Resp_Env/Comb_UPM_WSP_ADP/ADP/TFEA/input/

###Display job context
echo Job: $SLURM_JOB_NAME with ID $SLURM_JOB_ID
echo Running on host `hostname`
echo Job started at `date +"%T %a %d %b %Y"`
echo Directory is `pwd`
echo Using $SLURM_NTASKS processors, across $SLURM_NNODES nodes, with $SLURM_JOB_CPUS_PER_NODE cpus per node
# 9587506 & 9588742
#################################################
###########  SET UP ENVIRONMENT  ################
#################################################
### Clear modules and load conda environment
module purge

module load python/3.7.4
module load samtools/1.3.1
module load bedtools/2.25.0
module load meme/5.0.3
module load samtools/1.3.1
module load gcc/7.1.0
module load R/4.4.0
Ge
echo PATH: $PATH
source /Users/hoto7260/src/TFEA/vir_TFEA/bin/activate
echo PATH: $PATH

echo "STARTING"
# make the out directory
mkdir ${outdir}

# #######################################
# ###########  RUN TFEA  ################
# #######################################
python3 /Users/hoto7260/src/TFEA/vir_TFEA/lib/python3.7/site-packages/tfea-1.1.4-py3.7.egg/TFEA  \
        --output ${outdir}/Gene_par_rat_Wd_GeneHK_noback \
        --ranked_file ${input_dir}/GeneTSS_${label_use}_vs_Veh_par_rat_Wd_GeneHK.bed \
        --label1 VEH \
        --label2 ${label_use} \
        --genomefasta ${genomefasta} \
        --fimo_motifs ${fimo_motifs}\
        --cpus 50 \
        --mem 50gb \
        --fimo_thresh ${fimo_pval} \
        --output_type html \
        --debug


python3 /Users/hoto7260/src/TFEA/vir_TFEA/lib/python3.7/site-packages/tfea-1.1.4-py3.7.egg/TFEA  \
        --output ${outdir}/NonTSS_par_rat_Wd_GeneHK_noback \
        --ranked_file ${input_dir}/NonTSS_${label_use}_vs_Veh_par_rat_Wd_GeneHK.bed \
        --label1 VEH \
        --label2 ${label_use} \
        --genomefasta ${genomefasta} \
        --fimo_motifs ${fimo_motifs}\
        --cpus 50 \
        --mem 50gb \
        --fimo_thresh ${fimo_pval} \
        --output_type html \
        --debug




date
