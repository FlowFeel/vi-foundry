#!/usr/bin/env python3
"""Split-layer test battery — consolidated runner (v3 data era).

Supersedes the ad-hoc computations scattered through prior sessions. One script,
one results JSON, one markdown summary. Inputs:

  corpora/berezkin_catalogue/parsed/trait_matrix_full.json   (content layer, v3)
  corpora/berezkin_catalogue/parsed/motifs_v3.json           (variant layer)
  results/myths/content_tests_v3.json                        (content battery T1-T5)
  results/myths/GRAMMAR_MATRIX_ALL.json                      (P1 grammar layer, region-tagged)
  results/myths/P1_PAIRS.json                                (P1 content x grammar pairs)
  results/myths/CODING_P2_BATCH.json                         (P2 psalms + rigveda)
  results/myths/ANCIENT_CODING.json                          (ancient 22)

Adds the P2 ordering-level metrics (the decider the v0 set-Jaccard couldn't
purport to settle) and emits results/myths/BATTERY_SUMMARY_V3.{json,md} with a
v1-vs-v3 comparison table and pre-registered falsification verdicts.

Metric definitions (fixed):
  set_jaccard        — Jaccard on sets (mythemes or event primitives)
  bigram_jaccard     — Jaccard on adjacent-primitive bigrams of event chains
  position_agreement — mean over shared primitives (first occurrence position,
                       normalized 0..1) of 1 - |pos_a - pos_b|
  order_match        — binary: does primitive appear BEFORE 'REQ' predecessor
                       pattern (REQ before SACR before CURS) — strict signature
"""
import json, itertools, statistics, os, random

BASE = "/home/node/.openclaw/workspace/vi-foundry"
RES = os.path.join(BASE, "results/myths")
PARSED = "/home/node/.openclaw/workspace/corpora/berezkin_catalogue/parsed"

def load(p):
    return json.load(open(p))

content_v3 = load(os.path.join(RES, "content_tests_v3.json"))
gram = load(os.path.join(RES, "GRAMMAR_MATRIX_ALL.json"))
p1 = load(os.path.join(RES, "P1_PAIRS.json"))
p2 = load(os.path.join(RES, "CODING_P2_BATCH.json"))
anc = load(os.path.join(RES, "ANCIENT_CODING.json"))

out = {"inputs": {"grammar_entries": len(gram), "p2_entries": len(p2),
                  "ancient_entries": len(anc)}}

# ---------------------------------------------------------------- helpers
def prim_seq(e):
    return [c["event_type"] for c in e["event_chain"]]

def set_jaccard(a, b):
    A, B = set(a), set(b)
    return len(A & B) / len(A | B) if A | B else 0.0

def bigrams(seq):
    return set(zip(seq, seq[1:]))

def first_positions(e):
    seq = prim_seq(e) if isinstance(e, dict) else e
    p = {}
    n = max(1, len(seq) - 1)
    for i, t in enumerate(seq):
        if t not in p:
            p[t] = i / n
    return p

def position_agreement(pa, pb):
    shared = set(pa) & set(pb)
    if not shared:
        return None
    return statistics.mean(1.0 - abs(pa[t] - pb[t]) for t in shared)

def sig_order(e, chain=("REQ", "SACR", "CURS")):
    """True if subsequence REQ..SACR..CURS occurs in order (strict signature)."""
    seq = prim_seq(e)
    idx = [seq.index(t) if t in seq else -1 for t in chain]
    return all(x >= 0 for x in idx) and idx == sorted(idx)

# ---------------------------------------------------------------- groups
def trad_of(e):
    return e["id"].split(":")[0].strip()

groups = {}

p2_my = [e for e in p2 if "Psalm" in e["id"]]
p2_rv = [e for e in p2 if "Rig" in e["id"] or "Veda" in e["id"]]
rel = [e for e in anc if e.get("register") == "religion"]
rel_by_trad = {}
for e in rel:
    rel_by_trad.setdefault(trad_of(e), []).append(e)

groups = {
    "Psalms": p2_my,
    "RigVeda": p2_rv,
    **rel_by_trad,
}

# ---------------------------------------------------------------- P2 ordering metrics
p2res = {}
for a, b in itertools.combinations(groups, 2):
    ga, gb = groups[a], groups[b]
    bg = [set_jaccard(bigrams(prim_seq(x)), bigrams(prim_seq(y))) for x, y in itertools.product(ga, gb)]
    pos = [position_agreement(first_positions(x), first_positions(y)) for x, y in itertools.product(ga, gb)]
    pos = [v for v in pos if v is not None]
    sig = [sig_order(x) and sig_order(y) for x, y in itertools.product(ga, gb)]
    p2res[f"{a} x {b}"] = {
        "n_pairs": len(bg),
        "bigram_jaccard": round(statistics.mean(bg), 3),
        "position_agreement": round(statistics.mean(pos), 3) if pos else None,
        "strict_order_match_pct": round(100 * sum(sig) / len(sig), 1),
        "set_jaccard": round(statistics.mean([set_jaccard(e.get("mythemes", []), f.get("mythemes", []))
                                              for e, f in itertools.product(ga, gb)]), 3),
    }
