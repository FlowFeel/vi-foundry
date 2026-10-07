#!/usr/bin/env python3
"""PyRate diversity-dependent (DD) analysis on the 11-species threshold taxonomy.

Re-runs the van Holstein DD analysis with the 6 rare species removed (<5 occ):
  Homo:     erectus, habilis s.l., heidelbergensis, neanderthalensis, sapiens
            EXCLUDED: ergaster (not in DB), floresiensis (2 occ)
  Non-Homo: afarensis, africanus, anamensis, aethiopicus, boisei, robustus
            EXCLUDED: bahrelghazali, deyiremeda, garhi, sediba

Input: Wood-Boyle SE tables (already estimated by PyRate RJMCMC on full taxonomy)
  Filtered to 11 species, plus new LTT from filtered SE table.
"""

import pandas as pd
import numpy as np
import subprocess, sys, json, os, shutil
from pathlib import Path

PYRATE_SOURCE = Path("/home/node/.openclaw/workspace/tools/PyRate-source")
PYRATE_VENV = PYRATE_SOURCE / ".venv" / "bin" / "python"
VH_DATA = Path("/home/node/.openclaw/workspace/work/marsyas6/papers/valence-ingress/data/van-holstein/Data_Code_Final/PyRate/Outputs")
FOUNDRY = Path("/home/node/.openclaw/workspace/vi-foundry")
OUT_DIR = FOUNDRY / "results" / "threshold-dd-analysis"
DATA_DIR = OUT_DIR / "input"

# Species codes in Wood-Boyle taxonomy:
# WB Code → Species
#   1 = Australopithecus afarensis
#   2 = Australopithecus africanus
#   3 = Australopithecus anamensis
#   4 = Australopithecus bahrelghazali  ← EXCLUDED (<5 occ)
#   5 = Australopithecus deyiremeda     ← EXCLUDED (<5 occ)
#   6 = Australopithecus garhi          ← EXCLUDED (<5 occ)
#   7 = Australopithecus sediba         ← EXCLUDED (<5 occ)
#   8 = Homo erectus
#   9 = Homo ergaster                   ← EXCLUDED (not in DB)
#  10 = Homo floresiensis               ← EXCLUDED (<5 occ)
#  11 = Homo habilis sensu lato
#  12 = Homo heidelbergensis
#  13 = Homo neanderthalensis
#  14 = Homo sapiens
#  15 = Paranthropus aethiopicus
#  16 = Paranthropus boisei
#  17 = Paranthropus robustus

# The 11 threshold species (≥5 occ per species)
THRESHOLD_CODES_ALL = [1, 2, 3, 8, 11, 12, 13, 14, 15, 16, 17]
THRESHOLD_CODES_HOMO = [8, 11, 12, 13, 14]
THRESHOLD_CODES_NONHOMO = [1, 2, 3, 15, 16, 17]

# Species names (for output)
WB_SPECIES = {
    1: "Australopithecus afarensis",
    2: "Australopithecus africanus",
    3: "Australopithecus anamensis",
    4: "Australopithecus bahrelghazali",
    5: "Australopithecus deyiremeda",
    6: "Australopithecus garhi",
    7: "Australopithecus sediba",
    8: "Homo erectus",
    9: "Homo ergaster",
    10: "Homo floresiensis",
    11: "Homo habilis sensu lato",
    12: "Homo heidelbergensis",
    13: "Homo neanderthalensis",
    14: "Homo sapiens",
    15: "Paranthropus aethiopicus",
    16: "Paranthropus boisei",
    17: "Paranthropus robustus",
}

def make_se_table(codes, label, source_log, replicate=0):
    """Create a filtered SE table from the Wood-Boyle PyRate log file."""
    wb_log = VH_DATA / source_log
    df = pd.read_csv(wb_log, sep='\t')
    df = df[df['clade'] >= 0]  # skip header
    df['species'] = df['species'].astype(int)
    
    # Filter to threshold codes
    mask = df['species'].isin(codes)
    df_filtered = df[mask].copy()
    
    # Set all to same clade
    df_filtered['clade'] = 0.0
    
    # Write output
    out_path = DATA_DIR / f"threshold_{label}.txt"
    df_filtered.to_csv(out_path, sep='\t', index=False, header=True)
    return out_path

