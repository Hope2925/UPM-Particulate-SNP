#!/usr/bin/env python3
"""Primary concordance and distance-standardized enrichment against bronchial ENCODE-rE2G.

No CRISPR validation, plotting, alternate overlap rules, or self-promoter sensitivity.
The full correlation table is required to construct the non-significant background.
"""
from __future__ import annotations
import argparse
import bisect
import hashlib
import json
from collections import defaultdict
from pathlib import Path
import numpy as np
import pandas as pd
from download_encode_reference import verify_reference

DATASETS = ('ENCSR100UQM', 'ENCSR262GGN')
DISTANCE_EDGES = [0, 10000, 25000, 50000, 100000, 250000, 500000, 1000000, np.inf]


def interval_index(frame):
    """Sorted starts plus cumulative maximum ends support nested intervals."""
    result = {}
    for chrom, group in frame.groupby('#chr', sort=False):
        group = group.sort_values('start')
        result[chrom] = (group.start.to_numpy(), np.maximum.accumulate(group.end.to_numpy()),
                         list(group.itertuples(index=False, name=None)))
    return result


def overlaps(index, chrom, start, end):
    """Positive-length intersection of zero-based, half-open intervals."""
    if chrom not in index:
        return []
    starts, max_ends, rows = index[chrom]
    left = bisect.bisect_right(max_ends, start)
    right = bisect.bisect_left(starts, end)
    return [row for row in rows[left:right] if row[2] > start]


def deduplicate(raw, threshold):
    required = {'gene', 'enhancer', 'pearson_r', 'p_value', 'q_value_BH'}
    if not required.issubset(raw.columns):
        raise ValueError(f'Missing columns: {required - set(raw.columns)}')
    raw = raw.copy()
    if raw[['gene', 'enhancer']].isna().any().any():
        raise ValueError('Gene and enhancer identifiers cannot be missing')
    for column in ['pearson_r', 'p_value', 'q_value_BH']:
        raw[column] = pd.to_numeric(raw[column], errors='raise')
    raw['symbol'] = raw.gene.str.split(':').str[0]
    counts = raw.loc[raw.q_value_BH.lt(threshold)].groupby(['symbol', 'enhancer']).size().to_dict()
    frame = raw.sort_values(['p_value', 'gene'], na_position='last', kind='stable').drop_duplicates(['symbol', 'enhancer']).copy()
    frame = frame.rename(columns={'gene': 'representative_transcript', 'symbol': 'gene'})
    frame['significant'] = frame.q_value_BH.lt(threshold)
    frame['significant_transcript_count'] = [counts.get(key, 0) for key in zip(frame.gene, frame.enhancer)]
    frame['sign'] = np.select([frame.pearson_r.gt(0), frame.pearson_r.lt(0), frame.pearson_r.eq(0)],
                              ['positive', 'negative', 'zero'], default='undefined')
    if int(frame.significant.sum()) != len(counts):
        raise ValueError('Minimum-p deduplication and significance disagree; input must use one BH test family')
    return frame


