#!/usr/bin/env python3
"""Content-layer test battery on the corrected (v3) Berezkin trait matrix.

Re-runs the pre-registered split-layer content tests (SPLIT_LAYER_TESTS_AND_PREDICTIONS.md
§1) on motifs_v3.json — the v3 parse fixed v2's region false-positives, so all
numbers here supersede the original doc figures which ran on the v1 matrix.

Tests:
  T1  Old World vs New World hemisphere block (shared-motif Jaccard)
  T2  PCA of region×motif presence; PC1 vs hemisphere alignment
  T3  Great-circle distance vs motif similarity (Spearman + Mantel-type perm test)
  T4  Same language family vs cross-family (approximate dominant-family map)
  T5  Same-family effect controlling for distance (partial correlation on residuals)

Outputs results/myths/content_tests_v3.{json,md}.
"""
import json, math, random, itertools, collections, re, os
import numpy as np

BASE = "/home/node/.openclaw/workspace/vi-foundry"
PARSED = "/home/node/.openclaw/workspace/corpora/berezkin_catalogue/parsed"
OUT = os.path.join(BASE, "results/myths")

motifs = json.load(open(os.path.join(PARSED, "motifs_v3.json")))
stats = json.load(open(os.path.join(PARSED, "stats.json")))

# ---- strict region definitions: a region counts as present only if the motif
# has a non-crossref body occurrence there (crossrefs are tagged by the parser)
def strict_regions(m):
    s = set()
    for k, v in m["regions"].items():
        if k.startswith("UNMAPPED"):
            continue
        if any(not x.get("crossref") for x in v):
            s.add(int(k))
    return s

region_sets = {}
for m in motifs:
    r = strict_regions(m)
    if r:
        region_sets[m["code"].upper()] = r

# add header-declared areal codes for motifs without body regions? No: header
# codes are the motif's aggregate distribution, not per-variant; keep body strict.
CODES = sorted({c for r in region_sets.values() for c in r})

# Region → B (set of motif codes present)
region_motifs = collections.defaultdict(set)
for code, r in region_sets.items():
    for c in r:
        region_motifs[c].add(code)
region_motifs = {c: v for c, v in region_motifs.items()}

# region label table (English, from regions.json)
labels = stats["region_key"]

RD = json.load(open(os.path.join(PARSED, "regions.json")))
label_of = lambda c: f"{c}-{RD[str(c)] if str(c) in RD else '?'}"

# ---- coordinates: first-order centroids (documented approximation, ±500km)
CENTROIDS = {
    10:(17,-22),11:(25,-3),12:(-5,9),13:(33,5),14:(10,28),15:(17,43),16:(0,46),
    17:(40,35),18:(133,-25),19:(150,-8),20:(-160,-15),21:(92,27),22:(102,15),
    23:(77,21),24:(112,-2),25:(122,15),26:(112,35),27:(22,43),28:(15,50),
    29:(43,40),30:(60,37),31:(17,62),32:(53,57),33:(67,42),34:(95,48),35:(72,61),
    36:(110,62),37:(137,50),38:(138,37),39:(165,64),
    40:(-85,65),41:(-110,57),42:(-130,52),43:(-120,47),44:(-90,42),45:(-75,45),
    46:(-100,42),47:(-85,32),48:(-120,37),49:(-117,40),50:(-110,34),51:(-108,27),
    52:(-95,17),53:(-84,10),54:(-70,19),55:(-74,5),56:(-67,6),57:(-63,3),
    59:(-57,4),60:(-78,-1),61:(-73,-5),62:(-70,0),63:(-60,-4),64:(-50,-4),
    65:(-73,-13),66:(-71,-9),67:(-63,-15),68:(-55,-12),69:(-49,-13),70:(-42,-10),
    71:(-46,-22),72:(-60,-23),73:(-51,-27),74:(-69,-40),
}

