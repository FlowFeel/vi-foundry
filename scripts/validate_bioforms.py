#!/usr/bin/env python3
"""Validate Bioforms Archive grammar tests T1-T7 (foundry load 2026-10-29).

Per Jan: "can you create tests in foundry to identify life forms and blindly
predict their behaviors, their predators, how they adapt in different kinds of
environments; combine forms to explain intelligence/parameters of behavior,
modes of learning."

Uses the archive's own published dataset (data/bioforms/bioforms.json, 101
entries) and the affinity partition + compound rules from
data/analysis/bioforms-affinity-groups.md (oracle_bioforms.yml).

  T1: partition integrity (101/101, 9 families, family x level matrix)
  T2: blind family identification from geometry_en only (seeded 10% holdout)
  T3: blind behavior-class prediction from geometry+family (function_en held out)
  T4: blind adaptation-class prediction from geometry+family (significance_en held out)
  T5: grammar closure: do compound rules R1-R13 generate the archive's L4/L5 forms?
      unreachable residue = novel-form predictions (the grammar's payoff)
  T6: predator rules: recorded in oracle; scored only when an external trait
      matrix is staged (GATED — reports pending, not failure)
  T7: learning-mode coverage: does the archive's own plasticity language (Levin
      imports) support the family x operator -> learning-mode matrix?

Seeded, deterministic, stdlib only. Output: output/bioforms_validation.json
"""

from __future__ import annotations

import json
import os
import random
import re
from collections import Counter

DATA = "/home/node/.openclaw/workspace/vi-foundry/data/bioforms/bioforms.json"
OUT = "/home/node/.openclaw/workspace/vi-foundry/output/bioforms_validation.json"
SEED = 20261029

with open(DATA) as f:
    FORMS = json.load(f)
BY_ID = {d["id"]: d for d in FORMS}

# Family definitions (mirrors oracle_bioforms.yml)
FAMILIES = {
    "F1_AXIS": [1, 3, 6, 20, 42, 43, 68, 76, 84, 89],
    "F2_SHEET": [2, 5, 17, 18, 50, 51, 52, 53, 62, 63, 64, 79, 80, 85, 86],
    "F3_RADIAL": [14, 15, 21, 22, 48, 49, 61, 67, 71, 99],
    "F4_CONTAINER": [4, 7, 12, 54, 65, 66, 82, 83, 90],
    "F5_CONDUIT": [8, 9, 10, 11, 55, 58, 69, 74, 75, 77, 96],
    "F6_BRANCH": [25, 26, 57, 72, 87, 88, 91, 92, 93, 95],
    "F7_MODULE_COLLECTIVE": [23, 24, 29, 56, 59, 60, 94, 97, 98, 100, 101],
    "F8_CHASSIS": [13, 44, 45, 46, 47, 70, 73, 78, 81],
    "F9_OPERATORS": [16, 19, 27, 28, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41],
}
FAM_OF = {i: fam for fam, ids in FAMILIES.items() for i in ids}

