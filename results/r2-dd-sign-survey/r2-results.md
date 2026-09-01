---
uri: vi-foundry/results/r2-dd-sign-survey/r2-results
author: Flow
date: 2026-08-24
status: preliminary
---

# R2: DD Sign Survey — Preliminary Results

## What the data show

The R2 subagent compiled the full Phillimore & Price (2008) dataset of 45 bird clades with DD coefficients (γ), plus 5 extension clades (sexual selection systems). Each clade was classified by substrate type (generative vs. ecological) from independent behavioural evidence (vocal learning, social learning, tool use, combinatorial signals).

## The headline finding

**The prediction is NOT confirmed.** 

Almost ALL clades show negative DD, regardless of substrate type. The generative substrate clades (oscine passerines with vocal learning, complex songs, social learning) show negative DD just like the ecological substrate clades (non-vocal-learning birds).

### Generative substrate clades with NEGATIVE DD:
- Wrens (γ = −3.628, p < 0.001) — vocal learners, complex songs
- Phylloscopus (γ = −2.991, p < 0.01) — vocal learners, regional dialects
- Estrildidae (γ = −2.743, p < 0.01) — vocal learners, cultural transmission
- Parus (γ = −2.622, p < 0.01) — vocal learners, social learning, food caching
- Amazona (γ = −1.856, p < 0.05) — parrots, advanced vocal learning, tool use
- All 16 oscine passerine clades with vocal learning show negative DD

### Ecological substrate clades with NEGATIVE DD:
- Tringa (γ = −1.850, p < 0.05) — sandpipers, no vocal learning
- Anas (γ = −1.377, ns) — ducks, no vocal learning
- Thamnophilus (γ = −1.282, ns) — antbirds, suboscine, innate songs
- All 15 ecological clades also show negative DD

### Clades with positive DD (all ecological, all non-significant):
- Alectoris (γ = 0.287, ns) — partridges
- Cinclodes (γ = 0.465, ns) — ovenbirds (suboscine)
- Cranes (γ = 0.671, ns) — no vocal learning
- Albatross (γ = 0.866, ns) — no vocal learning
- Sterna (γ = 1.365, ns) — terns
- Puffinus (γ = 1.490, ns) — shearwaters
- Tauraco (γ = 1.657, ns) — turacos
- Myiarchus (γ = 1.854, ns) — tyrant flycatchers (suboscine)

**All positive DD clades have ecological substrates. None have generative substrates. All are non-significant.**

### Extension clades (sexual selection systems):
- Cichlids — negative DD (explosive radiation then saturation)
- Birds of paradise — negative DD
- Bowerbirds — negative DD
- Hummingbirds — negative DD (early burst then slowdown)
- Túngara frog — species-level, no clade-level DD estimate

**All sexual selection extension clades show negative DD.**

## What this means for VI

The prediction was: β > 1 (generative substrate) ⟺ positive DD.

**This is falsified for birds.** Generative substrate clades (vocal learners) show negative DD, same as ecological clades. The sign of DD does NOT distinguish substrate type in birds.

However, there is a nuance:

1. **All positive DD clades are ecological, not generative.** This is the opposite of the prediction — positive DD is associated with the ABSENCE of generative substrates, not their presence.

2. **No clade in this dataset shows significant positive DD.** All significant DD coefficients are negative. Positive DD is absent at the taxonomic scale of bird families/genera.

3. **Homo is still the only known lineage with sustained significant positive DD.** The extension clades (cichlids, birds of paradise, hummingbirds) all show negative DD — explosive initial radiation followed by slowdown.

## Possible interpretations

### A. The prediction is wrong for birds
Bird diversification may be driven by niche space (ecological, finite) regardless of vocal learning. Vocal learning is a trait, not a substrate that creates new niches. The β > 1 → positive DD prediction may only apply when the substrate creates genuinely new niches (language → technology → institutions), not when it creates combinatorial signals (bird songs).

This would mean: **β > 1 is necessary but not sufficient for positive DD. The substrate must also be cumulative** — each generation must build on the previous one's modifications. Bird song is combinatorial (β > 1) but not cumulative (each bird starts from scratch). Language is both combinatorial AND cumulative (ratchet effect, Tomasello).

### B. The scale is wrong
Phillimore & Price's clades are at the family/genus level. Positive DD may only appear at higher taxonomic scales (orders, classes) or in specific conditions (island radiations, cultural niche construction). The Homo case may be unique because human culture is uniquely cumulative.

### C. The prediction needs refinement
The refined P7 prediction from the monograph already anticipated this: "Weak culture attenuates negative DD; strong culture produces transient positive DD episodes; human-level culture produces sustained positive DD." The bird data are consistent with this refinement — bird culture is "weak" (combinatorial but not cumulative), so it attenuates but doesn't reverse DD.

The R2 data show: bird culture (vocal learning) does NOT attenuate negative DD. All oscine clades show strong negative DD. This is even weaker than the refined prediction — bird culture doesn't even attenuate.

## What about the valence-seeking question?

The R2 result is informative for the valence-seeking framework:

- If valence-seeking is a universal dynamics, the rate constants should be similar across systems. The bird data show that the DD coefficient (which is related to the slowing of diversification, analogous to k₂) varies across clades but is consistently negative.
- The floor (ρ_eq) varies by clade — some clades have more species than others at similar ages. This is consistent with niche-defined equilibrium (different niches, different ρ_eq).
- The absence of positive DD in generative-substrate clades means the attractor is still saturating. The niche is finite even for vocal learners. This supports the "analogy, not identity" interpretation — biological niches are finite, while the thermodynamic "attractor" (minimum free energy) is a different kind of equilibrium.

## Status

**Prediction falsified for birds.** β > 1 (combinatorial substrate) does NOT produce positive DD in birds. The prediction may need to be refined to require cumulative culture (ratchet effect), not just combinatorial signals.

**Homo remains the only known case of sustained positive DD.** This makes the prediction less general — it may be specific to cumulative culture, not to generative substrates in general.

**Next steps:** 
1. Check whether the refined prediction (cumulative vs. combinatorial substrate) can be operationalized
2. Check non-bird clades (bats, cetaceans, primates) for DD sign vs. substrate type
3. Consider whether the prediction should be dropped or further refined

## Data

Full classification table: `r2-raw-data.tsv` (45 Phillimore & Price clades + 5 extension clades)
