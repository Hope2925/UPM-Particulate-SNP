#!/bin/bash
#SBATCH --job-name=TFEA
#SBATCH --mail-type=FAIL,END
#SBATCH --mail-user=hoto7260@colorado.edu
#SBATCH --ntasks=50
#SBATCH -N 1
#SBATCH -p short 
#SBATCH --mem=50gb
#SBATCH --time=08:00:00 
#SBATCH --output=/scratch/Users/hoto7260/Resp_Env/WSP_NEC/e_and_o/TFEA_CUWA_%j.out
#SBATCH --error=/scratch/Users/hoto7260/Resp_Env/WSP_NEC/e_and_o/TFEA_CUWA_%j.out


#################################################
############  SET UP VARIABLES  #################
#################################################

outdir=/scratch/Users/hoto7260/Resp_Env/WSP_NEC/TFEA/out
fimo_motifs=/scratch/Users/hoto7260/assets/H12CORE_meme_format.meme
#fimo_pval=/scratch/Users/hoto7260/assets/PVAL_CUTOFF_ESTIMATES_H12.CORE.CUWA.txt
fimo_pval=/scratch/Users/hoto7260/assets/PVAL_CUTOFF_ESTIMATES_H12_noback.CORE.CUWA.txt
#fimo_pval=/scratch/Users/hoto7260/assets/PVAL_CUTOFF_ESTIMATES_H12.CORE.AHR_ATAC_3.16.txt
genomefasta=/scratch/Shares/dowell/genomes/hg38/hg38.fa

genomefasta=/scratch/Shares/dowell/genomes/hg38/hg38.fa
bg_dir=/scratch/Shares/dowell/forsasse/NEC-ALI_WSP_ATACseq/mapped_hg38/bams/dedup



# copy combined file to temporary directory in scratch
#combined_file=/scratch/Users/hoto7260/Resp_Env/UPM_NEC/UPM_NEC_1kb_ATAC_MUMERGE.bed
combined_file=/Users/hoto7260/projects/Resp_Env/WSP_NEC/mumerge/out/tfit_11.1.24_MUMERGE.bed
combined_file=/scratch/Users/hoto7260/Resp_Env/Comb_UPM_WSP_ADP/WSP/regions/nontss_bid_CUWA_WSP_3.26.25_forTFEA.bed

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

echo PATH: $PATH
source /Users/hoto7260/src/TFEA/vir_TFEA/bin/activate
echo PATH: $PATH

echo "STARTING"
# make the out directory
mkdir ${outdir}

"\n#### UPM30_Veh #############################\n"
python3 /Users/hoto7260/src/TFEA/vir_TFEA/lib/python3.7/site-packages/tfea-1.1.4-py3.7.egg/TFEA  \
    --output ${outdir}/WSP30_Veh_CUWA_noback_nontss \
    --combined_file ${combined_file} \
    --bam1 ${bg_dir}/NEC-D0_veh-1.dedup_sorted.bam ${bg_dir}/NEC-D0_veh-2.dedup_sorted.bam \
    --bam2 ${bg_dir}/NEC-D0_30WSP-1.dedup_sorted.bam ${bg_dir}/NEC-D0_30WSP-2.dedup_sorted.bam \
    --label1 VEH \
    --label2 WSP30 \
    --genomefasta ${genomefasta} \
    --fimo_motifs ${fimo_motifs}\
    --cpus 30 \
    --mem 50gb \
    --fimo_thresh ${fimo_pval} \
    --output_type txt \
    --debug

echo "\n#### UPM120_Veh #############################\n"
python3 /Users/hoto7260/src/TFEA/vir_TFEA/lib/python3.7/site-packages/tfea-1.1.4-py3.7.egg/TFEA  \
    --output ${outdir}/WSP120_Veh_CUWA_noback_nontss \
    --combined_file ${combined_file} \
    --bam1 ${bg_dir}/NEC-D0_veh-1.dedup_sorted.bam ${bg_dir}/NEC-D0_veh-2.dedup_sorted.bam \
    --bam2 ${bg_dir}/NEC-D0_120WSP-1.dedup_sorted.bam ${bg_dir}/NEC-D0_120WSP-2.dedup_sorted.bam \
    --label1 VEH \
    --label2 WSP120 \
    --genomefasta ${genomefasta} \
    --fimo_motifs ${fimo_motifs}\
    --cpus 30 \
    --mem 50gb \
    --fimo_thresh ${fimo_pval} \
    --output_type txt \
    --debug


