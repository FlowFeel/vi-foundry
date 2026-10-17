# P9 blind-deployment kill-test — VERDICT: PIPELINE ARTIFACT (grammar fingerprint refuted as text signal)

**Date:** 2026-10-17 · Design registered ex-ante in `P9_GRAMMAR_FINGERPRINT_PREREG.md` (commit b76998c), both rival predictions registered before the test.

## Design
Place independent-coder codings (blind coders B and C, v3 protocol, 6 staged texts × 2 coders = 12 codings; traditions: Egyptian×2, Hebrew Psalm 1, Koryak, Australian, Amis) against nearest-centroid classifiers trained on pipeline-v1 grammar profiles of the SAME five traditions (self-match tales excluded from training: Horus & Seth, Two Brothers, Psalm 1, Meamei, Amis 1).

Registered predictions:
- Placement above permuted null → grammar fingerprint is text-real (horizon-real).
- Chance-level → the within-pipeline accuracies (0.57–0.64) are pipeline fingerprint.

## Result: chance or below, under three metrics

| metric | accuracy | perm-p |
|---|---|---|
| cosine on frequency profiles | 1/12 (0.083) | 0.60 |
| set-based Jaccard | 1/12 (0.083) | 0.85 |
| coverage of centroid inventory | 2/12 (0.167) | 0.54 |

Systematic failure mode: codings collapse toward the flattest centroid (Amis), not toward their own tradition. Chain-length disparity is extreme (pipeline mean 39.4 predicates vs blind 14.7) — the v3 clause-level segmentation regime produces sparser profiles — but the set-based metrics, which are robust to granularity, are equally null.

## Verdict and consequences

1. **The grammar-fingerprint result (ANE 0.58, Koryak/Amur 0.64, Formosa 0.14; LOTO family-bond enrichment 1.77×) is REFUTED as a text-level signal.** It is a property of the pipeline-v1 coding process (per-tradition coding habits), not of the myths. All cross-tradition grammar-layer accuracies from the across-datasets battery are void as claims about traditions; they remain valid descriptions of the pipeline itself.
2. **The content (parent-mytheme) layer is now the ONLY cross-tradition instrument with independent-coder validation** (κ=0.597, round 2) — and it is the layer that shows story-cycle recovery (Maui 0.77) and geographic structure (T3). The fingerprint/passport dissociation survives ONLY in the form: content = passport (validated); grammar = so far indistinguishable from pipeline noise across traditions.
3. Within-pipeline analyses (P3/P4 diachronic) are unaffected: they never claimed cross-coder or cross-pipeline validity.
4. This reconciles with the κ rounds: slot-level κ failed twice (0.17, 0.31); profile-level placement now also fails. The grammar event-type layer carries no replicable tradition signal at current granularity.

## What would resurrect a grammar layer
A coding regime that (a) produces chains of comparable length to pipeline-v1 (episode-level, not clause-level), AND (b) is produced independently — i.e., re-code the same staged texts at episode granularity with an independent coder, THEN re-run this placement test. Only worth doing if a specific cross-tradition grammar hypothesis needs it; parent-mytheme layer currently carries the load.
