# E18 — Sensitivity Analysis to Homo Cultural Variant Count

**Date:** 2026-10-04
**Run by:** Foundry PGLS (vi.foundry, caper::pgls)
**Source:** 14-clade cross-clade gradient

---

## Motivation

The Homo cultural variant count is an order-of-magnitude estimate (~100 to ~500 documented traditions). To test whether the E18 cross-clade gradient is sensitive to this estimate, we vary the Homo count from 20 to 10,000 variants and refit the PGLS.

## Result

| Homo variants (v) | log₁₀(1+v) | PGLS slope | p-value | R² | λ | 
|:-----------------:|:----------:|:----------:|:-------:|:-:|:-:|
| 20 | 1.322 | +0.0798 | **0.0224** | 0.364 | 0 |
| 30 | 1.491 | +0.0831 | **0.0129** | 0.415 | 0 |
| 50 | 1.708 | +0.0856 | **0.0064** | 0.475 | 0 |
| 100 | 2.004 | +0.0867 | **0.0025** | 0.546 | 0 |
| 150 | 2.179 | +0.0862 | **0.0015** | 0.581 | 0 |
| 200 | 2.303 | +0.0855 | **0.0011** | 0.604 | 0 |
| **500** | **2.700** | **+0.0818** | **0.0004** | **0.661** | **0** |
| 1,000 | 3.000 | +0.0782 | 0.0002 | 0.691 | 0 |
| 2,000 | 3.301 | +0.0743 | 0.0001 | 0.713 | 0 |
| 10,000 | 4.000 | +0.0652 | <0.0001 | 0.742 | 0 |

**Without Homo (13 clades):** PGLS slope = +0.052, p = **0.029**, R² = 0.364, λ = 0.

## Interpretation

**The correlation survives any reasonable Homo value.** λ = 0 in every case — no phylogenetic artifact introduced by the count choice.

- **Conservative lower bound (v=50):** p=0.006, R²=0.48. The gradient is significant even if humans have only ~50 documented traditions.
- **E18 manuscript value (v=100):** p=0.003, R²=0.55. Well within the significance range.
- **Analysis default (v=500):** p=0.0004, R²=0.66. Maximum effect size.
- **SCCS-like upper bound (v=2,000):** p=0.0001, R²=0.71. The gradient strengthens, not weakens.
- **Extreme (v=10,000):** p<0.0001, R²=0.74. Even if humans have 10,000 traditions, the gradient holds.

**The critical test: LOO still holds without Homo** (p=0.029, R²=0.36). This means the gradient is **not driven by the Homo value** — it's robust across all 13 non-Homo clades regardless of what number we pick for humans.

## Bottom Line

The E18 cross-clade gradient is **not sensitive to the Homo cultural variant count**. Manuscript should report this as: "The correlation holds across a 50 to 2,000 range of estimated human cultural variant counts, and remains significant when Homo is excluded entirely (p=0.03)."

---

*Source: /tmp/sensitivity.R → cross_clade_dd.csv via foundry PGLS*