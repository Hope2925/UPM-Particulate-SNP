#!/bin/bash 
#SBATCH --job-name=nextflow # Job name
#SBATCH -p long
#SBATCH --mail-type=ALL # Mail events (NONE, BEGIN, END, FAIL, ALL)
#SBATCH --mail-user=hope.townsend@colorado.edu # Where to send mail
#SBATCH --nodes=1 # Run on a single node
#SBATCH --ntasks=5     # Number of CPU (processer cores i.e. tasks) In this example I use 1. I only need one, since none of the commands I run are parallelized.
#SBATCH --mem=8gb # Memory limit
#SBATCH --time=96:00:00 # Time limit hrs:min:sec
#SBATCH --output=/scratch/Users/hoto7260/nextflow_out/Nascent/e_and_o/UPM_smAECs.%j.out # Standard output
#SBATCH --error=/scratch/Users/hoto7260/nextflow_out/Nascent/e_and_o/UPM_smAECs.%j.err # Standard error log

# mkdir -p /scratch/Users/hoto7260/nexttemp1/
# mkdir -p /scratch/Users/hoto7260/nexttemp1out/

# echo "Made proper directories"

# #activate conda environment
#source activate Nextflow

echo "PATH" $PATH

echo "Loading modules"
#load modules 
module purge
module load sra/2.8.0 
module load bbmap/38.05
module load fastqc/0.11.8
module load hisat2/2.1.0
module load samtools/1.8
module load preseq/2.0.3
module load python/3.6.3/rseqc
module load igvtools/2.3.75
module load mpich/3.2.1 
module load bedtools/2.28.0 
module load openmpi/1.6.4
module load gcc/7.1.0 

#Get the Nextflow paths (for script and Nextflow Executive)
SRC=/Users/hoto7260/Flows/Nascent-Flow
NF_EXE='/scratch/Shares/dowell/dbnascent/pipeline_assets/nextflow'


${NF_EXE} ${SRC}/main.nf -profile slurm_grch38 --workdir '/scratch/Users/hoto7260/nextflow_out/Nascent/tmp/' --genome_id 'hg38' --outdir '/scratch/Users/hoto7260/nextflow_out/Nascent/UPM_smAECs_07-23-24/' --email hope.townsend@colorado.edu --fastqs '/scratch/Shares/dowell/forsasse/sm36-ALI_UPM_PROseq/fastq/*.fastq.gz' --flip --saveTrim --singleEnd --skippileup 
