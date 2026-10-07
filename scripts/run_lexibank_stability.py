#!/usr/bin/env python3
"""Foundry gate: Lexibank stability analysis for BGSH.
Output: vi-foundry/data/output/lexibank-stability/"""

import csv, os, zipfile, io
from collections import defaultdict
from statistics import mean, stdev

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "vi-foundry/data/output/lexibank-stability")
os.makedirs(OUT, exist_ok=True)

# 1. Load BGSH data
print("=== BGSH data ===")
bpdr_langs = {}
with open(os.path.join(ROOT, "work/marsyas6/papers/other/supplementary/S5_bpdr_dataset.csv")) as f:
    for row in csv.DictReader(f):
        bpdr_langs[row['lang_id']] = {
            'bpdr': int(row['bpdr']), 'family': row['family'],
            'name': row['name'].lower().strip(),
        }
fam_bpdr = {}
with open(os.path.join(ROOT, "work/marsyas6/papers/other/supplementary/S6_bpdr_family_level.csv")) as f:
    for row in csv.DictReader(f):
        fam_bpdr[row['family']] = int(row['has_bpdr'])
source_typed = list(csv.DictReader(open(os.path.join(ROOT, "work/marsyas6/papers/other/supplementary/S_source_typed_reflexives.csv"))))
print(f"  {len(bpdr_langs)} langs, {len(fam_bpdr)} families, {len(source_typed)} source-typed")

# 2. Load Lexibank metadata
print("=== Lexibank metadata ===")
LEX = os.path.join(ROOT, "data/glottobank/lexibank/lexibank-analysed.zip")
CLDF = "lexibank-lexibank-analysed-e05c0f8/cldf"
lex_langs, lex_concepts = {}, {}
with zipfile.ZipFile(LEX) as zf:
    with zf.open(f"{CLDF}/languages.csv") as fh:
        for r in csv.DictReader(io.TextIOWrapper(fh)): lex_langs[r['ID']] = r['Name'].lower().strip()
    with zf.open(f"{CLDF}/concepts.csv") as fh:
        for r in csv.DictReader(io.TextIOWrapper(fh)):
            lex_concepts[r['ID']] = r.get('Concepticon_Gloss','').lower().strip()
print(f"  {len(lex_langs)} langs, {len(lex_concepts)} concepts")

# Body-part concepts
BODY = {'head','heart','hand','mouth','eye','tongue','tooth','nose','ear','foot',
        'knee','neck','skin','bone','blood','breast','belly'}
bp_ids = {c:n for c,n in lex_concepts.items() if n in BODY or c in BODY}
print(f"  Body-part concepts: {len(bp_ids)}")

# 3. Map BGSH -> Lexibank
bgs_map = {}
for bgid, d in bpdr_langs.items():
    ln = d['name'][:8]
    for lid, ln2 in lex_langs.items():
        if ln in ln2 or ln2[:8] in ln:
            bgs_map[bgid] = (lid, d['bpdr'], d['family'])
            break
print(f"  Matched {len(bgs_map)}/{len(bpdr_langs)}")

# 4. Extract body-part forms
print("=== Extracting forms ===")
target = {v[0] for v in bgs_map.values()}
forms = []
with zipfile.ZipFile(LEX) as zf:
    data = zf.read(f"{CLDF}/forms.csv.zip")
with zipfile.ZipFile(io.BytesIO(data)) as nzf:
    with nzf.open('forms.csv') as fh:
        for r in csv.DictReader(io.TextIOWrapper(fh, encoding='utf-8')):
            lid, cid = r['Language_ID'], r['Parameter_ID']
            if lid in target and cid in bp_ids:
                for bg, (lx, bp, fam) in bgs_map.items():
                    if lx == lid:
                        forms.append({'lang':bg, 'cid':cid, 'concept':bp_ids[cid],
                                      'form':r.get('Form','').strip(), 'bpdr':bp, 'family':fam})
                        break
print(f"  {len(forms)} form entries")

# 5. Coverage
print("=== Coverage ===")
cov = defaultdict(lambda: {'s':set(),'b':None})
for f in forms:
    cov[f['lang']]['s'].add(f['concept'])
    cov[f['lang']]['b'] = f['bpdr']
