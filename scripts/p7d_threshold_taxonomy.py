#!/usr/bin/env python3
"""Fix taxonomic naming mismatches and create 12-species threshold dataset."""
import pandas as pd
from pathlib import Path
import json

VHD = Path("/home/node/.openclaw/workspace/work/marsyas6/papers/valence-ingress/data/van-holstein/Data_Code_Final")
tax = pd.read_csv(VHD / "PyRate/Outputs/Wood-Boyle/WB_equivalent_taxonomy.csv")
occ = pd.read_excel(VHD / "PyRate/Data/Occurrence_database.xlsx")

print("=" * 60)
print("TAXONOMIC NAMING FIX & THRESHOLD")
print("=" * 60)

# Build occ counts dict
occ_counts = {}
for s in sorted(occ['Species_name'].unique()):
    occ_counts[s] = len(occ[occ['Species_name'] == s])

# Map occurrence species names to the taxonomy species names
# The occ database has a mix of "Homo erectus" (space) and "Homo_habilis" (underscore)
# Map both to the taxonomy names
name_map = {
    'Homo erectus': 'Homo erectus',
    'Homo_habilis': 'Homo habilis sensu lato',
    'Homo_rudolfensis': 'Homo habilis sensu lato',
    'Homo_heidelbergensis': 'Homo heidelbergensis',
    'Homo_neanderthalensis': 'Homo neanderthalensis',
    'Homo_sapiens': 'Homo sapiens',
    'Homo_floresiensis': 'Homo floresiensis',
    'Australopithecus_afarensis': 'Australopithecus afarensis',
    'Australopithecus_africanus': 'Australopithecus africanus',
    'Australopithecus_anamensis': 'Australopithecus anamensis',
    'Australopithecus_bahrelghazali': 'Australopithecus bahrelghazali',
    'Australopithecus_deyiremeda': 'Australopithecus deyiremeda',
    'Australopithecus_garhi': 'Australopithecus garhi',
    'Australopithecus_sediba': 'Australopithecus sediba',
    'Paranthropus aethiopicus': 'Paranthropus aethiopicus',
    'Paranthropus_boisei': 'Paranthropus boisei',
    'Paranthropus_robustus': 'Paranthropus robustus',
}

# Aggregate counts
tax_counts = {}
for raw_name, tax_name in name_map.items():
    cnt = occ_counts.get(raw_name, 0)
    tax_counts[tax_name] = tax_counts.get(tax_name, 0) + cnt

print("\nSpecies with occurrence counts (matched to taxonomy):")
for sp in sorted(tax_counts.keys()):
    cnt = tax_counts[sp]
    note = ""
    if cnt < 5: note = " [EXCLUDE]"
    if cnt == 0: note = " [MISSING]"
    print(f"  {sp:<35} {cnt:>3} occ{note}")

exclude = [sp for sp, cnt in tax_counts.items() if cnt < 5]
keep = [sp for sp, cnt in tax_counts.items() if cnt >= 5]
print(f"\nKeep ({len(keep)}): {', '.join(keep)}")
print(f"Exclude ({len(exclude)}): {', '.join(exclude)}")

# Write threshold taxonomy
thresh_tax = tax[tax['species'].isin(keep)].copy()
out_path = VHD / "PyRate/Outputs/threshold_5occ_taxonomy.csv"
thresh_tax.to_csv(out_path, index=False)
print(f"\nThreshold taxonomy: {out_path}")
print(f"  {len(thresh_tax)} species")

homo_keep = [s for s in keep if s.startswith('Homo')]
nonhomo_keep = [s for s in keep if not s.startswith('Homo')]
print(f"  Homo: {len(homo_keep)} — {', '.join(homo_keep)}")
print(f"  Non-Homo: {len(nonhomo_keep)} — {', '.join(nonhomo_keep)}")

results = {"species_keep": keep, "species_exclude": exclude,
           "n_homo_keep": len(homo_keep), "n_nonhomo_keep": len(nonhomo_keep),
           "homo_keep": homo_keep, "nonhomo_keep": nonhomo_keep}
json.dump(results, open("/home/node/.openclaw/workspace/vi-foundry/results/threshold-taxonomy-results.json", 'w'), indent=2)
print("Done.")