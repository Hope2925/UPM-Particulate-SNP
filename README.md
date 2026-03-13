# UPM and WSP analysis using consensus bidirectionals

## Brief Description
Lung cells perturbed by wood smoke particles and urban particulate matter are likely expected to have similar responses. Therefore, we compare the responses of BEAS-2B cells perturbed with wood smoke particles and small airway epithelial cells perturbed with urban particulate matter, both for 30 and 120min.

## Organization
### Data and Results
Exact files used for analysis can be found on Zenodo () with amalgamated  versions available in Supplemental Tables in the publication (bottom)
* Data
  * counts
  * regions (bidirectionals)
  * SNP (nearest gene)
  * TFEA_input (used to run TFEA)
* results
  * Close_TRE_Gene
  * DESeq2
  * GO
  * GSEA_MsigDB 
  * SNP_analysis
  * TFEA
  * Wet_Lab (previously named From_Arnav)
### Analyses
Additional information can be found in each of the subfolders
* **Preprocessing**: 
  * NascentFlow (getting bams from fastqs) 
  * BidirFlow (identifying bidirectionals)
  * mumerge (running muMerge to get consensus bidirectionals)
  * LIET (running LIET-EMG from https://github.com/Dowell-Lab/LIET/tree/LIET_EMGtoo and getting the final consensus coordinates of tREs) 
* **Counting**: Code to quantify expression/accessibility levels for bidirectionals and genes
  * ATACseq
  * Bidir_Count_Flow (used Nextflow pipeline https://github.com/Dowell-Lab/Bidir_Counting_Analysis (commit 4076721))
  * WSP_RNAseq 
* **Diff_Exp**: Differential Expression Analysis and Comparison (e.g. Genes, tREs, GO terms, etc)
  * `Diff_Exp_[].ipynb`: Differential expression analysis for different conditions
  * `Compare_Gene_tREs_GO_[].ipynb`: Comparing the GO results across different perturbations and timings, using a adjusted p-value cutoff for genes of 1x10^-20 or 1x10^-10
  * `Compare_ATACseq_PROseq.ipynb`: Comparing tRE results for ATAC-seq and PRO-seq
  * `Compare_RNAseq_PROseq.ipynb`: Comparing gene results for RNA-seq and PRO-seq
  * `Plot_UPM[]_sequences.ipynb`: Plot transition of transcription of genes/tREs across timepoints and perturbations

* **TFEA**: TF-focused analyses
  * `Get_pval_file_noback.ipynb`: TF motif p-value cutoffs w to get the estimated number of TF motif instances to be between 700 and 5000 to ensure p-values were not shrunk due to simply high number of motif instances. 
  * `run_tfea.sh` and `run_TFEA_WSPNEC.sh`: code to actually run TFEA
  * `Compare_TFEA_results.ipynb`: Assess TFEA results and compare
  * `Compare_TFEA_LE_tREs.ipynb`: Compare the tREs responding to the same TFs across different perturbations
* **MultiOmics_Comp**: Comparing ATAC-seq and RNA-seq to PRO-seq
* **SNP_Analysis**: SNP-focused analyses
  * Gene_Enh_Mapping/ (Matching genes to tREs based on transcription correlation and position)
    * `Getting_Gene_Enh_Pairs.ipynb`
      * includes instructions on whe to use `get_bidir_pairs.sbatch` and `get_bidir_gene_pairs.sh`
  * `Annotate_SNPs.ipynb`: Annotate the SNPs and enhancers using APIs and internal data
  * `Plot_Annotated_SNPs.ipynb`: plot the SNP information retrieved from Annotate_SNPs.ipynb
  * `SNP_PollResponseType.ipynb`: Categorize and statistically summarize SNPs based on the enhancer response timing and perturbation they fall in.
