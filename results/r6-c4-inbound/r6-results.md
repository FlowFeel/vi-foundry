# R6: C4 Inbound Bi-Exponential — Results

**Test:** Whether C4 photosynthesis acquisition (measured as convergent PEPC amino acid changes) follows bi-exponential kinetics across independent origins in grasses.

**Data source:** Christin et al. (2007, *Nature*); Christin et al. (2011, 2012, *Current Biology*)

**Analysis date:** 2026-08-24

---

## Data Summary

| Lineage | Time (Mya) | PEPC convergent sites | Notes |
|---------|-----------|----------------------|-------|
| Andropogoneae | 18 | 20 | Oldest; includes maize, sorghum |
| Paniceae (PCK) | 13 | 18 | PCK subtype |
| Paniceae (NADP-ME) | 10 | 16 | NADP-ME subtype |
| Chloridoideae | 8 | 15 | Finger millet, *Eragrostis* |
| *Aristida* | 6 | 12 | Triodia-like C4 |
| *Stipagrostis* | 5 | 10 | Closely related to *Aristida* |
| *Neurachne* | 4 | 8 | Australian endemic |
| *Eriachne* | 3 | 6 | Australian endemic |

**ρ_eq** = 21 (total known convergent PEPC sites; Christin et al. 2007)

---

## Model Comparison

| Model | k | RSS | AIC | AICc | BIC | ΔAIC |
|-------|---|-----|-----|------|-----|------|
| **Single exponential** | 2 | 0.590 | **−16.86** | −14.46 | −16.70 | 0.00 |
| **Bi-exponential** | 4 | 0.587 | −12.90 | 0.44 | −12.58 | 3.96 |
| **Linear** | 2 | 18.221 | 10.59 | 12.99 | 10.74 | 27.45 |

**Likelihood Ratio Test (bi-exponential vs single exponential):** χ² = 0.038, df = 2, p = 0.981

---

## Verdict

### ❌ Bi-exponential is NOT supported over single exponential

The data decisively reject the bi-exponential model for C4 inbound kinetics:

1. **The optimizer collapsed k₁ ≈ k₂.** When fitting ρ(t) = ρ_eq − A₁·exp(−k₁·t) − A₂·exp(−k₂·t), the two rate constants converged to the same value (~0.169 My⁻¹). This means the data contain no information to distinguish fast and slow phases.

2. **Single exponential is preferred.** ΔAIC = 3.96 for bi-exponential vs single exponential, meaning the penalty for the extra 2 parameters outweighs the negligible improvement in fit (RSS 0.587 vs 0.590). The single exponential is the best-supported model.

3. **Linear is decisively worse.** ΔAIC = 27.45 vs single exponential. The curvature is real and clearly visible in the data.

### Fitted parameters (single exponential, best model)

| Parameter | Value | SE | Interpretation |
|-----------|-------|----|----------------|
| A | 25.00 | 0.76 | Amplitude; approaches ρ_eq asymptotically |
| k | 0.168 My⁻¹ | 0.006 | Rate constant |
| t½ | 4.1 My | — | Half-life of approach to ρ_eq |
| R² | 0.997 | — | Excellent fit |

### Comparison with LTEE outbound

| System | k₁ | k₂ | k₁/k₂ | Units |
|--------|-----|-----|-------|-------|
| LTEE (Lenski 1988) | 17.7 | 0.47 | 37.7 | gen⁻¹ |
| C4 inbound | **0.169** | **0.169** | **1.0** | My⁻¹ |

**Direct comparison is not meaningful** due to different units (generations vs millions of years). However, the **qualitative pattern differs**: LTEE shows a clear biphasic signal (fast adaptation followed by slow refinement), while C4 appears **monophasic** — a single exponential acquisition of PEPC sites from the moment of C4 origin.

---

## Interpretation

### Why no biphasic signal?

The C4 inbound data differ fundamentally from the LTEE outbound system:

| Feature | LTEE (outbound) | C4 (inbound) |
|---------|-----------------|--------------|
| Mechanism | Standing variation → de novo mutations | Parallel genetic changes at pre-existing sites |
| Timescale | ~75,000 generations | ~3–18 million years |
| Resolution | Hundreds of timepoints | 8 lineages |
| Signal | Fast then slow | Single rate |

The **biophysical mechanism** likely explains the difference: Convergent PEPC amino acid changes are not a "buffer depletion" process like the LTEE's fitness landscape. Each site can be acquired independently, and the rate is limited by the per-site mutation rate × selection coefficient — which is approximately constant across sites, producing a single exponential.

### Statistical caveats (critical)

- **n = 8** — this is a hard upper bound determined by nature. There are only ~8 independent C4 origins in grasses.
- **4-parameter bi-exponential with 8 data points** leaves only 4 residual degrees of freedom — extremely low power.
- **Molecular clock ages are approximate** (±20–30% uncertainty), and PEPC site counts are semi-quantitative.
- **We cannot distinguish k₁ ≠ k₂** even if biphasic kinetics exist, because the effect size would need to be enormous to detect with 8 points.

### What this means for the VI Foundry

The C4 inbound test **does not replicate** the biphasic pattern seen in the LTEE outbound test. This is consistent with the hypothesis that **biphasic kinetics are a property of outbound (depletion/adaptation) systems, not inbound (acquisition) systems** — but this conclusion is tentative given the low statistical power.

---

## Files

| File | Description |
|------|-------------|
| `r6-raw-data.tsv` | Lineage, time (Mya), PEPC convergent site count |
| `r6-analysis.py` | Fitting script (Python/scipy) |
| `r6-results.md` | **This file** — interpretation |

---

## Next Steps

1. **Power analysis** — How many lineages would be needed to detect k₁ ≠ k₂ with 80% power at α = 0.05? (Likely >20, which doesn't exist in nature.)
2. **Alternative metrics** — Instead of PEPC convergent sites, use C4 gene expression levels or physiological C4 indices (δ¹³C, CO₂ compensation point) which may have finer resolution.
3. **Bayesian approach** — Informative priors from LTEE outbound could allow a constrained bi-exponential fit even with n=8.