#!/usr/bin/env python3
"""
Full myth pipeline runner for the foundry.
Processes all available datasets and writes results to results/myths/.
"""
import sys, os, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from myth_pipeline import *

def run_simulacra(n_sims=3):
    """Run multiple simulacra and show recovery stats."""
    print("=" * 50)
    print("PHYLOMYTHOLOGY SIMULACRA")
    print("=" * 50)
    for s in range(1, n_sims + 1):
        seed = 42 + s
        sim = simulacrum_myth_data(n_versions=20 + s * 10, n_slow=6, n_fast=12,
                                    noise_level=0.15, seed=seed)
        res = run_myth_pipeline(sim, f"simulacrum_{s}", seed=seed)
        s_ = res['contradiction_summary']
        sig = res['signal']
        outpath = f'results/myths/simulacrum_{s}.json'
        os.makedirs(os.path.dirname(outpath), exist_ok=True)
        with open(outpath, 'w') as f:
            json.dump(res, f, indent=2, default=str)
        print(f"  Sim {s}: {sim['n_versions']}v×{sim['n_characters']}c "
              f"slow={s_['n_slow']} fast={s_['n_fast']} "
              f"meanCI={s_['mean_contradiction']:.3f} "
              f"sig_p={sig['p_value']:.4f} → {outpath}")


def run_all_datasets():
    """Process all real datasets found in data/myths/."""
    print()
    print("=" * 50)
    print("REAL DATASETS")
    print("=" * 50)
    data_dir = 'data/myths'
    if not os.path.exists(data_dir):
        print(f"  {data_dir} not found")
        return
    
    csvs = [f for f in os.listdir(data_dir) if f.endswith('.csv') and '_matrix' in f]
    if not csvs:
        print("  No matrix CSV files found. Need to extract from PDFs first.")
        print("  Expected: cosmic_hunt_matrix.csv, exogamy_matrix.csv, serpent_motifs_matrix.csv")
        return
    
    for fname in sorted(csvs):
        path = os.path.join(data_dir, fname)
        name = fname.replace('_matrix.csv', '')
        print(f"\n  Loading {fname}...")
        data = load_myth_matrix(path)
        print(f"    {data['n_versions']} versions × {data['n_characters']} characters")
        res = run_myth_pipeline(data, name, seed=42)
        s_ = res['contradiction_summary']
        sig = res['signal']
        outpath = f'results/myths/{name}.json'
        with open(outpath, 'w') as f:
            json.dump(res, f, indent=2, default=str)
        print(f"    slow={s_['n_slow']} fast={s_['n_fast']} "
              f"meanCI={s_['mean_contradiction']:.3f} "
              f"sig_p={sig['p_value']:.4f} → {outpath}")


def extract_matrices_from_pdfs():
    """
    Placeholder for PDF-to-CSV extraction.
    The annex PDFs need character matrices transcribed.
    """
    print()
    print("=" * 50)
    print("PDF MATRIX EXTRACTION")
    print("=" * 50)
    papers_dir = '../work/marsyas6/papers/myths'
    print(f"  Check: {papers_dir}")
    print(f"  Need to extract from:")
    print(f"    - thuillard-lequellec-dhuy-berezkin_2018_large-scale-world-myths-annex.pdf")
    print(f"    - dhuy_2020_mythologie-matrimoniale.pdf (exogamy motifs)")
    print(f"    - dhuy_2023_aux-origines-du-dragon-nmc7.pdf (serpent motifs)")
    print(f"    - berezkin JSON catalogue (for presence-absence analysis)")
    print()
    print(f"  Manual transcription needed: PDF tables → CSV matrices")
    print(f"  Output: data/myths/cosmic_hunt_matrix.csv etc.")


if __name__ == '__main__':
    run_simulacra(3)
    run_all_datasets()
    extract_matrices_from_pdfs()