def hav(c1, c2):
    (lon1, lat1), (lon2, lat2) = CENTROIDS[c1], CENTROIDS[c2]
    p = math.pi / 180
    a = (math.sin((lat2-lat1)*p/2)**2 +
         math.cos(lat1*p)*math.cos(lat2*p)*math.sin((lon2-lon1)*p/2)**2)
    return 2*6371*math.asin(math.sqrt(a))

# ---- language families (approximate dominant-family sets for tradition pools)
FAM = {
    10:{"Khoisan","NigerCongo"},11:{"NigerCongo"},12:{"NigerCongo"},
    13:{"Afroasiatic","NiloSaharan"},14:{"Afroasiatic"},15:{"IE"},16:{"IE"},
    17:{"Afroasiatic"},18:{"PamaNyungan"},19:{"Austronesian","Papuan"},
    20:{"Austronesian"},21:{"SinoTibetan"},22:{"Austroasiatic","TaiKadai","SinoTibetan"},
    23:{"IE","Dravidian","Austroasiatic"},24:{"Austronesian"},25:{"Austronesian"},
    26:{"SinoTibetan","Japonic","Koreanic"},27:{"IE"},
    28:{"IE"},29:{"IE","Kartvelian","NCaucasian"},30:{"IE","Turkic"},
    31:{"IE","Uralic"},32:{"Uralic","Turkic"},33:{"Turkic"},
    34:{"Mongolic","Turkic","Tungusic"},35:{"Uralic"},
    36:{"Tungusic","Turkic","Uralic","Yeniseic"},37:{"Tungusic","Nivkh","Ainu"},
    38:{"Japonic","Ainu"},39:{"ChukotKamchatkan","EskimoAleut","Tungusic"},
    40:{"EskimoAleut"},41:{"Athabaskan","Algonquian"},42:{"Wakashan","Salishan","Tsimshianic","Athabaskan"},
    43:{"Salishan","Sahaptian","KTehuelche"},44:{"Algonquian","Siouan"},45:{"Algonquian","Iroquoian"},
    46:{"Siouan","Algonquian","Caddoan"},47:{"Muskogean","Siouan","Iroquoian"},
    48:{"UtoAztecan","Penutian"},49:{"UtoAztecan"},50:{"UtoAztecan","Yuman","Athabaskan"},
    51:{"UtoAztecan","Yuman"},52:{"Mayan","Otomanguean","UtoAztecan"},53:{"Chibchan","Mayan"},
    54:{"Arawakan","Cariban"},55:{"Chibchan","Cariban"},56:{"Arawakan"},
    57:{"Cariban"},59:{"Cariban","Arawakan"},60:{"Chibchan","Jivaroan","Barbacoan"},
    61:{"Arawakan","Panoan","Jivaroan"},62:{"Arawakan","Tucanoan"},63:{"Tupian"},
    64:{"Tupian","Cariban"},65:{"Quechuan","Aymaran"},66:{"Panoan","Arawakan"},
    67:{"Tacanan","Arawakan"},68:{"Tupian","MacroGe"},69:{"MacroGe"},
    70:{"MacroGe"},71:{"Tupian","MacroGe"},72:{"Matacoan","Guaicuruan"},
    73:{"Tupian","MacroGe"},74:{"Chonan","Araucanian"},
}

def jac(a, b):
    u = len(a | b)
    return len(a & b) / u if u else 0.0

results = {"n_regions": len(region_motifs), "n_motifs_with_presence": len(region_sets)}

# ---------------- T1 hemisphere block ----------------
OLD = [c for c in CODES if 10 <= c <= 39]
NEW = [c for c in CODES if c >= 40]
def mean_sim(group1, group2=None):
    gs = group2 if group2 is not None else group1
    vals = []
    pairs = list(itertools.combinations(group1, 2)) if group2 is None else list(itertools.product(group1, group2))
    for a, b in pairs:
        if a != b:
            vals.append(jac(region_motifs[a], region_motifs[b]))
    return float(np.mean(vals)), len(vals)
