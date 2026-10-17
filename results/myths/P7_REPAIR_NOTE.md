# P7 instrument-repair addendum

**Date:** 2026-10-17 · follows `p7_laurasian_test.py` prereg result (commit `8067e71`)

## Diagnosis (quantified)

1. Chain-length spread ~70x: region mean chain length 4.2 (Amur/Nanai) to 300 (Popol Vuh); literary pipelines (14, 17, 29: 83-210) vs oral/performance (25, 26, 37-39: 4-7).
2. Vocabulary contamination: 55 "event types" in inventory, ~25 are prose fragments (actions leaked into the type field). Canonical-code regex filter applied.
3. Genre/segmentation heterogeneity: same shared vocabulary across clause-level oral coding and literary summaries.

## Repairs applied and results

| Repair | G1 mytheme delta | G2 bigram delta | Content delta |
|---|---|---|---|
| baseline (prereg run) | -0.039 [-0.090, +0.006] | -0.019 [-0.049, +0.007] | +0.040 [+0.010, +0.068] |
| R1 canonical vocab + consecutive-collapse | -0.036 | -0.008 | +0.041 |
| R2 + length-band gate (3x, 44 pairs) | -0.045 | -0.007 | +0.041 |

**None of the repairs move the grammar contrast toward positive.** Grammar deltas stay <=0, CIs straddle 0; content stays significantly positive (Australia content-isolated, rank 13/13).

## Root-cause finding: resolution saturation, not noise

Region-inventory overlap at the coarse event-type level is uniformly high (all-pairs vocab-share Jaccard 0.35-0.73; Australia overlaps every region, including Laurasians, at 0.50-0.67). With ~15-45 coarse codes per region and ~55 total (30 canonical), the mytheme/type vocabulary is a *floor* rather than a signal: between-region grammar similarity saturates everywhere, so no contrast — Laurasian or otherwise — can be detected at this resolution. The instrument measures register/genre coarseness, not lineage structure.

## Repair direction (registered)

Rebuild the grammar layer at predicate resolution: (event_type x agent-role/periphery) pairs as characters, parent-category-normalized mythemes; first validation on like-genre literary subsets (ancient canon + Kojiki + Psalms/RV + Davison Han), then oral subsets internally. Settlement criteria same as P7 prereg shuffle-nulls. Until then, grammar-layer claims remain capped at tier M (see CLAIM_TIERS_V1.md) and no cross-tradition grammar verdicts are issued.