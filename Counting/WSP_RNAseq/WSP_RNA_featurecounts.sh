#!/bin/bash
#SBATCH --job-name=Counting
#SBATCH --output=/scratch/Users/hoto7260/Resp_Env/WSP_RNA_B2B/featurecounts_%j.out
#SBATCH --error=/scratch/Users/hoto7260/Resp_Env/WSP_RNA_B2B/featurecounts_%j.out
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

BAM_DIR=/scratch/Users/hoto7260/nextflow_out/RNA/WSP_RNA_B2B/mapped/bams
GTF=/scratch/Shares/dowell/genomes/hg38/ncbi/hg38_refseq.gtf
COUNT_DIR=/scratch/Users/hoto7260/Resp_Env/WSP_RNA_B2B/

########################################## 
# Count reads over gene coordinates     ##
##########################################
cd ${bams}
echo "Submitted counts with Rsubread for original genes by strand......"
# Use this many threads (-T)
# Count multi-overlapping read
# Count reads in a strand specific manner (-s 2)
# Count by the gene feature (-t 'gene' - default) or tanscript (-t transcript_id)
featureCounts \
    -T 32 \
    -O \
    -s 1 \
    -t "exon" \
    -a ${GTF} \
    -F 'GTF' \
    -o ${COUNT_DIR}/WSP_RNA_B2B_str_gtf_genes.txt \
    ${BAM_DIR}/*.sorted.bam

featureCounts \
    -T 32 \
    -O \
    -s 1 \
    -t "exon" \
    -a ${GTF} \
    -F 'GTF' \
    -g transcript_id \
    -o ${COUNT_DIR}/WSP_RNA_B2B_str_gtf_transcripts.txt \
    ${BAM_DIR}/*.sorted.bam


