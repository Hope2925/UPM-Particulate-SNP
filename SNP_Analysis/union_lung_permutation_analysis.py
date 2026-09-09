#!/usr/bin/env python3
"""EAF-matched permutation test of respiratory SNPs in lung-function GWAS.

1. Define the union as variants having All of Us COPD or asthma P < 0.05.
2. Retain variants annotated ``ld_role == lead`` in at least one qualifying
   phenotype analysis.
   Note - see methods section for how lead variants were defined
3. Retain variants present, with compatible alleles and valid EAF/P, in BOTH
   the FEV1 and FEV1/FVC GWAS.
4. Within each external GWAS, compare the observed mean -log10(P) with random
   SNP sets matched one-for-one on external minor-allele-frequency (MAF) bin.

The supplied ``ld_role`` annotation is used as-is. This script does not calculate
LD or define LD blocks. Random variants are biallelic SNVs, exclude all 681 union
candidates, and are sampled from 0.01-wide MAF bins in the same external GWAS.
"""

from __future__ import annotations

import argparse
import csv
import gzip
import json
import math
import random
import re
import sys
from collections import defaultdict
from pathlib import Path
from typing import Any

import numpy as np


DEFAULT_DISCOVERY = Path("COPD_asthma_all_SNP_allele_EAF_LD.tsv")
DEFAULT_MAP = Path("replication_results/dbsnp_mapping_qc.csv")
DEFAULT_FEV1 = Path("gwas_summary_statistics/GCST90244092_buildGRCh37.tsv.gz")
DEFAULT_FEV1_FVC = Path("gwas_summary_statistics/GCST90244094_buildGRCh37.tsv.gz")
DEFAULT_OUTPUT = Path("union_lung_permutation_results")

STUDIES = {
    "FEV1": "GCST90244092",
    "FEV1_FVC": "GCST90244094",
}

DNA = {"A", "C", "G", "T"}
COMPLEMENT = str.maketrans("ACGT", "TGCA")


def numeric(value: Any) -> float | None:
    try:
        number = float(value)
        return number if math.isfinite(number) else None
    except (TypeError, ValueError):
        return None


def minor_allele_frequency(eaf: float | None) -> float | None:
    if eaf is None or not 0 <= eaf <= 1:
        return None
    return min(eaf, 1 - eaf)


def bin_index(maf: float, width: float) -> int:
    return min(int(maf / width), int(0.5 / width) - 1)


def allele_compatible(ref: str, alt: str, external_a1: str, external_a2: str) -> bool:
    """Accept the same biallelic SNV on either allele order or DNA strand."""
    ref, alt = ref.upper(), alt.upper()
    a1, a2 = external_a1.upper(), external_a2.upper()
    if not all(len(a) == 1 and a in DNA for a in (ref, alt, a1, a2)):
        return False
    observed = {a1, a2}
    return observed == {ref, alt} or observed == {ref.translate(COMPLEMENT), alt.translate(COMPLEMENT)}


def load_union_leads(discovery_path: Path, mapping_path: Path) -> tuple[list[dict[str, Any]], set[str]]:
    """Return LD leads and all 681 rsIDs, joining by verified GRCh38 variant ID."""
    with mapping_path.open(encoding="utf-8-sig", newline="") as handle:
        mapping = {row["discovery_variant"]: row["rsid"].lower()
                   for row in csv.DictReader(handle)
                   if row.get("coordinate_ok") == "true" and row.get("allele_ok") == "true"}

    grouped: dict[str, list[dict[str, str]]] = defaultdict(list)
    order: list[str] = []
    with discovery_path.open(encoding="utf-8-sig", newline="") as handle:
        for row in csv.DictReader(handle, delimiter="\t"):
            p = numeric(row.get("P"))
            if p is None or p >= 0.05:
                continue
            if row["SNP"] not in grouped:
                order.append(row["SNP"])
            grouped[row["SNP"]].append(row)

    if len(grouped) != 681:
        raise ValueError(f"Expected 681 unique variants with COPD or asthma P < 0.05; found {len(grouped)}")
    missing_map = [variant for variant in order if variant not in mapping]
    if missing_map:
        raise ValueError(f"Missing verified rsID mappings for {len(missing_map)} variants; examples: {missing_map[:5]}")

    all_rsids = {mapping[variant] for variant in order}
    leads = []
    for variant in order:
        rows = grouped[variant]
        if not any(row.get("ld_role", "").strip().lower() == "lead" for row in rows):
            continue
        # Alleles are site properties and therefore the same in the two discovery rows.
        row = rows[0]
        leads.append({"rsid": mapping[variant], "discovery_variant": variant,
                      "reference_allele": row["reference_allele"].upper(),
                      "effect_allele": row["effect_allele"].upper(),
                      "qualifying_phenotypes": "|".join(sorted(r["phenotype"] for r in rows)),
                      "minimum_discovery_p": min(float(r["P"]) for r in rows)})
    if len(leads) != 601:
        raise ValueError(f"Expected 601 union variants annotated as a lead; found {len(leads)}")
    return leads, all_rsids


