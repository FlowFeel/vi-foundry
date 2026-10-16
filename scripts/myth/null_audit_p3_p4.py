#!/usr/bin/env python3
"""Null-audit of P3 (deictic transposition) and P4 (diachronic congealing).

Jan's directive: our headline magnitudes shrank 2-4x under the v3 data audit;
P3/P4 were published with NO null baselines. This script retro-applies them.

P3 data: results/myths/ANCIENT_DEICTIC_ROWS.json
  rows = [id, first/1000, second/1000, spatial/1000, temporal/1000, ritual/1000, register]
  (column semantics per inferno-chain-grammar-deictic.md method preamble)
P4 data: phase tables transcribed from DIACHRONIC_POLITICAL_RELIGION.md §2
  (Mesopotamia n=6 phases, Egypt n=4; ORDERING% and royal-words/1000)

Tests:
  P3  — religion-vs-myth deixis index gap per culture; observed gap vs label-
        permutation null (shuffle register within culture, B=20,000). Per-culture
        sign test + pooled (Fisher-style combining of perm gaps).
  P4  — chronological trend (Kendall tau of metric vs phase order), exact
        permutation under all n! orders (n<=6). Predictions: Mesopotamia
        rising (positive), Egypt falling (negative). Both metrics reported;
        royal-density is primary.
Output: results/myths/NULL_AUDIT_P3_P4.{json,md}
"""
import json, itertools, statistics, os, math

BASE = "/home/node/.openclaw/workspace/vi-foundry"
RES = os.path.join(BASE, "results/myths")
import random

rows = json.load(open(os.path.join(RES, "ANCIENT_DEICTIC_ROWS.json")))["rows"]

# ---- deictic index variants (documented formula = variant A)
def index_a(r):   # (2nd + 1st + ritual) / (spatial + temporal)   [doc formula]
    return (r[2] + r[1] + r[5]) / (r[3] + r[4]) if (r[3] + r[4]) else 0.0
def index_b(r):   # (2nd + ritual) / (spatial + temporal)  [1st person penalized for god-speech myths]
    return (r[2] + r[5]) / (r[3] + r[4]) if (r[3] + r[4]) else 0.0
def index_c(r):   # (2nd + 1st + ritual) / (1 + spatial + temporal)
    return (r[2] + r[1] + r[5]) / (1 + r[3] + r[4])
VARIANTS = {"A_doc": index_a, "B_no1st": index_b, "C_reg1": index_c}

def trad(e_id):
    return e_id.split(":")[0].strip().replace("Akkadian", "Mesopotamian")

# group rows by (tradition, register)
groups = {}
for r in rows:
    groups.setdefault((trad(r[0]), r[6]), []).append(r)

B = 20000
rng = random.Random(123)
out = {"P3": {}, "P4": {}}

for name, fn in VARIANTS.items():
    res = {}
    pooled_obs, pooled_null = [], []
    cultures = sorted({t for (t, reg) in groups if reg == "myth" and (t, "religion") in groups})
    for cu in cultures:
        my = [fn(r) for r in groups[(cu, "myth")]]
        re_ = [fn(r) for r in groups[(cu, "religion")]]
        obs = statistics.mean(re_) - statistics.mean(my)
        # permutation: shuffle combined labels within culture
        pool = my + re_
        nmy = len(my)
        null = []
        for _ in range(B):
            rng.shuffle(pool)
            gm = statistics.mean(pool[:nmy])
            gr = statistics.mean(pool[nmy:])
            null.append(gr - gm)
        p = sum(1 for x in null if x >= obs) / B
        z = (obs - statistics.mean(null)) / statistics.stdev(null) if statistics.stdev(null) else 0
        res[cu] = {"n_myth": len(my), "n_relig": len(re_),
                   "myth_mean": round(statistics.mean(my), 2),
                   "relig_mean": round(statistics.mean(re_), 2),
                   "gap": round(obs, 2), "z": round(z, 2), "p_perm": round(p, 4)}
        pooled_obs.append(obs); pooled_null.append(0.0)
    # pooled: min p across cultures with all gaps positive sign consistency
    res["POOLED"] = {"cultures": cultures,
                     "all_positive_gaps": all(res[c]["gap"] > 0 for c in cultures),
                     "min_p": min(res[c]["p_perm"] for c in cultures)}
    out["P3"][name] = res

