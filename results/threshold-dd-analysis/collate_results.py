#!/usr/bin/env python3
"""Collate all DD analysis results — full Wood-Boyle + threshold (11 spp) runs."""

import pandas as pd
import numpy as np
import json
from pathlib import Path

FULL_WB = Path("/home/node/.openclaw/workspace/work/marsyas6/papers/valence-ingress/data/van-holstein/Data_Code_Final/PyRate/Outputs/Wood-Boyle")
THRESHOLD_IN = Path("/home/node/.openclaw/workspace/vi-foundry/results/threshold-dd-analysis/input")
OUT = Path("/home/node/.openclaw/workspace/vi-foundry/results/threshold-dd-analysis")

def extract_dd(log_path, n_burnin=100):
    """Extract DD coefficient posterior summary from PyRateContinuous log."""
    if not log_path.exists():
        return None
    df = pd.read_csv(log_path, sep='\t')
    df = df.iloc[n_burnin:]
    gl_cols = [c for c in df.columns if 'Gl_' in c]
    gm_cols = [c for c in df.columns if 'Gm_' in c]
    r = {'n_samples': len(df)}
    if gl_cols:
        gl = df[gl_cols[0]]
        r['Gl_mean'] = float(f"{gl.mean():.4f}")
        r['Gl_sd'] = float(f"{gl.std():.4f}")
        r['Gl_p025'] = float(f"{gl.quantile(0.025):.4f}")
        r['Gl_p50'] = float(f"{gl.quantile(0.5):.4f}")
        r['Gl_p975'] = float(f"{gl.quantile(0.975):.4f}")
        r['P_Gl_gt_0'] = float(f"{(gl>0).mean():.4f}")
    if gm_cols:
        gm = df[gm_cols[0]]
        r['Gm_mean'] = float(f"{gm.mean():.4f}")
        r['Gm_p025'] = float(f"{gm.quantile(0.025):.4f}")
        r['Gm_p975'] = float(f"{gm.quantile(0.975):.4f}")
        r['P_Gm_lt_0'] = float(f"{(gm<0).mean():.4f}")
    return r

# --- Full Wood-Boyle (17 spp) ---
full_configs = {
    "Full WB (17 spp) wholeclade": FULL_WB / "wholeclade_DD_0_expSp_expEx_HP.log",
    "Full WB (17 spp) Homo": FULL_WB / "homo_diversity_0_expSp_expEx_HP.log",
    "Full WB (17 spp) non-Homo": FULL_WB / "nonhomo_diversity_0_expSp_expEx_HP.log",
}

# --- Threshold (11 spp) ---
threshold_configs = {
    "Threshold (11 spp) wholeclade": THRESHOLD_IN / "threshold_wholeclade_DD_0_expSp_expEx_HP.log",
    "Threshold (11 spp) Homo": THRESHOLD_IN / "threshold_homo_DD_0_expSp_expEx_HP.log" if (THRESHOLD_IN / "threshold_homo_DD_0_expSp_expEx_HP.log").exists() else None,
    "Threshold (11 spp) non-Homo": THRESHOLD_IN / "threshold_nonhomo_DD_0_expSp_expEx_HP.log" if (THRESHOLD_IN / "threshold_nonhomo_DD_0_expSp_expEx_HP.log").exists() else None,
}

all_results = {}
for label, path in full_configs.items():
    r = extract_dd(path)
    if r:
        all_results[label] = r
        
for label, path in threshold_configs.items():
    if path and path.exists():
        r = extract_dd(path)
        if r:
            all_results[label] = r

# Print table
print("=== DD COEFFICIENT COMPARISON ===")
print(f"{'Config':<35} {'N_spp':>6} {'Gl_mean':>8} {'Gl_2.5%':>9} {'Gl_97.5%':>9} {'P(>0)':>7} {'Gm':>8} {'P(Gm<0)':>8}")
print("-" * 95)

spp_map = {
    "Full WB (17 spp) wholeclade": 17,
    "Full WB (17 spp) Homo": 7,
    "Full WB (17 spp) non-Homo": 10,
    "Threshold (11 spp) wholeclade": 11,
    "Threshold (11 spp) Homo": 5,
    "Threshold (11 spp) non-Homo": 6,
}

for label in sorted(all_results.keys()):
    r = all_results[label]
    n_spp = spp_map.get(label, "?")
    gl_mean = r.get('Gl_mean', 0)
    gl_025 = r.get('Gl_p025', 0)
    gl_975 = r.get('Gl_p975', 0)
    p_gt_0 = r.get('P_Gl_gt_0', 0)
    gm = r.get('Gm_mean', 0)
    p_gm_lt = r.get('P_Gm_lt_0', 0)
    print(f"{label:<35} {n_spp:>6} {gl_mean:>8.3f} {gl_025:>9.3f} {gl_975:>9.3f} {p_gt_0:>6.1%} {gm:>8.3f} {p_gm_lt:>6.1%}")

# Compute sign-reversal strength
if all_results.get("Full WB (17 spp) Homo") and all_results.get("Full WB (17 spp) non-Homo"):
    h = all_results["Full WB (17 spp) Homo"]["Gl_mean"]
    n = all_results["Full WB (17 spp) non-Homo"]["Gl_mean"]
    print(f"\nFull WB sign reversal: Homo Gl = {h:+.3f} vs non-Homo Gl = {n:+.3f} → Δ = {h-n:+.3f}")

if all_results.get("Threshold (11 spp) Homo") and all_results.get("Threshold (11 spp) non-Homo"):
    h = all_results["Threshold (11 spp) Homo"]["Gl_mean"]
    n = all_results["Threshold (11 spp) non-Homo"]["Gl_mean"]
    print(f"Threshold sign reversal: Homo Gl = {h:+.3f} vs non-Homo Gl = {n:+.3f} → Δ = {h-n:+.3f}")

json.dump({"results": all_results, "species_counts": spp_map}, open(OUT / "dd_comparison_results.json", 'w'), indent=2)
print(f"\nWritten to {OUT / 'dd_comparison_results.json'}")