def annotate(frame, reference_dir, manifest):
    coords = {}
    for enhancer in frame.enhancer.unique():
        chrom, interval = enhancer.split(':')
        start, end = map(int, interval.split('-'))
        if start < 0 or end <= start:
            raise ValueError(f'Invalid interval: {enhancer}')
        coords[enhancer] = (chrom, start, end)
    gene_tss = defaultdict(set)
    evidence, reference_stats = [], []
    keys = list(zip(frame.gene, frame.enhancer))
    significant_keys = set(zip(frame.loc[frame.significant, 'gene'], frame.loc[frame.significant, 'enhancer']))
    for dataset in DATASETS:
        print(f'Matching {dataset}', flush=True)
        paths = {item['role']: reference_dir / (item['accession'] + '.bed.gz')
                 for item in manifest if item['dataset'] == dataset}
        predictions = pd.read_csv(paths['predictions'], sep='\t')
        genes = pd.read_csv(paths['genes'], sep='\t')
        peaks = pd.read_csv(paths['candidate_elements'], sep='\t', header=None, names=['#chr', 'start', 'end'])
        for chrom, gene, tss in zip(genes['#chr'], genes.symbol, genes.tss):
            gene_tss[(chrom, gene)].add(int(tss))
        flags = predictions.isSelfPromoter.astype(str).str.lower()
        if not flags.isin(['true', 'false']).all():
            raise ValueError('Unrecognized isSelfPromoter value')
        distal = predictions.loc[flags.eq('false')]
        index = interval_index(distal[['#chr', 'start', 'end', 'TargetGene', 'Score']])
        peak_index = interval_index(peaks)
        support, candidate, represented, targets = {}, {}, {}, {}
        for enhancer, (chrom, start, end) in coords.items():
            matches = overlaps(index, chrom, start, end)
            candidate[enhancer] = bool(overlaps(peak_index, chrom, start, end))
            represented[enhancer] = bool(matches)
            targets[enhancer] = ';'.join(sorted({row[3] for row in matches}))
            for row in matches:
                key = (row[3], enhancer)
                support[key] = max(support.get(key, 0), row[4])
                if key in significant_keys:
                    evidence.append((dataset, enhancer, row[3], f'{chrom}:{row[1]}-{row[2]}',
                                     row[4], min(end, row[2]) - max(start, row[1])))
        frame[dataset + '_score'] = [support.get(key, np.nan) for key in keys]
        frame[dataset + '_supported'] = frame[dataset + '_score'].notna()
        frame[dataset + '_candidate_overlap'] = frame.enhancer.map(candidate)
        frame[dataset + '_prediction_overlap'] = frame.enhancer.map(represented)
        frame[dataset + '_gene_in_reference'] = frame.gene.isin(set(genes.symbol))
        frame[dataset + '_overlapping_targets'] = frame.enhancer.map(targets)
        reference_stats.append({'dataset': dataset, 'prediction_rows': len(predictions),
                                'self_promoter_rows_excluded': int(flags.eq('true').sum()),
                                'retained_rows': len(distal), 'candidate_elements': len(peaks)})
    for suffix in ['supported', 'candidate_overlap', 'prediction_overlap', 'gene_in_reference']:
        frame['union_' + suffix] = frame[[a + '_' + suffix for a in DATASETS]].any(axis=1)
    frame['supporting_biosamples'] = frame[[a + '_supported' for a in DATASETS]].sum(axis=1)
    frame['union_status'] = np.select(
        [frame.union_supported, frame.union_prediction_overlap, frame.union_candidate_overlap],
        ['supported_same_gene', 'overlapping_prediction_other_gene_only', 'candidate_element_without_thresholded_link'],
        default='no_candidate_element_overlap')
    distances = []
    for gene, enhancer in keys:
        chrom, start, end = coords[enhancer]
        tss = gene_tss.get((chrom, gene))
        distances.append(min(abs((start + end) / 2 - x) for x in tss) if tss else np.nan)
    frame['distance_to_nearest_reference_TSS_bp'] = distances
    frame['chromosome'] = frame.enhancer.str.split(':').str[0]
    frame['distance_bin'] = pd.cut(frame.distance_to_nearest_reference_TSS_bp, DISTANCE_EDGES, right=False).astype('string').fillna('missing_reference_TSS')
    frame['distance_stratum'] = frame.chromosome + '|' + frame.distance_bin
    return frame, pd.DataFrame(evidence, columns=['dataset', 'enhancer', 'gene', 'reference_enhancer', 'reference_score', 'overlap_bp']), pd.DataFrame(reference_stats)


def summarize(frame):
    significant = frame[frame.significant]
    rows = []
    for dataset in (*DATASETS, 'union'):
        for sign in ['all', 'positive', 'negative']:
            subset = significant if sign == 'all' else significant[significant.sign.eq(sign)]
            supported = int(subset[dataset + '_supported'].sum())
            rows.append({'dataset': dataset, 'sign': sign, 'pairs': len(subset), 'supported': supported,
                         'support_percent': 100 * supported / len(subset) if len(subset) else np.nan,
                         'candidate_overlap': int(subset[dataset + '_candidate_overlap'].sum()),
                         'prediction_overlap': int(subset[dataset + '_prediction_overlap'].sum())})
    return pd.DataFrame(rows)