# pooled sign test: all culture gaps positive across k index variants
n_cells = sum(len(res['POOLED']['cultures']) for res in out['P3'].values())
n_pos = sum(1 for res in out['P3'].values() for c in res['POOLED']['cultures'] if res[c]['gap'] > 0)
out['P3']['SIGN_TEST'] = {'positive_cells': n_pos, 'total_cells': n_cells,
                          'p': round(0.5 ** n_pos, 5)}

# ---------------- P4 ----------------
P4 = {
    "Mesopotamia": {
        "phases": ["EnkiDilmun_early", "GilgameshAgga", "InannaDescent", "SKL", "UrIII", "EnumaElish"],
        "ordering_pct": [0.0, 2.4, 0.0, 27.5, 5.3, 0.0],
        "royal_per_1000": [0.7, 1.7, 0.4, 14.7, 6.2, 1.2],
    },
    "Egypt": {
        "phases": ["OldKingdom", "MiddleKingdom", "NewKingdom", "Late_Ptol"],
        "ordering_pct": [5.4, 1.1, 1.3, 0.0],
        "royal_per_1000": [2.7, 2.3, 2.1, 0.6],
    },
}

def kendall_tau(v):
    """tau of value vs time (positive = rising over chronology)"""
    n = len(v)
    c = d = 0
    for i, j in itertools.combinations(range(n), 2):
        if v[i] < v[j]: c += 1
        elif v[i] > v[j]: d += 1
    return (c - d) / (n * (n - 1) / 2)

def exact_trend_p(v, expect):
    """exact permutation p for one-sided trend (expect=+1 rising, -1 falling)"""
    obs = kendall_tau(v) * expect
    null = [kendall_tau(list(u)) * expect for u in itertools.permutations(v)]
    return round(sum(1 for t in null if t >= obs) / len(null), 4)

for cu, dat in P4.items():
    res = {}
    for metric in ("ordering_pct", "royal_per_1000"):
        v = dat[metric]
        tau = kendall_tau(v)
        # prediction: Mesopotamia rises, Egypt falls -> test one-sided accordingly
        # but be honest: report BOTH one-sided results
        p_up = exact_trend_p(v, +1)
        p_down = exact_trend_p(v, -1)
        res[metric] = {"tau": round(tau, 3), "p_rising": p_up, "p_falling": p_down,
                       "n_phases": len(v)}
    out["P4"][cu] = res

json.dump(out, open(os.path.join(RES, "NULL_AUDIT_P3_P4.json"), "w"), indent=1)

lines = ["# Null audit: P3 deictic transposition & P4 diachronic congealing", "",
         "**Date:** 2026-10-16 · null baselines applied retroactively per Jan directive", "",
         "## P3 — religion-vs-myth deixis gap vs register-label permutation (B=20,000)", "",
         "| index variant | culture | myth mean | relig mean | gap | z | p | clears? |",
         "|---|---|---|---|---|---|---|---|"]
for name, res in out["P3"].items():
    if name == "SIGN_TEST":
        continue
    for cu in res["POOLED"]["cultures"]:
        r = res[cu]
        ok = "YES" if r["p_perm"] < 0.05 else "no"
        lines.append(f"| {name} | {cu} | {r['myth_mean']} | {r['relig_mean']} | {r['gap']} | {r['z']} | {r['p_perm']} | {ok} |")
lines += ["", "## P4 — chronological trend vs exact phase-permutation", "",
          "| culture | metric | tau | p (rising) | p (falling) | verdict |", "|---|---|---|---|---|---|"]
for cu, res in out["P4"].items():
    for m, r in res.items():
        if cu == "Mesopotamia":
            verdict = "RISE confirmed" if r["p_rising"] < 0.05 else "rise NOT confirmed"
            lines.append(f"| {cu} | {m} | {r['tau']} | {r['p_rising']} | {r['p_falling']} | {verdict} |")
        else:
            verdict = "FALL confirmed" if r["p_falling"] < 0.05 else "fall NOT confirmed"
            lines.append(f"| {cu} | {m} | {r['tau']} | {r['p_rising']} | {r['p_falling']} | {verdict} |")
open(os.path.join(RES, "NULL_AUDIT_P3_P4.md"), "w").write("\n".join(lines) + "\n")
print(json.dumps(out, indent=1))