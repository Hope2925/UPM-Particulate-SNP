import os
import sys
import traceback
from pathlib import Path
from collections import defaultdict

import pysam
import pybedtools
from Bio import SeqIO
import pandas as pd

# Read SNP file path from command-line (expects: chrom, pos, rsid)
if len(sys.argv) < 2:
    print("Usage: python allele_counter_chunk_fullgw.py <snp_chunk.txt>")
    sys.exit(1)

allsnps = sys.argv[1]
chunk_prefix = os.path.basename(allsnps).replace('.txt', '')

# Set up paths and variables (customize as needed)
project = "/scratch/alpine/agupta06@xsede.org/aqtl_analysis_0924"
resources = "/projects/agupta06@xsede.org/aqtl/aqtl_resources"
project_gw = f"{project}/genome-wide_fulldbsnp156"
os.makedirs(project_gw, exist_ok=True)

consensus_peaks = f"{resources}/mumerge_out_MUMERGE.bed"
genome_fa = "/projects/agupta06@xsede.org/genome/grch38/genome.fa"
bam_dir = f"{project}/bams_dedup/dl_061825"
bam_files = list(Path(bam_dir).glob("*.bam"))

# Output files per chunk
full_allele_freq_file = f"{project_gw}/full_allele_freq_unstimulated_{chunk_prefix}.txt"

def fetch_sequence(genome_fa, chrom, start, end):
    fasta = pysam.FastaFile(genome_fa)
    seq = fasta.fetch(chrom, start, end)
    fasta.close()
    return seq

def get_bam_rootname(bam_path):
    return Path(bam_path).stem

def allele_count_at_snp(bam_path, chrom, pos, alleles, flank_len, genome_fa):
    counts = dict(A=0, T=0, G=0, C=0)
    bam = pysam.AlignmentFile(bam_path, "rb")
    for pileupcolumn in bam.pileup(chrom, pos-1, pos, truncate=True, stepper="all"):
        if pileupcolumn.pos == pos-1:
            for pileupread in pileupcolumn.pileups:
                if pileupread.is_del or pileupread.is_refskip:
                    continue
                base = pileupread.alignment.query_sequence[pileupread.query_position]
                if base in counts:
                    counts[base] += 1
    bam.close()
    return counts

def is_het(counts):
    return sum(1 for c in counts.values() if c > 0) > 1

def get_total_reads(bam_path):
    with pysam.AlignmentFile(bam_path, "rb") as bamfile:
        count = sum(1 for read in bamfile if not read.is_unmapped)
    return count

from concurrent.futures import ProcessPoolExecutor, as_completed

# CHANGED: Parse new input format: chrom, pos, rsid (tab-delimited)
def process_snp(line, bam_files, bam_total_reads, genome_fa):
    try:

        fields = line.strip().split()
        if len(fields) < 3:
            return None  # skip malformed lines
        chrom, pos, snpid = fields[:3]
        pos = int(pos)  # 1-based position
        flank_len = 17
        seq5p = fetch_sequence(genome_fa, chrom, pos-flank_len-1, pos-1)
        seq3p = fetch_sequence(genome_fa, chrom, pos, pos+flank_len)

        sample_counts = defaultdict(lambda: dict(A=0, T=0, G=0, C=0))
        het_samples = []
        total_samples = 0

        total_norm_counts = 0.0

        for bam in bam_files:
            rootname = get_bam_rootname(bam)
            counts = allele_count_at_snp(bam, chrom, pos, list('ATGC'), flank_len, genome_fa)
            total_reads = bam_total_reads[rootname]
            norm_counts = {base: (count / total_reads if total_reads > 0 else 0.0) for base, count in counts.items()}
            total_samples += 1
            if is_het(counts):
                sample_counts[rootname] = norm_counts
                het_samples.append(rootname)
            total_norm_counts += sum(norm_counts.values())
        if not sample_counts:
            return None

        sumA = sum(counts['A'] for counts in sample_counts.values())
        sumT = sum(counts['T'] for counts in sample_counts.values())
        sumG = sum(counts['G'] for counts in sample_counts.values())
        sumC = sum(counts['C'] for counts in sample_counts.values())
        sumtot = sumA + sumT + sumG + sumC

        freqA = sumA / sumtot if sumtot > 0 else 0.0
        freqC = sumC / sumtot if sumtot > 0 else 0.0
        freqG = sumG / sumtot if sumtot > 0 else 0.0
        freqT = sumT / sumtot if sumtot > 0 else 0.0

        total_norm_reads_per_million = total_norm_counts * 1e6

        return f"{snpid}\t{freqA:.8f}\t{freqC:.8f}\t{freqG:.8f}\t{freqT:.8f}\t{len(het_samples)}\t{total_samples}\t{total_norm_reads_per_million:.8f}\n"
    except Exception as e:
        error_msg = f"ERROR processing line: {line.strip()} | Exception: {e}\n{traceback.format_exc()}"
        return error_msg


def main():
    with open(full_allele_freq_file, 'w') as fout:
        fout.write("")

    bam_total_reads = {get_bam_rootname(bam): get_total_reads(bam) for bam in bam_files}

    # Read all SNP lines at once
    with open(allsnps) as snpfile:
        snp_lines = list(snpfile)

    # Set number of workers (threads/processes)
    n_workers = os.cpu_count() # Or set to count from the cpu: os.cpu_count()  # Or set to a custom value, e.g., 4

    # Use ProcessPoolExecutor for true parallelism
    with ProcessPoolExecutor(max_workers=n_workers) as executor:
        futures = [
            executor.submit(process_snp, line, bam_files, bam_total_reads, genome_fa)
            for line in snp_lines
        ]
        with open(full_allele_freq_file, 'a') as fout_freq:
            for future in as_completed(futures):
                result = future.result()
                if result:
                    if result.startswith("ERROR"):
                        print(result)
                    else: 
                        fout_freq.write(result)

if __name__ == "__main__":
    main()