def compute_ltt(se_txt_path, out_path):
    """Compute a Lineage-Through-Time (LTT) curve from an SE table.
    At each 0.1 Myr time bin, count how many species are alive."""
    df = pd.read_csv(se_txt_path, sep='\t')
    df = df[df['clade'] >= 0]
    
    max_ts = df['ts'].max()
    bins = np.arange(0, max_ts + 0.1, 0.05)
    
    records = []
    for t in bins:
        n_alive = ((df['ts'] >= t) & (df['te'] <= t)).sum()
        records.append({'time': t, 'diversity': float(n_alive)})
    
    ltt_df = pd.DataFrame(records)
    ltt_df['m_div'] = ltt_df['diversity'].astype(int)
    ltt_df['M_div'] = ltt_df['m_div']
    ltt_df.to_csv(out_path, sep='\t', index=False)
    return out_path

def run_pyrate_continuous(infile, dd_label, ltt_path=None):
    """Run PyRateContinuous.py with -DD model on the SE table."""
    cmd = [str(PYRATE_VENV), str(PYRATE_SOURCE / "PyRateContinuous.py"),
           "-d", str(infile),
           "-n", "1050000",
           "-s", "1000",
           "-p", "1000",
           "-r", "1",
           "-DD"]
    
    if ltt_path:
        cmd.extend(["-c", str(ltt_path)])
    
    out_prefix = OUT_DIR / f"dd_{dd_label}"
    env = os.environ.copy()
    env['PYTHONPATH'] = str(PYRATE_SOURCE)
    
    result = subprocess.run(cmd, capture_output=True, text=True, env=env,
                           cwd=PYRATE_SOURCE)
    
    # Move output files
    output_files = list(OUT_DIR.glob("*"))
    pyrate_results = [f for f in output_files if f.is_file() and f.suffix in ('.log', '.txt', '.pdf')]
    
    return {
        'label': dd_label,
        'infile': str(infile),
        'stdout': result.stdout[-2000:] if len(result.stdout) > 2000 else result.stdout,
        'stderr': result.stderr[-1000:] if len(result.stderr) > 1000 else result.stderr,
        'returncode': result.returncode,
    }

