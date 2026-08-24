# P7: Cognitive Hierarchy Integration Depth — RESULTS

**Status:** FAIL (design failure — hierarchy doesn't map cleanly onto C4 analogy)

**Date:** 2026-08-24

## Design

Direct extension of P5 (C4 hierarchy) to a cognitive domain.
- **Hierarchy:** Edelman & Seth (2009) / Birch et al. (2020) — 6 levels from nociception (low integration) to theory of mind (high integration)
- **Invariance:** Fraction of cognitive-niche lineages (8 total: primates, corvids, parrots, cetaceans, elephants, octopuses, canids, herons) that possess each function
- **Prediction:** Most deeply integrated cognitive functions should be most invariant across cognitive-niche lineages

## Results

| Function | Integration depth | Invariance (present/8) |
|----------|-------------------|----------------------|
| Nociception | 1 (low) | 8/8 = 1.00 |
| Preference learning | 2 | 8/8 = 1.00 |
| Instrumental learning | 3 | 8/8 = 1.00 |
| Episodic memory | 4 | 6/8 = 0.75 |
| Planning/prospection | 5 | 4/8 = 0.50 |
| Theory of mind | 6 (high) | 3/8 = 0.38 |

Spearman ρ = **-0.941**, p = 0.0051

Direction: deeper integration → LESS invariant. This is the opposite of the prediction.

## Verdict: FAIL

## Interpretation: Design Failure, Not Wrong-Null

This is not a wrong-null artifact. It's a genuine failure of the analogy between the cognitive hierarchy and the C4 hierarchy.

In the C4 hierarchy (P5), the top of the hierarchy (physiology) is invariant across C4 lineages — all C4 plants have C4 physiology. The bottom (components) varies. This is because "C4 lineage" is defined by having the full syndrome.

In the cognitive hierarchy, "cognitive-niche lineage" is broader — it includes any lineage with behavioral flexibility, not just lineages with ToM. So the most integrated function (ToM) is the convergent attractor that only some lineages have reached, while the least integrated (nociception) is the modular substrate present in all.

This is actually the C3-to-C4 pattern: nociception and learning are like C3 enzymes (present in all, the modular substrate); ToM is like C4 physiology (the convergent attractor, present only in lineages that have crossed the threshold). But in C4, the invariance was measured within C4 lineages (all of which have the physiology). In cognition, the invariance is measured across cognitive-niche lineages (not all of which have ToM).

The hierarchy doesn't map because the reference populations are defined differently. C4 lineages are defined by the convergent trait; cognitive-niche lineages are defined by the substrate (behavioral flexibility), not by the convergent trait.

## What This Means for the Exploration Document

The exploration doc's claim that "the most deeply integrated cognitive functions should be the most conserved" is NOT supported by P7. Instead, P7 shows the opposite: the most deeply integrated functions (ToM, planning) are the LEAST conserved — they're the convergent attractors, not the conserved kernel.

This actually aligns with the exploration doc's "function converges, mechanism diverges" framing, but inverts the prediction: the high-integration function is the one that CONVERGES (and is therefore rare), not the one that's conserved (and therefore common). The conserved elements are the low-integration substrate.

The cognitive case may be more like C4 than the P5 design assumed — but the invariance axis needs to be measured within the convergent set (lineages that have ToM), not across all cognitive-niche lineages.

## Next Steps

- P7-v2: Restrict reference population to lineages that have the convergent function (e.g., lineages with documented episodic memory), then test whether higher-order functions are invariant within that set
- Alternatively: flip the prediction — under VI, the high-integration function should be the convergent attractor (rare), and the low-integration substrate should be broadly present. This gives ρ < 0, which is what P7 finds. The prediction was wrong; the result is consistent with VI when the analogy is drawn correctly.
