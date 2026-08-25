import pandas as pd, numpy as np, re
from scipy import stats
from Bio import SeqIO

B = '/home/node/.openclaw/workspace/vi-foundry/data/t7-ltee/'
gbk_path = B+'LTEE-metagenomic/additional_data/REL606.6.gbk'

# Parse REL606 genome - extract gene name, protein length (aa), CDS length (bp)
records = list(SeqIO.parse(gbk_path, 'genbank'))
rec = records[0]
gene_info = {}
for feat in rec.features:
    if feat.type == 'CDS':
        gene = None
        for key in ['gene','locus_tag']:
            if key in feat.qualifiers:
                gene = feat.qualifiers[key][0]
                break
        if not gene:
            continue
        # protein length = translation length
        prot_len = None
        aa_len = None
        if 'translation' in feat.qualifiers:
            aa_len = len(feat.qualifiers['translation'][0])
        # CDS length
        cds_len = len(feat)
        gene_info[gene] = {
            'cds_length': cds_len,
            'protein_length': aa_len,
            'aa_cost': (aa_len * 5 if aa_len else None),  # ~5 ATP/aa synthesis cost
            'locus_tag': feat.qualifiers.get('locus_tag',[None])[0]
        }
print(f"Parsed {len(gene_info)} genes from REL606")

# Load lost genes
merged = pd.read_csv(B+'t7_merged_analysis.tsv', sep='\t')
lost = merged.dropna(subset=['first_gen']).copy()
lost['first_gen'] = lost['first_gen'].astype(float)
sc = pd.read_csv(B+'string_centrality.tsv', sep='\t')
sc_map = sc.set_index('b_number')

# Map gene name -> info
lost['cds_length'] = lost['gene'].map(lambda g: gene_info.get(g,{}).get('cds_length'))
lost['protein_length'] = lost['gene'].map(lambda g: gene_info.get(g,{}).get('protein_length'))
lost['aa_cost'] = lost['gene'].map(lambda g: gene_info.get(g,{}).get('aa_cost'))

# Merge with metabolic/FBA
lost['met_degree'] = lost['b_number'].map(sc_map['met_degree'])
lost['fba_dep_ltee'] = lost['b_number'].map(sc_map['fba_dep_ltee'])

print(f"Lost genes with length data: {lost['protein_length'].notna().sum()} / {len(lost)}")
print()

print("=== TRUE MAINTENANCE COST vs LOSS TIMING ===")
print("Prediction: longer protein (higher biosynthetic cost) shed EARLIER (rho < 0)")
for col, label in [('protein_length','protein length (aa)'),
                   ('cds_length','CDS length (bp)'),
                   ('aa_cost','AA synthesis cost (~5ATP/aa)')]:
    sub = lost[['first_gen', col]].dropna()
    if len(sub) < 10:
        print(f"  {label}: insufficient ({len(sub)})")
        continue
    rho, p = stats.spearmanr(sub['first_gen'], sub[col])
    print(f"  {label}: rho={rho:.3f}, p={p:.4f}, n={len(sub)}")

print()
print("=== MAINTENANCE COST × DISPENSABILITY (the full hypothesis) ===")
print("Cost-to-shed driver = biosynthetic cost × dispensability-in-niche")
# dispensability = (1 - fba_dep_ltee): 1 = totally dispensable, 0 = essential
sub = lost[['first_gen','protein_length','fba_dep_ltee']].dropna()
sub['dispensability'] = 1 - sub['fba_dep_ltee']
sub['cost_x_disp'] = sub['protein_length'] * sub['dispensability']
rho, p = stats.spearmanr(sub['first_gen'], sub['cost_x_disp'])
print(f"  protein_length × dispensability: rho={rho:.3f}, p={p:.4f}, n={len(sub)}")

# Also: cost to maintain OVER TIME (what the organism pays)
# maintenance cost per generation = protein length (maintained each gen)
sub['cum_cost'] = sub['protein_length'] * sub['first_gen']
rho2, p2 = stats.spearmanr(sub['first_gen'], sub['cum_cost'])
print(f"  cumulative maintenance paid before shed: rho={rho2:.3f}, p={p2:.4f}")

# Split high/low cost
med = sub['protein_length'].median()
hi = sub[sub['protein_length']>med]
lo = sub[sub['protein_length']<=med]
if len(hi) and len(lo):
    mw = stats.mannwhitneyu(hi['first_gen'], lo['first_gen'])
    print(f"  High-cost genes shed at gen {hi['first_gen'].median():.0f} (n={len(hi)})")
    print(f"  Low-cost genes shed at gen {lo['first_gen'].median():.0f} (n={len(lo)})")
    print(f"  Mann-Whitney p={mw.pvalue:.4f}")

print()
print("=== Raw comparison table (top 15 by length) ===")
cols = ['gene','first_gen','protein_length','fba_dep_ltee','met_degree']
sub2 = lost[cols].dropna(subset=['protein_length']).sort_values('protein_length',ascending=False)
print(sub2.head(15).to_string(index=False))
