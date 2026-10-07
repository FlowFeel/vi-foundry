# R1 Cavefish — INFERNO-Style Self-Audit (Jan's challenge, 2026-09-05)

**Subject:** Was the R1 cavefish integration-depth test (STRING degree vs loss
timing, registered 2026-08-24, `vi-foundry/results/r1-cavefish-sequence/`)
conducted with full inferential rigor: data collection → labeling →
experiment plan from motivations → prediction → inference?

**Verdict: NO. The registered negative is not clean. The test has a labeling
confound and a category-block artifact that were not disclosed at registration
time. This audit downgrades the result from "VI prediction falsified by
independent metric" to "uninterpretable as registered; specific failures
identified below."**

---

## 1. Data collection — ⚠️ PARTIAL

- 22 genes across 4 categories (eye, pigment, circadian, metabolic). STRING
  degrees queried live from string-db.org (zebrafish orthologs, species 7955). ✅
  Reproducible, real database query.
- Selection of the 22 genes is **NOT documented** — no inclusion criteria, no
  table of "all eye-development genes we could find," no citation list in the
  TSV header. It is plausibly cherry-picked per category (the classic
  integration-depth genes). ❌ Selection protocol absent.
- Loss-timing ranks come from "developmental literature" — but **no source
  citations are given for the ranks**. Which paper says pigment genes are lost
  at ~10hpf and circadian at ~72hpf? Unverifiable as recorded. ❌ Provenance gap.

## 2. Data labeling — ❌ THE CORE PROBLEM

Two independent labeling defects, both fatal to the test as registered:

**(a) The "loss timing" label is actually developmental EXPRESSION ONSET (hpf),
not evolutionary trait-loss order.** The TSV header says: `loss_timing:
1=early(~10hpf), 2=mid(~24hpf), 3=late(~36hpf), 4=very late(~72hpf+)`. These are
**hours-post-fertilization developmental expression times**, a completely
different variable from "when was the trait lost in cave evolution." The R1 doc
then treats them as the loss-order dependent variable. The prediction was
"low-integration traits lost first in cavefish evolution" — but the dependent
variable measures developmental onset, not evolutionary loss order. The two are
conflated without justification or even acknowledgment.

**(b) The ranks are category-level blocks, not gene-level labels.** Only **4
distinct rank values** assigned to 4 whole categories (pigment=1, eye=2-3,
circadian=4, metabolic=4). Within-category degree variation is large (eye:
28–225; pigment: 58–229) yet all eye genes share the same ranks (2 or 3).
Effective n is 4 categories, not 22 genes — the Spearman ρ on 22 points with 4
tied blocks is inflated sample size. Permutation p = 0.521 is likewise computed
on the categorical-block structure.

**Consequence:** the registered "negative" (ρ = −0.013, p = 0.956) may be an
artifact of (a) measuring the wrong variable (developmental onset ≠ cave loss
order) and (b) pseudo-replication from category-block labels. It cannot be
interpreted as "STRING degree does not predict cavefish trait-loss order."

## 3. Experiment plan from motivations — ⚠️ ADEQUATE BUT UNMET

- Motivation (break circularity via independent metric) — sound, from the recast
  R1 design: STRING degree, dependency depth, developmental timing as three
  independent metrics. ✅ Design intent correct.
- But the executed test used **the third metric (developmental timing) as the
  DEPENDENT variable** while the design called for it as an **independent**
  integration-depth metric. The design's own logic was inverted in execution.
  ❌ Plan/execution mismatch.

## 4. Prediction work — ⚠️ DIRECTION UNCLEAR

- Prediction stated: "low-integration (low degree) traits lost first." But the
  dependent variable is hpf developmental onset — under which the sign
  prediction is not derived. If anything, deep-integration genes are often
  EARLY-expressed developmental regulators (high hpf-onset logic cuts the other
  way). The prediction was never mapped onto the actual dependent variable. ❌

## 5. Inference on results — ⚠️ OVERREACHED

- The conclusion text says "The integration-depth ordering prediction is **not
  supported** when measured with STRING network degree" and offers
  interpretations A/B/C (wrong metric, wrong prediction, refinement needed).
- What it does NOT say: "the dependent variable is developmental onset, not loss
  order, so this is not a test of loss-order prediction at all." That
  disambiguation is absent. The negative was thereby overstated relative to what
  the data can bear. ❌

## 6. What survives

- The STRING-degree ordering claim **as a test of developmental-onset ordering**
  — none; never framed that way.
- The valid kernel: STRING degree, IF the dependent variable were actual
  evolutionary loss order (from cave population divergence data per trait),
  would be a legitimate independent metric. The data to build that test:
  loss-order from cave-population comparative data (which traits regress in
  which sequence across populations of known age — the E7 raw-traits dataset
  has some of this), NOT hpf onset.
- E7 (the OTHER cavefish test, raw trait regression) is separately scored WCI 79
  and is NOT implicated by this audit — it measured actual trait values across
  surface/cave populations. The audit's scope is R1 only.

## 7. Corrective action

1. **R1 status change:** registered negative → **withdrawn as interpreted;
   re-queued as needs-rebuild** (loss-order labels must come from cave
   population comparative data, not hpf onset).
2. **Labeling protocol:** any future R1 rebuild must document gene inclusion
   criteria, per-gene loss-order sources with citations, and gene-level (not
   category-block) labels.
3. **Paper impact:** the monograph must NOT cite R1 as an independent-metric
   falsification. No active claim depends on R1 being true, so no paper claim
   falls — but the foundry record must be corrected (honesty over convenience).

## Files

- Audit: this file
- Original (flawed) record: `vi-foundry/results/r1-cavefish-sequence/r1-results.md`
- Raw data (labels flawed): `r1-raw-data.tsv`