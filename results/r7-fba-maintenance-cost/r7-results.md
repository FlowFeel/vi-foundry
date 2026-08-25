# R7: FBA Maintenance-Cost Test — LTEE

**Date:** 2026-08-25
**Status:** Complete
**Question:** Does true metabolic maintenance cost (protein biosynthesis cost, FBA essentiality) predict the order of gene loss in LTEE?
**Context:** Follows the seriation finding (R1-extension) that metabolic cost predicted cavefish loss ordering (ρ=−0.97). This test asks whether the same holds with real molecular measurements in the LTEE system.

---

## Data & Method

- **Lost genes:** 62 genes with loss-timing (first_gen) from `t7_merged_analysis.tsv`
- **Protein lengths:** Parsed from the actual REL606 genome GenBank file (`REL606.6.gbk`, 4266 CDS) — the true LTEE ancestor genome
- **Biosynthetic cost proxy:** Protein length (aa) × ~5 ATP/aa synthesis cost
- **FBA essentiality:** From earlier FBA knockout analysis — `fba_dep_full` (rich medium model) and `fba_dep_ltee` (LTEE glucose-limited environment model)
- **Metabolic integration:** `met_degree` from STRING + metabolic network centrality

## Results

### 1. Protein length (true biosynthetic cost) does NOT predict loss timing

| Metric | ρ | p | n |
|--------|------|------|-----|
| protein length (aa) | +0.150 | 0.243 | 62 |
| CDS length (bp) | +0.150 | 0.243 | 62 |
| AA synthesis cost (~5ATP/aa) | +0.150 | 0.243 | 62 |

**Prediction FALSIFIED.** If the metabolic-cost hypothesis were right, longer proteins (more expensive to maintain) should be shed first (negative ρ). Instead: no relationship. High-cost and low-cost genes are shed at the same median generation (6500 vs 7500, Mann-Whitney p=0.97).

### 2. FBA essentiality — THE SUBSTRATE CORRECTION (key finding)

| Environment model | ρ vs loss timing | p |
|-------------------|------------------|------|
| fba_dep_full (rich medium) | −0.254 | 0.047 |
| fba_dep_ltee (LTEE glucose-limited) | −0.055 | 0.670 |

**This is the methodological payoff.** The full-medium FBA model shows a *significant* correlation (ρ=−0.25, p=0.047) — high-dependency genes shed earlier. This looks like a real effect. But it's an artifact of the **wrong substrate**: the rich-medium model doesn't describe the LTEE flask. When you use the actual LTEE environment model (glucose-limited minimal medium — the real niche), the effect vanishes (ρ=−0.06, p=0.67).

**This confirms Ed Phil's bounding-conditions point empirically.** The FBA "essentiality" of a gene is not a property of the gene — it's a property of the gene × environment model. Change the medium (the niche), and essentiality changes. The "significant" correlation from the wrong medium was noise dressed as signal.

### 3. Genes shed that are "essential" in the actual niche

- 36 of 62 shed genes have fba_dep_ltee > 0 (FBA says they contribute to biomass in LTEE env)
- Only 7 have >5% biomass impact (truly essential)
- Shed timing: essential 7000 vs non-essential 5500, Mann-Whitney p=0.81 (no difference)

Even in the correct environment model, FBA essentiality does not separate early-shed from late-shed genes.

## Interpretation

**The metabolic-cost hypothesis as stated is NOT supported in LTEE.** Cavefish showed ρ=−0.97 for a *category-level* cost proxy (pigment expensive, circadian cheap). But at the *molecular* level in LTEE, protein length and FBA essentiality do not predict loss order.

Three possibilities:

1. **The cavefish result is category-level, not cost-level.** Pigment vs circadian differ in *function* (and many correlated things — expression, pathway position, selection pressure), not just cost. The ρ=−0.97 may reflect functional category, not metabolic cost per se.

2. **Gene loss in LTEE is not primarily cost-driven.** LTEE is an extreme environment (glucose-limited, 60k+ generations). Genes are lost for many reasons — mutation accumulation, drift, loss-of-function by chance — not just maintenance cost. The niche pressure is weak (no predators, rich enough to survive), so cost-driven shedding may not dominate.

3. **The true cost variable is not protein length.** Maintenance cost in vivo includes expression level (mRNA/protein abundance), turnover rate, and regulatory load — not just length. A short, highly-expressed protein can cost more than a long, silent one. We don't have expression data here.

## What This Means for the Program

1. **The metabolic-cost hypothesis is downgraded from "confirmed" to "category-level, system-dependent."** It holds in cavefish at category granularity. It does not hold in LTEE at molecular granularity. The clean metabolic-accounting model needs more support before it becomes the leading reading.

2. **The substrate correction is the real win.** This test demonstrates — quantitatively, with a control (correct vs wrong environment model) — that the FBA result flips entirely based on how you model the niche. This is the strongest empirical demonstration yet of the bounding-conditions principle. Any future FBA-based claim must specify and justify the environment model.

3. **The magnet-jello discipline is validated.** We studied the metabolic jello and found it doesn't cleanly transmit the drive in LTEE — either the drive isn't primarily metabolic there, or we don't have the right metabolic measure (expression data needed).

## Files

- Script: `scripts/fba_cost_test.py` (working)
- Data: `data/t7-ltee/` (REL606.6.gbk, string_centrality.tsv, t7_merged_analysis.tsv)
- This report: `results/r7-fba-maintenance-cost/r7-results.md`
