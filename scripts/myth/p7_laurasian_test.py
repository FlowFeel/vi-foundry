#!/usr/bin/env python3
"""P7 — Laurasian grammar test. Implements P7_LAURASIAN_PREREG.md exactly.

Grammar layer: region-level similarity from event-chain codings (mytheme-set
Jaccard, primitive-bigram Jaccard). Content layer: v3 Berezkin motif Jaccard.
All residualized on log(1+distance); contrasts per prereg sections.
"""
import json, os, itertools, random, statistics, math
import numpy as np

BASE = "/home/node/.openclaw/workspace/vi-foundry"
RES = os.path.join(BASE, "results/myths")
PARSED = "/home/node/.openclaw/workspace/corpora/berezkin_catalogue/parsed"

# ---- load all event-chain entries with a fixed file->region map (prereg)
FILE_REGION = {
    "ANCIENT_CODING.json": {"Egyptian": 14, "Mesopotamian": 17, "Akkadian": 17,
                            "Hittite": 29, "Ugaritic": 17},
    "NEW_ACQUISITIONS_CODING.json": {"Mesoamerica": 52, "Polynesia": 20},
    "CODING_P2_BATCH.json": {"Psalm": 17, "Rig": 23, "Veda": 23},
    "AINU_CODING.json": 38,
    "AUSTRALIA_CODING.json": 18,
    "GREY_MERGED.json": 20,
    "KOJIKI_MERGED.json": 38,
    "DAVISON_HAN_CODING.json": 26,
    "PHILIPPINES_CODING.json": 25,
    "TINGUIAN_CODING.json": 25,
    "RIFTIN_AMUR_EXTRACT.json": 37,
    "SIBERIA_CODING.json": 39,
    "TSIMSHIAN_CODING.json": 42,
    "BRETT_GUIANA_CODING.json": 59,
    "FORMOSAN_CONSENSUS.json": 25,
}
entries = []
for fname, spec in FILE_REGION.items():
    d = json.load(open(os.path.join(RES, fname)))
    for e in d:
        if not isinstance(e, dict) or 'event_chain' not in e or not e.get('event_chain'):
            continue
        if isinstance(spec, dict):
            reg = next((v for k, v in spec.items() if k in e.get("id", "")), None)
        else:
            reg = spec
        if reg is None:
            continue
        e = dict(e)
        e["_region"] = reg
        e["_src"] = fname
        entries.append(e)
# GRAMMAR_MATRIX_ALL stores event_primitives rather than raw chains; ANCIENT_CODING
# provides the ancient entries directly (region map in FILE_REGION above)
# dedupe by (id, region) keeping first
seen = set(); uniq = []
for e in entries:
    k = (str(e["id"]), e["_region"])
    if k in seen: continue
    seen.add(k); uniq.append(e)
entries = uniq

regions = {}
for e in entries:
    regions.setdefault(e["_region"], []).append(e)
used = sorted(r for r in regions if len(regions[r]) >= 2)
print("regions with >=2 entries:", [(r, len(regions[r])) for r in used])

LAUR = [r for r in used if r != 18]
OUTG = [18]

def prim_seq(e):
    return [c if isinstance(c, str) else c["event_type"] for c in e["event_chain"]]

def jac(a, b):
    A, B = set(a), set(b)
    return len(A & B) / len(A | B) if A | B else 0.0

def bigrams(seq):
    return set(zip(seq, seq[1:]))

# region pair similarities
import math
def hav(c1, c2):
    P = CENTROIDS[c1]; Q = CENTROIDS[c2]
    p = math.pi/180
    a = (math.sin((P[1]-Q[1])*p/2)**2 + math.cos(P[1]*p)*math.cos(Q[1]*p)*math.sin((P[0]-Q[0])*p/2)**2)
    return 2*6371*math.asin(math.sqrt(a))

CENTROIDS = {
    14:(10,28),17:(40,35),18:(133,-25),19:(150,-8),20:(-160,-15),23:(77,21),
    25:(122,15),26:(112,35),29:(43,40),37:(137,50),38:(138,37),39:(165,64),
    42:(-130,52),59:(-57,4),36:(110,62),40:(-85,65),
}

def region_sim(a, b, mode):
    vals = []
    for x, y in itertools.product(regions[a], regions[b]):
        if a == b and x is y: continue
        if mode == "mytheme":
            vals.append(jac(x.get("mythemes", []), y.get("mythemes", [])))
        else:
            vals.append(jac(bigrams(prim_seq(x)), bigrams(prim_seq(y))))
    return statistics.mean(vals)

# content region sets
tm = json.load(open(os.path.join(PARSED, "trait_matrix_full.json")))
csets = {r: {m for m, regs in tm.items() if r in regs} for r in used}

def content_sim(a, b):
    return jac(csets[a], csets[b])

pairs = list(itertools.combinations(used, 2))
# residualize each layer on log(1+d)
def residuals(simfn):
    sims, dists = [], []
    for a, b in pairs:
        sims.append(simfn(a, b)); dists.append(math.log1p(hav(a, b)))
    fit = np.polyfit(dists, sims, 1)
    return {p: s - np.poly1d(fit)(d) for p, s, d in zip(pairs, sims, dists)}

res_g1 = residuals(lambda a, b: region_sim(a, b, "mytheme"))
res_g2 = residuals(lambda a, b: region_sim(a, b, "bigram"))
res_c = residuals(content_sim)
LAYERS = {"G1_mytheme": res_g1, "G2_bigram": res_g2, "C_content": res_c}

out = {}
for name, resid in LAYERS.items():
    within = [resid[p] for p in itertools.combinations(LAUR, 2)]
    cross = [resid[(r, 18) if r < 18 else (18, r)] for r in LAUR]
    delta = statistics.mean(within) - statistics.mean(cross)
    # bootstrap CI over pairs
    rng = random.Random(11); boots = []
    for _ in range(10000):
        w = [within[rng.randrange(len(within))] for _ in range(len(within))]
        c = [cross[rng.randrange(len(cross))] for r in range(len(cross))]
        boots.append(statistics.mean(w) - statistics.mean(c))
    boots.sort()
    lo, hi = boots[int(0.025*len(boots))], boots[int(0.975*len(boots))]
    # pseudo-outgroup rank: actual Australia's delta rank among all 1-outgroup choices
    deltas = {}
    for cand in used:
        w = [resid[p] for p in itertools.combinations([r for r in used if r != cand], 2)]
        c = [resid[(min(r, cand), max(r, cand))] for r in used if r != cand]
        deltas[cand] = statistics.mean(w) - statistics.mean(c)
    rank = sorted(deltas, key=deltas.get).index(18) + 1  # 1 = most-distant delta
    out[name] = {"delta": round(delta, 4), "ci95": [round(lo, 4), round(hi, 4)],
                 "australia_delta": round(deltas[18], 4),
                 "australia_rank_out_of": f"{rank}/{len(used)}",
                 "n_within": len(within), "n_cross": len(cross)}
    print(name, out[name])

out["n_entries"] = len(entries); out["n_regions"] = len(used)
json.dump(out, open(os.path.join(RES, "P7_RESULTS.json"), "w"), indent=1)
print("saved P7_RESULTS.json")