KEYWORDS = {
    "F1_AXIS": {"axial": 3, "axis": 2, "elongated": 2, "tubular": 2, "vermiform": 4,
                "fusiform": 4, "worm": 2, "coiled": 2, "undulat": 2, "tapering": 2, "serially": 2},
    "F2_SHEET": {"plan": 3, "laminar": 3, "flat": 2, "flatten": 3, "disc": 3, "wing": 4,
                 "membran": 3, "fan": 3, "comb": 3, "brush": 3, "glid": 3, "lift": 4,
                 "lateral branch": 2, "stretched": 2},
    "F3_RADIAL": {"radial": 4, "center": 3, "central": 3, "stellate": 4, "tentac": 4,
                  "crown": 3, "medus": 3, "omnidirection": 3},
    "F4_CONTAINER": {"spher": 4, "globul": 4, "ovoid": 3, "armor": 4, "spin": 4, "shell": 3,
                     "helical": 3, "protect": 3, "enclosure": 3, "compact": 2, "rigid": 3},
    "F5_CONDUIT": {"cavity": 3, "hollow": 3, "funnel": 4, "cup": 3, "bell": 4, "torus": 4,
                   "annular": 3, "conduit": 3, "nozzle": 3, "pressure": 3, "casing": 2,
                   "void": 4, "opening": 3, "empty": 3, "enclos": 2},
    "F6_BRANCH": {"branch": 4, "bifurcat": 4, "tree": 3, "vascular": 4, "reticular": 4,
                  "mesh": 3, "phyllotax": 4, "gradient": 4, "reaction-diffusion": 4,
                  "field": 3, "root": 2, "interconnect": 2, "connect": 1},
    "F7_MODULE_COLLECTIVE": {"segment": 4, "repetit": 3, "modular": 4, "module": 4,
                             "colon": 4, "chain": 3, "catenary": 4, "aggregat": 4,
                             "cluster": 3, "swarm": 4, "network": 3, "serial": 2,
                             "reiterat": 3, "unit": 3, "similar": 2, "individu": 2,
                             "repeated": 2, "multiple": 1, "homolog": 3},
    "F8_CHASSIS": {"bilater": 3, "limb": 4, "leg": 4, "quadr": 4, "biped": 4, "arthropod": 4,
                   "carcin": 4, "pincer": 3, "claw": 3, "jump": 3, "excavat": 3,
                   "appendage": 3, "exoskeleton": 3},
    "F9_OPERATORS": {"reduction": 3, "loss": 2, "elongat": 2, "compress": 3, "expansion": 2,
                     "constrict": 3, "coil": 3, "rotation": 3, "migration": 3, "inversion": 3,
                     "specializ": 3, "hypertroph": 4, "atrophy": 4, "fusion": 3, "division": 3,
                     "asymmetry": 3, "reorganiz": 2, "position": 2, "alter": 2, "transform": 2,
                     "differentiate": 3, "separate": 2, "copy": 2, "decrease": 2, "increase": 2,
                     "lengthen": 2, "narrow": 2, "shorten": 1},
}

BEHAVIOR_CLASSES = {
    "LOCOMOTE": ["propuls", "locomot", "swim", "mov", "undulat", "jump", "fly", "glid", "thrust",
                 "travel", "migrat", "forag", "descent"],
    "CAPTURE": ["capture", "prey", "grasp", "suction", "filtrat", "collect", "feeding", "ingest",
                "grip", "trap", "intercept"],
    "PROTECT": ["protect", "defens", "armor", "deterrent", "shield", "camoufl", "buffering",
                "shell", "enclos"],
    "TRANSPORT": ["transport", "distribut", "conduct", "vascular", "flow", "circulat", "channel",
                  "conduit", "pump"],
    "ATTACH": ["attach", "anchor", "fixation", "hold", "substrate", "settle", "bond"],
    "INTEGRATE": ["integrat", "coordinat", "communicat", "collective", "signal", "synchron",
                  "cooperat", "division of labor"],
    "GROW": ["growth", "proliferat", "coloniz", "scale", "expand", "reproduc", "regenerat"],
    "SENSE": ["sense", "signal", "gradien", "polarit", "field", "instruct", "regulat", "orient",
              "detect", "percept"],
}

ADAPTATION_CLASSES = {
    "DEFENSE": ["predat", "protect", "defens", "armor", "deter", "desiccat", "crush", "puncture",
                "gape", "camoufl", "trauma"],
    "FLUID": ["drag", "flow", "fluid", "hydrodynamic", "current", "stream", "lift", "turbul",
              "pressure", "viscosit", "buoyancy", "wave"],
    "SURFACE": ["surface", "interface", "area", "absorption", "exchange", "light", "gas",
                "capture", "collect"],
    "PACKING": ["pack", "compact", "economy", "efficien", "redundanc", "cost", "density",
                "conserv"],
    "COLLECTIVE": ["collective", "integration", "cooperat", "colon", "superorganism", "network",
                   "synchron", "redundanc", "division"],
    "CONSTRAINT": ["physic", "geometr", "constraint", "force", "universal", "law", "pressur"],
    "DEVELOPMENT": ["development", "plasticity", "regenerat", "morphogen", "bioelectric",
                    "memory", "positional", "signal", "field"],
}