w_old, n_old = mean_sim(OLD)
w_new, n_new = mean_sim(NEW)
x_world, n_x = mean_sim(OLD, NEW)
results["T1"] = {
    "old_within_mean_jaccard": round(w_old, 4), "old_pairs": n_old,
    "new_within_mean_jaccard": round(w_new, 4), "new_pairs": n_new,
    "cross_mean_jaccard": round(x_world, 4), "cross_pairs": n_x,
    "signal_within_over_cross": round(np.mean([w_old, w_new]) / x_world, 2),
    "old_regions": len(OLD), "new_regions": len(NEW),
}

# cross-world pairs sharing >=1 motif (was ~1.4% claim in doc — verify with Jaccard>0)
shared_x = sum(1 for a, b in itertools.product(OLD, NEW) if a != b and region_motifs[a] & region_motifs[b])
results["T1"]["cross_pairs_sharing_any_motif_pct"] = round(100*shared_x/n_x, 1)

# ---------------- T2 PCA ----------------
reg_list = list(region_motifs)
motif_list = list(region_sets)
R = len(reg_list); M = len(motif_list)
X = np.zeros((R, M), dtype=np.float32)
ridx = {c: i for i, c in enumerate(reg_list)}
midx = {m: i for i, m in enumerate(motif_list)}
for c in reg_list:
    for mm in region_motifs[c]:
        X[ridx[c], midx[mm]] = 1
from scipy.sparse import csr_matrix
from sklearn.decomposition import PCA
Xc = csr_matrix(X)
import scipy.sparse as sp
mean_vec = np.asarray(X.mean(axis=0)).ravel()
Xd = X - mean_vec
Xd = X - mean_vec
p = PCA(n_components=5)
pcs = p.fit_transform(Xd)
results["T2"] = {
    "explained_ratio_pct": [round(v*100, 1) for v in p.explained_variance_ratio_],
    "old_mean_pc1": round(float(pcs[[ridx[c] for c in OLD], 0].mean()), 3),
    "new_mean_pc1": round(float(pcs[[ridx[c] for c in NEW], 0].mean()), 3),
}
# PC1-hemisphere point-biserial corr
hemi = np.array([0 if c in OLD else 1 for c in reg_list])
r_pc1 = float(np.corrcoef(hemi, pcs[:, 0])[0, 1])
results["T2"]["pc1_hemisphere_pointbiserial_r"] = round(abs(r_pc1), 3)

# ---------------- T3 distance vs similarity ----------------
pairs_sim = []
for a, b in itertools.combinations(reg_list, 2):
    pairs_sim.append((a, b, jac(region_motifs[a], region_motifs[b]), hav(a, b)))
sim = np.array([p[2] for p in pairs_sim]); dist = np.array([p[3] for p in pairs_sim])
from scipy.stats import spearmanr, pearsonr
rho, pv = spearmanr(sim, dist)
results["T3"] = {
    "n_pairs": len(pairs_sim), "spearman_rho": round(float(rho), 3),
    "p_value": f"{float(pv):.1e}".replace("e-", "×10⁻"),
    "pearson_r_logdist": round(float(pearsonr(sim, np.log1p(dist))[0]), 3),
}

# ---------------- T4 language family ----------------
same_f, cross_f = [], []
for a, b, s, d in pairs_sim:
    (same_f if FAM[a] & FAM[b] else cross_f).append((s, d))
results["T4"] = {
    "same_family_mean_jaccard": round(float(np.mean([s for s, d in same_f])), 4),
    "cross_family_mean_jaccard": round(float(np.mean([s for s, d in cross_f])), 4),
    "n_same": len(same_f), "n_cross": len(cross_f),
    "signal": round(float(np.mean([s for s, d in same_f])) / float(np.mean([s for s, d in cross_f])), 2),
}

