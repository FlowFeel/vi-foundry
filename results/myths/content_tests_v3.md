# Content-Layer Tests v3 (corrected Berezkin matrix)

**Date:** 2026-10-16 · **Data:** motifs_v3.json — 2319 motifs with areal presence, 62 regions, strict non-crossref occurrences
**Supersedes:** §1 of SPLIT_LAYER_TESTS_AND_PREDICTIONS.md (which ran on v1: 3,188 motifs, noisy region keys)

| Test | v3 result |
|---|---|
| T1 Old within / New within / cross (Jaccard) | 0.194 (29 reg) / 0.171 (33 reg) / 0.1029 |
| T1 hemisphere signal | **1.77×** (100.0% of cross-world pairs share ≥1 motif) |
| T2 PCA PC1/PC2 explained | 19.299999237060547% / 5.699999809265137%; PC1↔hemisphere r = 0.717 (OW 4.823, NW -4.238) |
| T3 distance vs similarity (n=1891) | Spearman ρ = -0.46 (p 1.7×10⁻99); Pearson vs log-dist -0.569 |
| T4 language family same/cross | 0.2691 vs 0.132 → **2.04×** (n 131/1760) |
| T5 same-family residual after distance control | Δ = 0.0434 vs -0.0032 (Δ 0.0466), perm p = 0.0005 (2000 perms) |

**Notes**
- Coordinates are first-order region centroids (documented in `content_layer_tests_v3.py`); ±500 km error is noise at hemisphere scale.
- Language-family map is approximate dominant-family sets (also in script); T5's distance-controlled effect is the honest language test.
- Jaccard on strict (non-crossref) motif×region presence.