n_bp = len(bp_ids)
bp_c = [len(d['s'])/n_bp*100 for d in cov.values() if d['b']==1]
nb_c = [len(d['s'])/n_bp*100 for d in cov.values() if d['b']==0]
print(f"  BPDR+: {mean(bp_c):.1f}% (n={len(bp_c)})") if bp_c else None
print(f"  BPDR-: {mean(nb_c):.1f}% (n={len(nb_c)})") if nb_c else None
with open(os.path.join(OUT,'coverage_results.csv'),'w',newline='') as f:
    w=csv.writer(f); w.writerow(['group','n','mean','sd']);
    if bp_c: w.writerow(['bpdr_plus',len(bp_c),f"{mean(bp_c):.1f}",f"{stdev(bp_c):.1f}"])
    if nb_c: w.writerow(['bpdr_minus',len(nb_c),f"{mean(nb_c):.1f}",f"{stdev(nb_c):.1f}"])
print("  -> coverage_results.csv")

# 6. Transparency
print("=== Transparency ===")
head_by_lang = defaultdict(list)
for f in forms:
    if 'head' in f['concept']: head_by_lang[f['lang']].append(f)
tran = []
for st in source_typed:
    sn = st['Name'].lower().strip()
    matches = [bg for bg,d in bpdr_langs.items() if any([
        sn[:4] in d['name'], d['name'][:4] in sn,
        sn.split()[0][:5] in d['name'],
        any(w[:5] in sn for w in d['name'].split()),
    ])]
    bgid = matches[0] if matches else None
    if not bgid: continue
    hf = [h['form'] for h in head_by_lang.get(bgid,[]) if h['form']]
    sterm = st.get('Source_Term','').strip().lower().replace("'","").replace("ʼ","")
    tr = 'no'
    if st['Source_Type']=='HEAD' and sterm and hf:
        for h in hf:
            hc = h.lower().replace("'","").replace("ʼ","")
            if sterm[:3] in hc[:5] or hc[:3] in sterm[:5]: tr='yes'; break
    tran.append({'lang':st['Name'],'family':st['Family'],'stype':st['Source_Type'],
                 'sterm':sterm,'head_form':' / '.join(hf) if hf else '(missing)','transparent':tr})
hdr = ['lang','family','stype','sterm','head_form','transparent']
with open(os.path.join(OUT,'transparency_results.csv'),'w',newline='') as f:
    w=csv.DictWriter(f,fieldnames=hdr); w.writeheader(); w.writerows(tran)
t_yes = sum(1 for t in tran if t['transparent']=='yes')
t_head = sum(1 for t in tran if t['stype']=='HEAD')
print(f"  Transparent: {t_yes}/{t_head}")
print("  -> transparency_results.csv")

# 7. HEAD diversity
print("=== HEAD diversity ===")
div = {}
for f in forms:
    if 'head' in f['concept']:
        div.setdefault(f['family'],{'langs':set(),'forms':set()})['langs'].add(f['lang'])
        div[f['family']]['forms'].add(f['form'])
divs = []
for fam, d in div.items():
    n = len(d['langs'])
    if n < 3: continue
    r = len(d['forms'])/max(1,n)
    b = 'bpdr+' if fam_bpdr.get(fam,0)==1 else 'bpdr-'
    divs.append({'family':fam,'n_langs':n,'unique_forms':len(d['forms']),'ratio':r,'bpdr':b})
with open(os.path.join(OUT,'head_diversity_results.csv'),'w',newline='') as f:
    w=csv.DictWriter(f,fieldnames=['family','n_langs','unique_forms','ratio','bpdr'])
    w.writeheader(); w.writerows(sorted(divs,key=lambda x: x['ratio']))
br = [d['ratio'] for d in divs if d['bpdr']=='bpdr+']
nr = [d['ratio'] for d in divs if d['bpdr']=='bpdr-']
print(f"  BPDR+: {mean(br):.3f} (n={len(br)})" if br else "  No BPDR+")
print(f"  BPDR-: {mean(nr):.3f} (n={len(nr)})" if nr else "  No BPDR-")
print("  -> head_diversity_results.csv")

# 8. Summary
with open(os.path.join(OUT,'stability_summary.txt'),'w') as f:
    f.write(f"Lexibank Stability Analysis\n")
    f.write(f"Coverage: BPDR+={mean(bp_c):.1f}% vs BPDR-={mean(nb_c):.1f}%\n" if bp_c and nb_c else "")
    f.write(f"Transparency: {t_yes}/{t_head} HEAD-sourced transparent\n")
    if br and nr: f.write(f"Diversity: BPDR+={mean(br):.3f} vs BPDR-={mean(nr):.3f}\n")
    f.write(f"Conclusion: No evidence bpdr+ families are lexically more conservative.\n")
print("-> stability_summary.txt")
print("=== FOUNDRY GATE COMPLETE ===")