# ---------------- T5 same-family controlling distance (permutation) ----------------
resid = np.asarray(sim) - np.poly1d(np.polyfit(np.log1p(dist), sim, 1))(np.log1p(dist))
lab = np.array([1 if FAM[a] & FAM[b] else 0 for a, b, s, d in pairs_sim])
mr_same = resid[lab == 1].mean(); mr_cross = resid[lab == 0].mean()
# permutation p
rng = random.Random(42)
perm = resid.copy(); cnt = 0; NB = 2000
obs = mr_same - mr_cross
for _ in range(NB):
    rng.shuffle(perm)
    d_ = perm[lab == 1].mean() - perm[lab == 0].mean()
    if d_ >= obs:
        cnt += 1
results["T5"] = {
    "same_family_resid_mean": round(float(mr_same), 4),
    "cross_family_resid_mean": round(float(mr_cross), 4),
    "delta": round(float(obs), 4),
    "perm_p": round((cnt + 1) / (NB + 1), 4), "n_perm": NB,
}

def _tofloat(o):
    if isinstance(o, dict):
        return {k: _tofloat(v) for k, v in o.items()}
    if isinstance(o, list):
        return [_tofloat(v) for v in o]
    if isinstance(o, (np.floating, np.integer)):
        return o.item()
    return o

json.dump(_tofloat(results), open(os.path.join(OUT, "content_tests_v3.json"), "w"), indent=1, ensure_ascii=False)

md = f"""# Content-Layer Tests v3 (corrected Berezkin matrix)

**Date:** 2026-10-16 · **Data:** motifs_v3.json — {results['n_motifs_with_presence']} motifs with areal presence, {results['n_regions']} regions, strict non-crossref occurrences
**Supersedes:** §1 of SPLIT_LAYER_TESTS_AND_PREDICTIONS.md (which ran on v1: 3,188 motifs, noisy region keys)

| Test | v3 result |
|---|---|
| T1 Old within / New within / cross (Jaccard) | {results['T1']['old_within_mean_jaccard']} ({results['T1']['old_regions']} reg) / {results['T1']['new_within_mean_jaccard']} ({results['T1']['new_regions']} reg) / {results['T1']['cross_mean_jaccard']} |
| T1 hemisphere signal | **{results['T1']['signal_within_over_cross']}×** ({results['T1']['cross_pairs_sharing_any_motif_pct']}% of cross-world pairs share ≥1 motif) |
| T2 PCA PC1/PC2 explained | {results['T2']['explained_ratio_pct'][0]}% / {results['T2']['explained_ratio_pct'][1]}%; PC1↔hemisphere r = {results['T2']['pc1_hemisphere_pointbiserial_r']} (OW {results['T2']['old_mean_pc1']}, NW {results['T2']['new_mean_pc1']}) |
| T3 distance vs similarity (n={results['T3']['n_pairs']}) | Spearman ρ = {results['T3']['spearman_rho']} (p {results['T3']['p_value']}); Pearson vs log-dist {results['T3']['pearson_r_logdist']} |
| T4 language family same/cross | {results['T4']['same_family_mean_jaccard']} vs {results['T4']['cross_family_mean_jaccard']} → **{results['T4']['signal']}×** (n {results['T4']['n_same']}/{results['T4']['n_cross']}) |
| T5 same-family residual after distance control | Δ = {results['T5']['same_family_resid_mean']} vs {results['T5']['cross_family_resid_mean']} (Δ {results['T5']['delta']}), perm p = {results['T5']['perm_p']} ({results['T5']['n_perm']} perms) |

**Notes**
- Coordinates are first-order region centroids (documented in `content_layer_tests_v3.py`); ±500 km error is noise at hemisphere scale.
- Language-family map is approximate dominant-family sets (also in script); T5's distance-controlled effect is the honest language test.
- Jaccard on strict (non-crossref) motif×region presence.
"""
open(os.path.join(OUT, "content_tests_v3.md"), "w").write(md)
print(json.dumps(_tofloat(results), indent=1, ensure_ascii=False))