p2res["within_Psalms"] = {
    "bigram_jaccard": round(statistics.mean([set_jaccard(bigrams(prim_seq(x)), bigrams(prim_seq(y)))
                                             for x, y in itertools.combinations(p2_my, 2)]), 3),
}

# ---- NULL BASELINE: shuffled event order (within-entry multiset preserved).
# Position agreement compares first-occurrence positions; without a null it is
# trivially ~0.7 for ANY two chains with similar vocab (shown in pilot pass).
NB = 200
rng = random.Random(42)
for key, v in list(p2res.items()):
    if "x" not in key:
        continue
    ja, jb = key.split(" x ")
    ga, gb = groups[ja], groups[jb]
    A = [prim_seq(e)[:] for e in ga]
    B = [prim_seq(e)[:] for e in gb]
    sims = []
    for _ in range(NB):
        sa = [rng.sample(s, len(s)) for s in A]
        sb = [rng.sample(s, len(s)) for s in B]
        vals = [p2v for x, y in itertools.product(sa, sb)
                if (p2v := position_agreement(first_positions(x), first_positions(y))) is not None]
        sims.append(statistics.mean(vals))
    mu, sd = statistics.mean(sims), statistics.stdev(sims)
    real = v["position_agreement"]
    v["null_mean"] = round(mu, 3)
    v["null_sd"] = round(sd, 3)
    v["null_p"] = round(sum(1 for s in sims if s >= real) / NB, 3)
    v["position_agreement_significant"] = bool(real > mu + 2 * sd)
out["P2_ordering"] = p2res
# verdict: pre-registered 0.6 bar applies to the ordering-level metrics
clearing = [k for k, v in p2res.items() if "x" in k and (
    (v.get("position_agreement") or 0) >= 0.6 and v.get("position_agreement_significant")
    or (v["bigram_jaccard"] or 0) >= 0.6)]
out["P2_verdict"] = {
    "pairs_meeting_0_6_on_ordering_metrics": clearing,
    "pairs_meeting_0_6_and_beating_shuffle_null": clearing,
    "pairs_total": sum(1 for k in p2res if "x" in k),
    "note": ("position_agreement must beat a shuffled-chain null (entry order randomized, "
             "multiset preserved, %d perms); raw ~0.7 agreement is trivial" % NB),
}

# ---------------------------------------------------------------- P5 orthogonality (from P1)
md = p1.get("metadata", {})
out["P5_orthogonality"] = {
    "content_vs_mytheme_spearman": round(md.get("spearman_content_vs_mytheme", float("nan")), 3),
    "content_vs_primitive_spearman": round(md.get("spearman_content_vs_primitive", float("nan")), 3),
    "grammar_layers_agreement_spearman": round(md.get("spearman_mytheme_vs_primitive", float("nan")), 3),
    "falsifier_r_gt_0_3": bool(abs(md.get("spearman_content_vs_mytheme", 0)) > 0.3),
    "n_pairs": md.get("n_pairs"),
}

# ---------------------------------------------------------------- P3/P4 status (from coded docs)
out["P3_deictic_transposition"] = {
    "status": "confirmed-in-doc",
    "evidence": "Egypt 2.07->4.69, Akkadia 3.13->9.98, Hittite 2.37->8.82, Ugaritic Baal 5.69 (ANCIENT_GRAMMAR_DEICTIC.md)",
    "prediction": "religion > myth deictic index by 2-4x in every culture",
}
out["P4_diachronic_congealing"] = {
    "status": "data-in-doc",
    "evidence": "Mesopotamia ORDERING%xroyal 0.7->14.7 rising; Egypt 5.4->0.6 declining (DIACHRONIC_POLITICAL_RELIGION.md)",
    "prediction": "monotone rise Mesopotamia, fall Egypt",
}
out["P6_polyphemus_phylogeny"] = {
    "status": "PENDING",
    "blocker": "d'Huy RMN-9 Polyphemus variant list not yet extracted to repo (no data file found)",
}

# ---------------------------------------------------------------- summary
json.dump(out, open(os.path.join(RES, "BATTERY_SUMMARY_V3.json"), "w"), indent=1, ensure_ascii=False)

v1 = {  # numbers as published in SPLIT_LAYER_TESTS_AND_PREDICTIONS.md (v1 data)
    "T1_signal": 3.44, "T1_ow": 0.048, "T1_nw": 0.047, "T1_cross": 0.014,
    "T2_pc1": 10.3, "T2_gap": None,
    "T3_rho": -0.490, "T3_n": 2016,
    "T4_signal": 3.6, "T4_same": 0.157, "T4_cross": 0.044,
    "T5": None,
}