def reservoir_add(pool: list[float], value: float, number_seen: int,
                  capacity: int, rng: random.Random) -> None:
    """Uniform reservoir sample from an arbitrarily large stream."""
    if len(pool) < capacity:
        pool.append(value)
        return
    replacement = rng.randrange(number_seen)
    if replacement < capacity:
        pool[replacement] = value


def scan_gwas(path: Path, candidate_by_rsid: dict[str, dict[str, Any]],
              all_candidate_rsids: set[str], maf_bin_width: float,
              reservoir_per_bin: int, seed: int) -> dict[str, Any]:
    """Stream one compressed GWAS, retaining candidates and matched-null reservoirs."""
    hits: dict[str, dict[str, Any]] = {}
    pools: dict[int, list[float]] = defaultdict(list)
    seen_by_bin: dict[int, int] = defaultdict(int)
    rng = random.Random(seed)
    total_rows = eligible_background = 0

    with gzip.open(path, "rt", encoding="utf-8", errors="replace", newline="") as handle:
        reader = csv.DictReader(handle, delimiter="\t")
        required = {"variant_id", "effect_allele", "other_allele",
                    "effect_allele_frequency", "p_value"}
        missing = required.difference(reader.fieldnames or [])
        if missing:
            raise ValueError(f"{path} lacks required columns: {sorted(missing)}")

        for row in reader:
            total_rows += 1
            rsid = row["variant_id"].strip().lower()
            p = numeric(row["p_value"])
            eaf = numeric(row["effect_allele_frequency"])
            maf = minor_allele_frequency(eaf)
            if p is None or not 0 <= p <= 1 or maf is None:
                continue
            logp = 323.0 if p == 0 else -math.log10(max(p, 1e-323))

            candidate = candidate_by_rsid.get(rsid)
            if candidate is not None:
                if allele_compatible(candidate["reference_allele"], candidate["effect_allele"],
                                     row["effect_allele"], row["other_allele"]):
                    previous = hits.get(rsid)
                    # Duplicate candidate records are resolved conservatively by retaining
                    # the smallest p-value, matching the earlier harmonization pipeline.
                    if previous is None or p < previous["p"]:
                        hits[rsid] = {"p": p, "logp": logp, "eaf": eaf, "maf": maf,
                                      "effect_allele": row["effect_allele"],
                                      "other_allele": row["other_allele"]}
                continue

            # Exclude every union candidate, not only the LD-lead subset, from null pools.
            if rsid in all_candidate_rsids:
                continue
            a1, a2 = row["effect_allele"].upper(), row["other_allele"].upper()
            if a1 not in DNA or a2 not in DNA or len(a1) != 1 or len(a2) != 1:
                continue
            b = bin_index(maf, maf_bin_width)
            seen_by_bin[b] += 1
            reservoir_add(pools[b], logp, seen_by_bin[b], reservoir_per_bin, rng)
            eligible_background += 1

            if total_rows % 10_000_000 == 0:
                print(f"  {path.name}: {total_rows:,} rows", file=sys.stderr, flush=True)

    return {"hits": hits, "pools": pools, "seen_by_bin": dict(seen_by_bin),
            "total_rows": total_rows, "eligible_background": eligible_background}


def permutation_test(candidate_rows: list[dict[str, Any]], pools: dict[int, list[float]],
                     maf_bin_width: float, permutations: int, seed: int) -> dict[str, Any]:
    """Test whether candidate mean -log10(P) exceeds that of EAF-matched sets."""
    observed = np.asarray([row["logp"] for row in candidate_rows], dtype=float)
    required_bins: dict[int, int] = defaultdict(int)
    for row in candidate_rows:
        required_bins[bin_index(row["maf"], maf_bin_width)] += 1

    unavailable = [b for b in required_bins if not pools.get(b)]
    if unavailable:
        raise ValueError(f"No eligible random variants in required MAF bins: {unavailable}")

    rng = np.random.default_rng(seed)
    null_sum = np.zeros(permutations, dtype=float)
    # Independent draws are made with replacement from large reservoirs. With 50,000
    # variants per common bin and <=601 candidates, within-set duplicates are rare.
    for b, count in sorted(required_bins.items()):
        pool = np.asarray(pools[b], dtype=float)
        for start in range(0, permutations, 1_000):
            stop = min(start + 1_000, permutations)
            indices = rng.integers(0, len(pool), size=(stop - start, count))
            null_sum[start:stop] += pool[indices].sum(axis=1)

    observed_mean = float(observed.mean())
    null_means = null_sum / len(observed)
    empirical_p = float((1 + np.count_nonzero(null_means >= observed_mean)) / (permutations + 1))
    return {
        "n_variants": len(candidate_rows),
        "observed_mean_neg_log10_p": observed_mean,
        "null_mean_median": float(np.median(null_means)),
        "null_mean_2_5_percentile": float(np.quantile(null_means, 0.025)),
        "null_mean_97_5_percentile": float(np.quantile(null_means, 0.975)),
        "empirical_p_value": empirical_p,
        "permutations": permutations,
        "minimum_possible_empirical_p": 1 / (permutations + 1),
    }


