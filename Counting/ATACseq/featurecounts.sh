#!/bin/bash
#SBATCH --job-name=Counting
#SBATCH --output=/scratch/Users/hoto7260/Resp_Env/Transient_Response/e_and_o/ATAC_featurecounts_%j.out
#SBATCH --error=/scratch/Users/hoto7260/Resp_Env/Transient_Response/e_and_o/ATAC_featurecounts_%j.out
#SBATCH --time=05:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=32
#SBATCH --mem=10G
#SBATCH --partition short
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=hoto7260@colorado.edu

##########################
# EDIT THE FOLLOWING
##########################

#### Loading Modules/Environments

module load bedtools
module load samtools/1.8
module load subread/1.6.2

UPMNEC_BAM_DIR=/scratch/Shares/dowell/forsasse/NEC-ALI-D0_UPM_ATACseq/mapped_hg38/bams/dedup/
WSPNEC_BAM_DIR=/scratch/Shares/dowell/forsasse/NEC-ALI_WSP_ATACseq/mapped_hg38/bams/dedup/
WSPB2B_BAM_DIR=/scratch/Users/hoto7260/Resp_Env/WSP_B2B/mapped/ATAC/
SAF=/Users/hoto7260/projects/Resp_Env/Transient_Response/ATAC_comparison/UPM_WSP_ADP_tfit_MUMERGE_1kb.saf
SAF_M=/Users/hoto7260/projects/Resp_Env/Transient_Response/ATAC_comparison/UPM_WSP_ADP_tfit_MUMERGE_1kb_merged.saf
COUNT_DIR=/scratch/Users/hoto7260/Resp_Env/Transient_Response/

########################################## 
# Count reads over enhancer coordinates     ##
##########################################
echo "=========================UPM NEC"
# Use this many threads (-T)
# Count multi-overlapping read
featureCounts \
    -T 32 \
    -O \
    -a ${SAF} \
    -F 'SAF' \
    -o ${COUNT_DIR}/UPM_NEC_ATAC_CUWA1kb_MUMERGE.txt \
    ${UPMNEC_BAM_DIR}/*.dedup_sorted.bam 

featureCounts \
    -T 32 \
    -O \
    -a ${SAF_M} \
    -F 'SAF' \
    -o ${COUNT_DIR}/UPM_NEC_ATAC_CUWA1kb_merged.txt \
    ${UPMNEC_BAM_DIR}/*.dedup_sorted.bam 

echo "=========================WSP NEC"
# Use this many threads (-T)
# Count multi-overlapping read
featureCounts \
    -T 32 \
    -O \
    -a ${SAF} \
    -F 'SAF' \
    -o ${COUNT_DIR}/WSP_NEC_ATAC_CUWA1kb_MUMERGE.txt \
    ${WSPNEC_BAM_DIR}/*.dedup_sorted.bam  

featureCounts \
    -T 32 \
    -O \
    -a ${SAF_M} \
    -F 'SAF' \
    -o ${COUNT_DIR}/WSP_NEC_ATAC_CUWA1kb_merged.txt \
    ${WSPNEC_BAM_DIR}/*.dedup_sorted.bam  

echo "=========================WSP B2B"
# Use this many threads (-T)
# Count multi-overlapping read
featureCounts \
    -T 32 \
    -O \
    -a ${SAF} \
    -F 'SAF' \
    -o ${COUNT_DIR}/WSP_B2B_ATAC_CUWA1kb_MUMERGE.txt \
    ${WSPB2B_BAM_DIR}/*.dedup.sorted.bam 

featureCounts \
    -T 32 \
    -O \
    -a ${SAF_M} \
    -F 'SAF' \
    -o ${COUNT_DIR}/WSP_B2B_ATAC_CUWA1kb_merged.txt \
    ${WSPB2B_BAM_DIR}/*.dedup.sorted.bam 