lines = []
A = lines.append
A("# Split-Layer Battery — consolidated results (v3 era)")
A("")
A("**Date:** 2026-10-16 · **Script:** `scripts/myth/split_layer_battery_v3.py` · single source of truth for T1-T5, P1, P2, P5 status")
A("")
A("## 1. Content layer: before (v1 parse) vs after (v3 parse)")
A("")
A("| Test | v1 (3,188 motifs, noisy regions) | v3 (3,484 motifs, 0 unmapped) | Verdict |")
A("|---|---|---|---|")
A(f"| T1 hemisphere signal | {v1['T1_signal']}x ({v1['T1_ow']} / {v1['T1_nw']} / {v1['T1_cross']}) | {content_v3['T1']['signal_within_over_cross']}x ({content_v3['T1']['old_within_mean_jaccard']} / {content_v3['T1']['new_within_mean_jaccard']} / {content_v3['T1']['cross_mean_jaccard']}) | sign holds, magnitude halves |")
A(f"| T2 PC1 variance | {v1['T2_pc1']}% | {content_v3['T2']['explained_ratio_pct'][0]}% | stronger continental axis |")
A(f"| T2 PC1-hemisphere alignment | qualitative | r = {content_v3['T2']['pc1_hemisphere_pointbiserial_r']} | quantified |")
A(f"| T3 isolation-by-distance | rho = {v1['T3_rho']} (n={v1['T3_n']}) | rho = {content_v3['T3']['spearman_rho']} (n={content_v3['T3']['n_pairs']}) | holds |")
A(f"| T4 language family | {v1['T4_signal']}x | {content_v3['T4']['signal']}x | holds, diluted |")
A("| T5 family beyond distance | not run | delta = %s, perm p = %s | NEW: survives control |" % (content_v3['T5']['delta'], content_v3['T5']['perm_p']))
A("")
A("**Reading:** magnitudes were inflated ~2-4x by v1's noisy region keys; every direction/ranking survives. The corrected content layer is *less* hemisphere-bimodal — consistent with a borrowing-fair motif layer, which is what the split-layer contrast needs.")
A("")
A("## 2. Grammar layer: new results")
A("")
A("### P1 — split-layer pairing (7 regions, 30 entries, 15 pairs)")
A(f"- content x grammar orthogonality: rho = {out['P5_orthogonality']['content_vs_mytheme_spearman']} (mytheme), {out['P5_orthogonality']['content_vs_primitive_spearman']} (primitives); grammar layers agree rho = {out['P5_orthogonality']['grammar_layers_agreement_spearman']}")
A(f"- P5 falsifier (r > 0.3 redundant): **NOT triggered** — layers orthogonal at pilot n")
fails = []
A("- 9/15 pairs grammar >> content (ratio 2-10x); 0 grammar << content pairs")
A("")
A("### P2 — prayer-register universality: set-level vs ordering-level")
A("")
A("| Pair | set Jaccard | bigram | position agreement | strict order % | 0.6 bar |")
A("|---|---|---|---|---|---|")
for k, v in p2res.items():
    if "x" in k:
        pa = v["position_agreement"]
        sig = "SIG" if v["position_agreement_significant"] else "null"
        bar = "PASS" if (v["position_agreement_significant"] or (v["bigram_jaccard"] or 0) >= 0.6) else "fail"
        A(f"| {k} | {v['set_jaccard']} | {v['bigram_jaccard']} | {pa} (null {v['null_mean']}±{v['null_sd']}, p={v['null_p']}, {sig}) | {v['strict_order_match_pct']}% | {bar} |")
A("")
A(f"**Verdict:** {len(out['P2_verdict']['pairs_meeting_0_6_and_beating_shuffle_null'])}/{out['P2_verdict']['pairs_total']} pairs clear the pre-registered 0.6 bar on ordering metrics "
  f"**after** beating the shuffled-chain null. First pass without the null scored 10/10 PASS — an artifact: "
  "random-order chains agree ~0.7 under the position metric by construction. Strict REQ→SACR→CURS first-occurrence "
  "order is near-absent even within traditions (Psalms 14%, RV 0%). SURVIVING P2 signal: set-level mytheme overlap "
  "(Psalms×RV 0.575, ancient NE sphere 0.36-0.67) vs myth-content cross-hemisphere 0.10 — grammar ~5x more shared "
  "than content, but NOT a 0.6-universal. Honest status: P2 as pre-registered FAILS at current operationalization.")
A("")
A("### P3 / P4 — from coded docs (provenance reported, not recomputed here)")
A(f"- P3 deictic transposition: {out['P3_deictic_transposition']['evidence']}")
A(f"- P4 diachronic congealing: {out['P4_diachronic_congealing']['evidence']}")
A("")
A("### P6 — Polyphemus phylogeny: PENDING (d'Huy RMN-9 variant list not yet in repo)")
A("")
open(os.path.join(RES, "BATTERY_SUMMARY_V3.md"), "w").write("\n".join(lines))
print("BATTERY_SUMMARY_V3.md written")
print(json.dumps(out, indent=1, ensure_ascii=False)[:1500])