def enrichment(frame, replicates, seed):
    """Direct distance standardization; resample gene clusters jointly in both groups."""
    finite = frame[np.isfinite(frame.pearson_r)].copy()
    genes = {gene: i for i, gene in enumerate(sorted(finite.gene.unique()))}
    strata = {value: i for i, value in enumerate(sorted(finite.distance_stratum.unique()))}
    if not genes:
        raise ValueError('No finite candidate correlations')
    rng = np.random.default_rng(seed)
    weights = [rng.multinomial(len(genes), np.full(len(genes), 1 / len(genes))) for _ in range(replicates)]
    rows, details = [], []
    for dataset in (*DATASETS, 'union'):
        for sign in ['all', 'positive', 'negative']:
            subset = finite if sign == 'all' else finite[finite.sign.eq(sign)]
            foreground, background = subset[subset.significant], subset[~subset.significant]
            column = dataset + '_supported'
            ft = foreground.groupby('distance_stratum')[column].agg(['size', 'sum'])
            bt = background.groupby('distance_stratum')[column].agg(['size', 'sum'])
            joined = ft.join(bt, lsuffix='_fg', rsuffix='_bg').fillna(0)
            joined['dataset'], joined['sign'] = dataset, sign
            details.append(joined.reset_index())
            eligible = set(joined.index[joined.size_bg.gt(0)])
            initial_size = len(foreground)
            foreground = foreground[foreground.distance_stratum.isin(eligible)]
            background = background[background.distance_stratum.isin(eligible)]
            matrices = []
            for group, use_support in [(foreground, False), (foreground, True), (background, False), (background, True)]:
                matrix = np.zeros((len(genes), len(strata)))
                indices = (group.gene.map(genes).to_numpy(dtype=int), group.distance_stratum.map(strata).to_numpy(dtype=int))
                np.add.at(matrix, indices, group[column].to_numpy(dtype=float) if use_support else 1.)
                matrices.append(matrix)

            def estimate(totals):
                fn, fs, bn, bs = totals
                ok = bn > 0
                expected = float(np.sum(fn[ok] * bs[ok] / bn[ok]))
                observed = float(fs[ok].sum())
                return observed, expected, observed / expected if expected else np.nan

            observed, expected, fold = estimate([matrix.sum(axis=0) for matrix in matrices])
            boot = np.array([estimate([weight @ matrix for matrix in matrices])[2] for weight in weights])
            usable = boot[np.isfinite(boot)]
            low, high = np.quantile(usable, [.025, .975]) if len(usable) else (np.nan, np.nan)
            rows.append({'dataset': dataset, 'sign': sign, 'foreground_pairs': len(foreground),
                         'unmatched_foreground_pairs': initial_size - len(foreground),
                         'background_pairs': len(background), 'observed_supported': int(observed),
                         'distance_matched_expected': expected, 'fold_enrichment': fold,
                         'bootstrap_ci_low': low, 'bootstrap_ci_high': high,
                         'bootstrap_replicates': replicates, 'finite_bootstrap_estimates': len(usable)})
            print(f'{dataset} {sign}: enrichment={fold:.6g}', flush=True)
    return pd.DataFrame(rows), pd.concat(details, ignore_index=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--correlations', type=Path, required=True, help='Full transcript-level correlation TSV, including non-significant pairs')
    parser.add_argument('--reference-dir', type=Path, required=True)
    parser.add_argument('--outdir', type=Path, required=True)
    parser.add_argument('--bootstrap-replicates', type=int, default=1000)
    parser.add_argument('--seed', type=int, default=20260908)
    args = parser.parse_args()
    if args.bootstrap_replicates < 0:
        parser.error('--bootstrap-replicates cannot be negative')
    manifest = verify_reference(args.reference_dir)
    raw = pd.read_csv(args.correlations, sep='\t')
    audit = {'input_rows': len(raw), 'finite_input_rows': int(np.isfinite(raw.pearson_r).sum()),
             'significant_transcript_rows': int(raw.q_value_BH.lt(.001).sum()), 'BH_threshold': .001,
             'input_sha256': hashlib.sha256(args.correlations.read_bytes()).hexdigest(),
             'seed': args.seed, 'bootstrap_replicates': args.bootstrap_replicates,
             'reference_accessions': [item['accession'] for item in manifest]}
    frame = deduplicate(raw, .001)
    del raw
    audit.update(deduplicated_candidates=len(frame), finite_deduplicated_candidates=int(np.isfinite(frame.pearson_r).sum()))
    frame, evidence, refs = annotate(frame, args.reference_dir, manifest)
    significant = frame[frame.significant]
    audit.update(significant_pairs=len(significant), significant_genes=int(significant.gene.nunique()),
                 significant_enhancers=int(significant.enhancer.nunique()))
    args.outdir.mkdir(parents=True, exist_ok=True)
    outputs = {'significant_pairs_annotated.tsv': significant, 'overlap_evidence.tsv': evidence,
               'reference_summary.tsv': refs, 'concordance_summary.tsv': summarize(frame)}
    for name, data in outputs.items():
        data.to_csv(args.outdir / name, sep='\t', index=False, na_rep='NA')
    estimates, strata = enrichment(frame, args.bootstrap_replicates, args.seed)
    estimates.to_csv(args.outdir / 'distance_matched_enrichment.tsv', sep='\t', index=False, na_rep='NA')
    strata.to_csv(args.outdir / 'distance_matching_strata.tsv', sep='\t', index=False, na_rep='NA')
    (args.outdir / 'run_metadata.json').write_text(json.dumps(audit, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(audit, indent=2))


if __name__ == '__main__':
    main()