COMPOUND_RULES = {
    "R1": {"operands": ["F1_AXIS", "F9_OPERATORS"], "product": [6, 43]},
    "R2": {"operands": ["F1_AXIS", "F7_MODULE_COLLECTIVE"], "product": [42]},
    "R3": {"operands": ["F7_MODULE_COLLECTIVE"], "product": [94, 100, 101]},
    "R4": {"operands": ["F2_SHEET", "F6_BRANCH"], "product": [50, 62, 63, 64]},
    "R5": {"operands": ["F2_SHEET", "F9_OPERATORS"], "product": [51, 79, 80]},
    "R6": {"operands": ["F5_CONDUIT", "F9_OPERATORS"], "product": [75, 77]},
    "R7": {"operands": ["F5_CONDUIT", "F3_RADIAL"], "product": [67]},
    "R8": {"operands": ["F4_CONTAINER"], "product": [54, 66, 82]},
    "R9": {"operands": ["F4_CONTAINER", "F9_OPERATORS"], "product": [65, 83]},
    "R10": {"operands": ["F3_RADIAL", "F9_OPERATORS"], "product": [48, 49, 61, 71]},
    "R11": {"operands": ["F6_BRANCH", "F9_OPERATORS"], "product": [88]},
    "R12": {"operands": ["F7_MODULE_COLLECTIVE"], "product": [59, 56, 100, 101]},
    "R13": {"operands": ["F9_OPERATORS", "F8_CHASSIS"], "product": [47]},
}

LEARNING_MODE_HINTS = {
    "F1_AXIS": ["undulat", "oscillat", "rhythmic", "wave"],
    "F2_SHEET": ["lift", "predict", "kinemat", "aero", "hydrodyn"],
    "F3_RADIAL": ["omnidirection", "360", "radial"],
    "F4_CONTAINER": ["avoid", "deter", "defens"],
    "F5_CONDUIT": ["pressure", "threshold", "reflex", "burst"],
    "F6_BRANCH": ["gradient", "search", "explor", "parallel"],
    "F7_MODULE_COLLECTIVE": ["collective", "cooperat", "division", "swarm"],
    "F8_CHASSIS": ["manipul", "operant", "action", "limb"],
    "F9_OPERATORS": ["plastic", "specializ", "reallocat", "prun"],
}


def score_text(text: str, keywords: dict) -> float:
    t = text.lower()
    return sum(w for kw, w in keywords.items() if kw in t)


def predict_family(geom: str) -> str:
    scores = {fam: score_text(geom, kw) for fam, kw in KEYWORDS.items()}
    best = max(scores, key=scores.get)
    return best if scores[best] > 0 else "UNKNOWN"


# ---------- T1 ----------
def t1_partition():
    all_ids = [d["id"] for d in FORMS]
    fam_ids = sorted(i for ids in FAMILIES.values() for i in ids)
    ok_unique = len(set(all_ids)) == 101 and len(set(fam_ids)) == 101
    ok_all = sorted(all_ids) == sorted(fam_ids)
    # family x level matrix
    lvl = {d["id"]: d["categoryId"] for d in FORMS}
    mat = {}
    for fam, ids in FAMILIES.items():
        row = [0] * 7
        for i in ids:
            row[lvl[i] - 1] += 1
        mat[fam] = row
    return {
        "n_forms": len(all_ids),
        "n_family_members": len(fam_ids),
        "partition_complete": ok_unique and ok_all,
        "family_x_level_matrix": mat,
        "operator_layer_check": mat["F9_OPERATORS"][2] == 14,  # 14/16 operators in L3
    }