def run_dd_analysis():
    """Run the full threshold DD analysis."""
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    
    results = {}
    
    # Step 1: Create filtered SE tables from Wood-Boyle data
    print("=== Step 1: Creating filtered SE tables ===")
    
    # Use the Wood-Boyle log files (which have the correct SE estimates)
    # The wholeclade.txt for Wood-Boyle has all 17 species with their estimates
    # We need to extract the correct ts/te for our 11 threshold species
    
    # Actually, for the DD analysis we need the SE tables from the proper
    # PyRate estimation (the .txt files). The Wood-Boyle directory has these.
    # Let's use Wood-Boyle's wholeclade.txt and filter.
    
    wb_whole = VH_DATA / "Wood-Boyle" / "wholeclade.txt"
    
    # Filter for all 11 threshold species
    se_path = make_se_table(THRESHOLD_CODES_ALL, 
                            "wholeclade", 
                            "Wood-Boyle/wholeclade.txt")
    results['se_wholeclade'] = str(se_path)
    
    # Filter for just Homo
    se_homo = make_se_table(THRESHOLD_CODES_HOMO,
                            "homo",
                            "Wood-Boyle/homo.txt")  
    results['se_homo'] = str(se_homo)
    
    # Filter for just non-Homo
    se_nonhomo = make_se_table(THRESHOLD_CODES_NONHOMO,
                               "nonhomo",
                               "Wood-Boyle/nonhomo.txt")
    results['se_nonhomo'] = str(se_nonhomo)
    
    # Step 2: Compute LTT from the filtered dataset
    print("\n=== Step 2: Computing LTT curves ===")
    ltt_path = DATA_DIR / "threshold_wholeclade_ltt.txt"
    compute_ltt(se_path, ltt_path)
    results['ltt'] = str(ltt_path)
    
    # Step 3: Run PyRateContinuous.py -DD on each configuration
    print("\n=== Step 3: Running PyRateContinuous.py -DD ===")
    
    # Run on all 11 species (this is the main result)
    dd_all = run_pyrate_continuous(se_path, "threshold_wholeclade")
    results['dd_wholeclade'] = dd_all
    
    # Run on Homo subset (with whole clade LTT as covariate)
    dd_homo = run_pyrate_continuous(se_homo, "threshold_homo", ltt_path=ltt_path)
    results['dd_homo'] = dd_homo
    
    # Run on non-Homo subset (with whole clade LTT as covariate)
    dd_nonhomo = run_pyrate_continuous(se_nonhomo, "threshold_nonhomo", ltt_path=ltt_path)
    results['dd_nonhomo'] = dd_nonhomo
    
    # Step 4: Also run on FULL Wood-Boyle for comparison
    print("\n=== Step 4: Running full Wood-Boyle for comparison ===")
    wb_whole_path = VH_DATA / "Wood-Boyle" / "wholeclade.txt"
    wb_ltt_path = VH_DATA / "Wood-Boyle" / "wholeclade_ltt.txt"
    
    dd_wb_all = run_pyrate_continuous(wb_whole_path, "fullwb_wholeclade")
    results['dd_fullwb_wholeclade'] = dd_wb_all
    
    dd_wb_homo = run_pyrate_continuous(
        VH_DATA / "Wood-Boyle" / "homo.txt",
        "fullwb_homo", ltt_path=wb_ltt_path)
    results['dd_fullwb_homo'] = dd_wb_homo
    
    dd_wb_nonhomo = run_pyrate_continuous(
        VH_DATA / "Wood-Boyle" / "nonhomo.txt",
        "fullwb_nonhomo", ltt_path=wb_ltt_path)
    results['dd_fullwb_nonhomo'] = dd_wb_nonhomo
    
    # Step 5: Collate results from log files
    print("\n=== Step 5: Collating results ===")
    
    def load_dd_log(log_path):
        """Extract DD coefficient (Gl) posterior summary from PyRateContinuous log."""
        if not Path(log_path).exists():
            return None
        df = pd.read_csv(log_path, sep='\t')
        df = df.iloc[-2000:, :]  # last 2000 samples (post-burnin)
        
        gl_cols = [c for c in df.columns if 'Gl_' in c]
        gm_cols = [c for c in df.columns if 'Gm_' in c]
        
        summary = {}
        if gl_cols:
            gl = df[gl_cols[0]]
            summary['Gl_mean'] = float(gl.mean())
            summary['Gl_sd'] = float(gl.std())
            summary['Gl_p025'] = float(gl.quantile(0.025))
            summary['Gl_p50'] = float(gl.median())
            summary['Gl_p975'] = float(gl.quantile(0.975))
            summary['P_Gl_gt_0'] = float((gl > 0).mean())
            summary['n_samples'] = len(df)
        if gm_cols:
            gm = df[gm_cols[0]]
            summary['Gm_mean'] = float(gm.mean())
            summary['P_Gm_lt_0'] = float((gm < 0).mean())
        return summary
    
    # Find log files
    log_files = list(OUT_DIR.glob("*mcmc*.log")) + list(OUT_DIR.glob("*mcmc*.txt"))
    if not log_files:
        log_files = list(OUT_DIR.glob("*.log")) + list(OUT_DIR.glob("*.txt"))
    
    dd_summaries = {}
    for lf in log_files:
        label = lf.stem
        summary = load_dd_log(lf)
        if summary:
            dd_summaries[label] = summary
    
    results['dd_summaries'] = dd_summaries
    
    # Save overall results
    report = OUT_DIR / "threshold_dd_results.json"
    with open(report, 'w') as f:
        json.dump(results, f, indent=2, default=str)
    
    print(f"\nResults saved to {report}")
    
    # Print summary
    print("\n\n=== DD COEFFICIENT COMPARISON ===")
    print(f"{'Config':<30} {'Gl_mean':>8} {'Gl_2.5%':>9} {'Gl_97.5%':>9} {'P(>0)':>7}")
    print("-" * 65)
    for label, s in sorted(dd_summaries.items()):
        if 'Gl_mean' in s:
            print(f"{label:<30} {s['Gl_mean']:>8.3f} {s['Gl_p025']:>9.3f} {s['Gl_p975']:>9.3f} {s['P_Gl_gt_0']:>6.1%}")
    
    return results

if __name__ == "__main__":
    run_dd_analysis()