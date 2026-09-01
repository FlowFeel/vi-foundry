# P7 Protocol — Cognitive Hierarchy Integration Depth

**Date:** 2026-08-24
**Pre-registration:** Score file frozen at `data/a-priori-scores/p7_cognitive_hierarchy.tsv` before outcome merge. Hierarchy ranks and lineage breadth coded from literature, not from integration-depth data.
**Status:** PROTOCOL

## Question

Does the VI integration-depth signature hold for cognitive functions across lineages? Prediction: most deeply integrated cognitive functions (learning, memory) are most conserved across phyla — most modular (species-specific displays, cognitive specializations) are least conserved. Integration depth orders cross-lineage invariance breadth.

## Design (direct extension of P5)

- **Hierarchy source:** Built from Edelman & Seth (2009) "Animal consciousness: a synthetic approach" (*Trends Neurosci* 32: 476-484) and Birch et al. (2020, *Proc R Soc B* 287: 20200854). The candidate hierarchy levels, from bottom/substrate to top/integrated:

  1. **Nociception** (reflexive avoidance) — the simplest, most modular/substrate-level cognitive function. Point-level response to noxious stimuli, no integration across sensory modalities.
  2. **Preference learning** (approach/avoidance with valence) — requires valence encoding, but still modular: can operate within a single sensory channel.
  3. **Instrumental learning** (action-outcome associations) — requires cross-modal integration of action, outcome, and context. The simplest form of executive control.
  4. **Episodic memory** (what-where-when) — requires integration of multiple memory systems, temporal binding, and self-reference. Emerges from lower-level learning mechanisms.
  5. **Planning/prospection** (future-directed behavior) — requires episodic memory + executive simulation. The highest cognitive function documented across multiple lineages.
  6. **Theory of mind / metacognition** (modeling others' mental states) — requires recursive mental representation. The most integrated cognitive function, likely the most lineage-specific.

- **Invariance data:** Cross-lineage presence/absence of each cognitive function across phyla, compiled from comparative cognition reviews (Roth 2015, *Brain Behav Evol*; Roth 2017, *Interface Focus* 7: 20170031; Boyle & Dicke 2017, *Interface Focus* 7: 20170021; Ginsburg & Jablonka 2010, *J Cogn Sci* 11: 67-96). Breadth scored as number of phyla where the function is experimentally documented (not just theoretically plausible).

- **Prediction:** Spearman ρ between integration_depth_rank (1-6, substrate to integrated) and lineage_breadth (number of phyla with documented presence) is positive. Functions that are more integrated are more conserved across lineages.

- **Caveat (pre-registered):** Same floor problem as P5. With only 6 cognitive functions (6 levels), the minimum attainable p-value is constrained. This is a structural corroboration test, not a high-powered statistical test. The sign and direction are the primary evidence — the same argument as P5.

- **Method:** Spearman rank correlation between integration_depth_rank and lineage_breadth. Wilcoxon test comparing high-integration (depth ≥4) vs low-integration (depth ≤3) functions for lineage breadth. Binomial test of whether the more integrated half of functions show greater-than-median breadth.

## Pre-registration Statement

The hierarchy ranks are assigned a priori from the Edelman & Seth (2009) framework, which orders cognitive functions by integration requirements (not by cross-lineage breadth). The lineage breadth scores are compiled from comparative cognition literature — presence/absence documented independently of the integration-depth claim. The score file is frozen before any analysis. This is a pre-registered a priori contrast: the integration-depth order is the prediction, and the breadth data are the outcome.

## Caveats (pre-registered)

1. **Small n, constrained p.** With 6 levels, the minimum attainable one-sided p is 0.05 (Wilcoxon) or 0.0167 (Spearman with n=6 — but real p from permutation, not asymptotic). The test's role is structural corroboration, not standalone proof. This is explicitly the same limitation as P5.
2. **Presence/absence coding is a reading.** The literature's documentation of a cognitive function in a phylum depends on how it's defined and what experiments have been done. "Absence of evidence is not evidence of absence" — this is a known limitation that should be discussed in the results. The coding follows the consensus in comparative cognition reviews; a skeptic could contest individual assignments.
3. **Hierarchy is a framework, not a theorem.** The Edelman & Seth (2009) and Birch et al. (2020) frameworks are the best available integration-depth hierarchies for cognitive functions, but they are not derived from first principles. The alignment is the finding; the hierarchy is the input.
4. **Lineage breadth is not phylogenetic independence.** Scoring by phylum counts ignores phylogenetic structure. A future version should use phylogenetic comparative methods. This pre-registration acknowledges that limitation.

## Next

After analysis: compute Spearman ρ, Wilcoxon test, and binomial test. Write P7-RESULTS.md with honest statistical limits and qualitative corroboration reading.