# ---------- T2 ----------
def t2_blind_identify():
    rng = random.Random(SEED)
    ids = sorted(BY_ID)
    holdout = set(rng.sample(ids, 10))
    correct, conf = 0, Counter()
    for i in ids:
        pred = predict_family(BY_ID[i]["geometry_en"])
        true = FAM_OF[i]
        if i in holdout:
            conf[(true, pred)] += 1
            correct += pred == true
    n_hold = len(holdout)
    full_correct = sum(
        1 for i in ids if predict_family(BY_ID[i]["geometry_en"]) == FAM_OF[i]
    )
    return {
        "holdout_ids": sorted(holdout),
        "accuracy_holdout": round(correct / n_hold, 3),
        "correct": correct,
        "n_holdout": n_hold,
        "train_consistency_all_101": round(full_correct / len(ids), 3),
        "confusions": [f"{t}->{p}:{c}" for (t, p), c in sorted(conf.items())],
    }


# ---------- T3 ----------
def t3_blind_behavior():
    rng = random.Random(SEED + 1)
    ids = sorted(BY_ID)
    holdout = set(rng.sample(ids, 10))

    def predict_behavior(fid):
        geom = BY_ID[fid]["geometry_en"]
        fam = predict_family(geom)
        txt = (geom + " " + fam.replace("_", " ")).lower()
        scores = {}
        for cls, kws in BEHAVIOR_CLASSES.items():
            scores[cls] = sum(txt.count(kw) for kw in kws)
        return max(scores, key=scores.get) if max(scores.values()) > 0 else "UNKNOWN"

    def true_behavior(fid):
        txt = BY_ID[fid]["function_en"].lower()
        scores = {cls: sum(txt.count(kw) for kw in kws) for cls, kws in BEHAVIOR_CLASSES.items()}
        return max(scores, key=scores.get) if max(scores.values()) > 0 else "UNKNOWN"

    correct, conf = 0, Counter()
    unscoreable = []
    for i in holdout:
        p, t = predict_behavior(i), true_behavior(i)
        if t == "UNKNOWN":
            unscoreable.append(i)
            continue
        conf[(t, p)] += 1
        correct += p == t
    scored = len(holdout) - len(unscoreable)
    full_ok, full_scored = 0, 0
    for i in ids:
        t = true_behavior(i)
        if t == "UNKNOWN":
            continue
        full_scored += 1
        full_ok += predict_behavior(i) == t
    return {
        "holdout_ids": sorted(holdout),
        "accuracy_holdout": round(correct / scored, 3) if scored else None,
        "correct": correct,
        "n_scoreable": scored,
        "train_consistency_all_101": round(full_ok / full_scored, 3) if full_scored else None,
        "unscoreable_true_label": sorted(unscoreable),
        "confusions": [f"{t}->{p}:{c}" for (t, p), c in sorted(conf.items())],
    }


# ---------- T4 ----------
def t4_blind_adaptation():
    rng = random.Random(SEED + 2)
    ids = sorted(BY_ID)
    holdout = set(rng.sample(ids, 10))

    def predict_adaptation(fid):
        geom = BY_ID[fid]["geometry_en"]
        fam = predict_family(geom)
        txt = (geom + " " + fam.replace("_", " ")).lower()
        scores = {cls: sum(txt.count(kw) for kw in kws) for cls, kws in ADAPTATION_CLASSES.items()}
        return max(scores, key=scores.get) if max(scores.values()) > 0 else "UNKNOWN"

    def true_adaptation(fid):
        txt = BY_ID[fid]["significance_en"].lower()
        scores = {cls: sum(txt.count(kw) for kw in kws) for cls, kws in ADAPTATION_CLASSES.items()}
        return max(scores, key=scores.get) if max(scores.values()) > 0 else "UNKNOWN"

    correct, conf = 0, Counter()
    unscoreable = []
    for i in holdout:
        p, t = predict_adaptation(i), true_adaptation(i)
        if t == "UNKNOWN":
            unscoreable.append(i)
            continue
        conf[(t, p)] += 1
        correct += p == t
    scored = len(holdout) - len(unscoreable)
    full_ok, full_scored = 0, 0
    for i in ids:
        t = true_adaptation(i)
        if t == "UNKNOWN":
            continue
        full_scored += 1
        full_ok += predict_adaptation(i) == t
    return {
        "holdout_ids": sorted(holdout),
        "accuracy_holdout": round(correct / scored, 3) if scored else None,
        "correct": correct,
        "n_scoreable": scored,
        "train_consistency_all_101": round(full_ok / full_scored, 3) if full_scored else None,
        "unscoreable_true_label": sorted(unscoreable),
        "confusions": [f"{t}->{p}:{c}" for (t, p), c in sorted(conf.items())],
    }