def write_csv(path: Path, rows: list[dict[str, Any]]) -> None:
    if not rows:
        return
    with path.open("w", encoding="utf-8-sig", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--discovery", type=Path, default=DEFAULT_DISCOVERY)
    parser.add_argument("--variant-map", type=Path, default=DEFAULT_MAP)
    parser.add_argument("--fev1", type=Path, default=DEFAULT_FEV1)
    parser.add_argument("--fev1-fvc", type=Path, default=DEFAULT_FEV1_FVC)
    parser.add_argument("--output-dir", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--permutations", type=int, default=100_000)
    parser.add_argument("--maf-bin-width", type=float, default=0.01)
    parser.add_argument("--reservoir-per-bin", type=int, default=50_000)
    parser.add_argument("--seed", type=int, default=20260908)
    args = parser.parse_args()
    args.output_dir.mkdir(parents=True, exist_ok=True)

    leads, all_candidate_rsids = load_union_leads(args.discovery, args.variant_map)
    candidate_by_rsid = {row["rsid"]: row for row in leads}
    paths = {"FEV1": args.fev1, "FEV1_FVC": args.fev1_fvc}
    scans = {}
    for offset, (trait, path) in enumerate(paths.items()):
        print(f"Scanning {trait}: {path}", file=sys.stderr, flush=True)
        scans[trait] = scan_gwas(path, candidate_by_rsid, all_candidate_rsids,
                                 args.maf_bin_width, args.reservoir_per_bin,
                                 args.seed + offset)

    # Use the exact same candidate set for both traits.
    shared_rsids = set(candidate_by_rsid)
    for scan in scans.values():
        shared_rsids.intersection_update(scan["hits"])
    shared = [row for row in leads if row["rsid"] in shared_rsids]
    if not shared:
        raise RuntimeError("No LD-lead candidate variants overlap both GWAS files")

    candidate_output = []
    results = []
    scan_qc = []
    for offset, trait in enumerate(("FEV1", "FEV1_FVC")):
        scan = scans[trait]
        observed_rows = [scan["hits"][row["rsid"]] for row in shared]
        result = permutation_test(observed_rows, scan["pools"], args.maf_bin_width,
                                  args.permutations, args.seed + 10_000 + offset)
        result = {"trait": trait, "study_accession": STUDIES[trait], **result,
                  "maf_bin_width": args.maf_bin_width,
                  "background_reservoir_per_bin": args.reservoir_per_bin,
                  "random_pool_excluded_union_candidates": 681,
                  "ld_filter": "supplied ld_role == lead in at least one qualifying phenotype"}
        results.append(result)
        scan_qc.append({"trait": trait, "study_accession": STUDIES[trait],
                        "gwas_rows_scanned": scan["total_rows"],
                        "eligible_background_snvs": scan["eligible_background"],
                        "lead_candidates_found": len(scan["hits"]),
                        "shared_candidates_used": len(shared),
                        "background_reservoir_size": sum(len(v) for v in scan["pools"].values())})

    for candidate in shared:
        row = dict(candidate)
        for trait in ("FEV1", "FEV1_FVC"):
            hit = scans[trait]["hits"][candidate["rsid"]]
            prefix = trait.lower()
            row[f"{prefix}_external_eaf"] = hit["eaf"]
            row[f"{prefix}_external_maf"] = hit["maf"]
            row[f"{prefix}_p"] = hit["p"]
            row[f"{prefix}_neg_log10_p"] = hit["logp"]
        candidate_output.append(row)

    write_csv(args.output_dir / "empirical_p_values.csv", results)
    write_csv(args.output_dir / "shared_union_ld_lead_variants.csv", candidate_output)
    write_csv(args.output_dir / "scan_qc.csv", scan_qc)
    configuration = {
        "analysis": "mean -log10(P) EAF-matched permutation test",
        "union_definition": "All of Us COPD P < 0.05 or asthma P < 0.05",
        "ld_filter": "supplied ld_role == lead in at least one qualifying analysis",
        "overlap_filter": "compatible variant present in both FEV1 and FEV1/FVC GWAS",
        "background": "biallelic SNVs from the same external GWAS; all 681 candidates excluded",
        "permutations": args.permutations, "maf_bin_width": args.maf_bin_width,
        "reservoir_per_bin": args.reservoir_per_bin, "seed": args.seed,
        "inputs": {"discovery": str(args.discovery), "variant_map": str(args.variant_map),
                   "FEV1": str(args.fev1), "FEV1_FVC": str(args.fev1_fvc)},
        "software": {"python": sys.version, "numpy": np.__version__},
    }
    (args.output_dir / "analysis_config.json").write_text(json.dumps(configuration, indent=2), encoding="utf-8")
    print(f"Used {len(shared)} shared LD-lead variants", file=sys.stderr)
    print(f"Results: {args.output_dir / 'empirical_p_values.csv'}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
