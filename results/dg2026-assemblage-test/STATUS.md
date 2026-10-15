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
## Update 2026-10-15: raw WTC vessel-type data received

Added `data/diachenko-gronenborn-2026/WTC_vessel_types_raw.csv` (from the
authors' supplementary, Ryzhov typology A–M, time units 1, 4–10).

### Reconciliation vs S1 Fig 10 "Diversity of forms"

| Unit | Year | D(raw table) | colsum | S1 D | match |
|---|---|---|---|---|---|
| 1 | 4050 | 4.549 | 1.053 | 4.053 | ≠ |
| 4 | 3900 | 6.986 | 0.979 | 7.319 | ~ |
| 5 | 3850 | 6.231 | 0.976 | 6.814 | ≠ |
| 6 | 3800 | 7.753 | 0.977 | 8.239 | ≠ |
| 7 | 3750 | 5.924 | 1.000 | 5.924 | **EXACT** |
| 8 | 3700 | 5.207 | 0.995 | 5.321 | ~ |
| 9 | 3650 | 5.489 | 1.000 | 5.489 | **EXACT** |
| 10 | 3600 | 4.053 | 1.000 | 4.053 | **EXACT** |

- EXACT wherever table sums to 1.0 (complete type inventory).
- Non-matching units have colsum ≠ 1 → unlisted residual types in the raw
  table (aggregation difference vs the diversity-of-forms source [10]).
- S1's `-` cells at 4000/3950 BCE = file's "statistically weak" units 2–3,
  excluded per data note. Consistent.
- **Data hygiene:** duplicate row label `G` (two rows, different values) —
  likely `J` per Ryzhov's A–M typology. Fails to affect diversity (labels
  only) but should be flagged to authors.
- Raw vessel-type richness (8–11 types/unit) does NOT match S1 "Number of
  decoration classes" (6→1) — different typology axis (decoration classes,
  from [112–115]); expected, not an error.
- Standardization test on raw-computed forms diversity vs population:
  rho = +0.524, p = 0.184 (n=8) — the standardization signal lives in
  **decoration-class richness**, not vessel-form diversity. Consistent with
  the paper's framing (C4 uses decoration classes).