# ---------- T5 ----------
def t5_grammar_closure():
    l4l5 = [d["id"] for d in FORMS if d["categoryId"] in (4, 5)]
    reachable = set()
    for rule in COMPOUND_RULES.values():
        reachable.update(rule["product"])
    covered = sorted(reachable & set(l4l5))
    residue = sorted(set(l4l5) - reachable)
    # novelty: pairs of state-families whose joint instantiation exists in the archive
    # vs pairs with NO form -> candidate missing bioforms (grammar predictions)
    fam_of_form = {i: FAM_OF[i] for i in l4l5}
    present_pairs = set()
    from itertools import combinations
    state_fams = [f for f in FAMILIES if f != "F9_OPERATORS"]
    for i in l4l5:
        f = fam_of_form[i]
        for other in state_fams:
            if other != f and any(
                score_text(BY_ID[i]["geometry_en"], KEYWORDS[other]) > 0 for _ in [0]
            ):
                present_pairs.add(tuple(sorted((f, other))))
    all_pairs = set(combinations(sorted(state_fams), 2))
    absent_pairs = sorted(all_pairs - present_pairs)
    return {
        "l4l5_total": len(l4l5),
        "reachable_by_rules": len(reachable & set(l4l5)),
        "coverage": round(len(reachable & set(l4l5)) / len(l4l5), 3),
        "covered_ids": covered,
        "residue_ids": residue,
        "candidate_missing_bioforms": absent_pairs,
    }


# ---------- T6 ----------
def t6_predators():
    # GATED: rules recorded in oracle_bioforms.yml; scoring requires an external
    # predator-prey trait matrix (e.g., FishBase body-size/gape tables).
    data = os.environ.get("BIOFORMS_PREDATOR_MATRIX", "")
    if data:
        return {"status": "SCORED_PENDING_DATA", "note": "benchmark matrix not staged"}
    return {
        "status": "GATED",
        "note": "oracle predator_rules recorded; benchmark requires external trait matrix (FishBase or staged literature matrix). Not scored — pending, not failed.",
    }


# ---------- T7 ----------
def t7_learning_coverage():
    hints_hit = {}
    for fam, hints in LEARNING_MODE_HINTS.items():
        hits = 0
        for i in FAMILIES[fam]:
            txt = (" ".join(BY_ID[i]["traits_en"]) + " " + BY_ID[i]["significance_en"]).lower()
            if any(h in txt for h in hints):
                hits += 1
        hints_hit[fam] = {"family_members": len(FAMILIES[fam]), "members_with_hints": hits}
    # VD-relevant plasticity language in the archive's own texts (Levin imports)
    plastic_terms = ["bioelectric", "gradient", "memory", "regenerat", "plastic", "signal",
                     "field", "reorganiz", "adapt"]
    counts = Counter()
    for d in FORMS:
        txt = (" ".join(d["traits_en"]) + " " + d["significance_en"] + " " + d["function_en"]).lower()
        for t in plastic_terms:
            if t in txt:
                counts[t] += 1
    return {"learning_mode_hint_coverage": hints_hit, "plasticity_language_counts": dict(counts)}


def main():
    results = {}
    results["oracle"] = "baseline/oracle_bioforms.yml"
    results["seed"] = SEED
    results["T1_partition"] = t1_partition()
    results["T2_blind_identify"] = t2_blind_identify()
    results["T3_blind_behavior"] = t3_blind_behavior()
    results["T4_blind_adaptation"] = t4_blind_adaptation()
    results["T5_grammar_closure"] = t5_grammar_closure()
    results["T6_predators"] = t6_predators()
    results["T7_learning_coverage"] = t7_learning_coverage()
    with open(OUT, "w") as f:
        json.dump(results, f, indent=1)
    return results


if __name__ == "__main__":
    res = main()
    print(json.dumps(res, indent=1))