# DG2026 — Diachenko & Gronenborn 2026 Foundry Test

**Status:** ✅ ALL GATES PASS (assemblage tests) — 2026-10-13

**Source:** Diachenko A, Gronenborn D (2026) Social dynamics signals in
archaeological time-series. PLoS One 21(10): e0358135.
doi:10.1371/journal.pone.0358135

## Test inventory

| Gate | Result | Notes |
|---|---|---|
| unit (assemblage) | ✅ PASS | 13/13 — Eq 2/6/7 vs S1 exact; Eq 4 Fig 4 worked example exact |
| simulacra (assemblage) | ✅ PASS | k-recovery for k=1.1 and k=0.7 within 0.05; null control flat |
| regression (oracle) | ✅ PASS | 6 new oracle entries pass at tol 0.001 |
| integration | ⚠️ PRE-EXISTING FAIL | p8a/p8b/myth_* exports not in NAMESPACE — unrelated to dg2026 (verified: absent before this branch) |

## Empirical findings (permutation tests, n_perm = 99 999)

### LBK lead-lag (S1 Fig 7)
- **best_lag = 2** time steps (diversity leads population), ρ = 0.762, **p = 0.0369** (two-sided)
- Paper claim C3 (diversity peaks before population: 5150 vs 5065 BCE) **confirmed at α=0.05**
- Note: figure shows peak lead of 1 step visually; formal test finds best lead at 2 steps

### WTC standardization (S1 Fig 10)
- **ρ = −0.651** (decoration-class richness vs population proxy), **p = 0.0471** (two-sided)
- Paper claim C4 (standardization under production increase: 6→1 classes) **confirmed at α=0.05**
- 2 missing forms-diversity cells (4000, 3950 BCE) excluded from forms analysis; richness column complete

## Equation verification (vs S1 Table)

| Eq | Check | Value | S1 | Match |
|---|---|---|---|---|
| Eq 6 | r_stab (k=1.1, p=0.25) | 1.423529 | 1.423529 | EXACT |
| Eq 7 | p_max (k=1.1, r_stab=4) | 0.7975 | 0.7975 | EXACT |
| Eq 2 | D (0.1,0.8,0.05,0.05) | 2.030631 | 2.030631 | EXACT |
| Eq 4 | Fig 4 A→0.714 | 0.714050 | 0.714050 | EXACT |

## Files

- `R/assemblage_diversity.R` — Eqs 2/4/6/7 + simulators + empirical tests
- `tests/testthat/test-unit-assemblage-diversity.R` — 13 unit tests
- `tests/testthat/test-simulacrum-assemblage.R` — 5 simulacrum tests
- `tests/testthat/test-empirical-assemblage.R` — 6 empirical tests
- `data/diachenko-gronenborn-2026/` — S1 Table CSVs (9 figures) + original xlsx
- `baseline/oracle.yml` — 6 new dg2026 oracle entries
- `results/dg2026-assemblage-test/results.json` — empirical results

## Interpretation

Both headline empirical claims of the paper survive formal permutation testing
on the published S1 data. This upgrades the paper's *visual* model-data
alignment (flagged as the WCI weakness in notes/010) to a *quantified* result
for the two empirical series. What remains untested: full model fitting
(parameter estimation on the raw series) and the primaries [4,25,10,38,112–115],
which the foundry does not bundle.