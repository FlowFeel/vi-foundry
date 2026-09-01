# P8 Protocol — Sleep Architecture as Convergent Attractor

**Date:** 2026-08-24
**Pre-registration:** Score file frozen at `data/a-priori-scores/p8_sleep_cognitive_niche.tsv` before outcome merge. Taxon selection and coding criteria defined from literature before analysis.
**Status:** PROTOCOL

## Question

Is two-stage sleep (NREM/REM in vertebrates, quiet/active in cephalopods) a high-integration attractor that converges in lineages with cognitive niches? Prediction: two-stage sleep evolves only in lineages with behavioral flexibility, complex learning, and memory — the cognitive niche. Absent in lineages without cognitive niches.

## Design (pre-registered literature-based presence/absence test)

- **Convergent set:** Lineages with documented two-stage sleep:
  - **Mammals:** Human, mouse, rat, cat, dog, dolphin, elephant — all showing NREM/REM cycling (Medeiros et al. 2021, *iScience* 24: 102445; Roth 2015).
  - **Birds:** Zebra finch, pigeon, owl — showing NREM/REM cycling, including unihemispheric sleep in some species (Medeiros et al. 2021).
  - **Cephalopods:** Octopus — showing quiet/active sleep stages behaviorally and electrophysiologically distinct (Medeiros et al. 2021). Cuttlefish — also showing two-stage sleep.
  - **Reptiles:** Bearded dragon (*Pogona vitticeps*) — one species documented with REM-like and NREM-like states (Shein-Idelson et al. 2016, *Science* 352: 590-594). Coded as Y for two-stage sleep but N for cognitive niche (reptilian cognitive niche is debated).

- **Control set:** Lineages without documented two-stage sleep:
  - **Nematodes:** *C. elegans* — sleep-like states documented (lethargus) but no evidence of two-stage cycling (Medeiros et al. 2021).
  - **Cnidarians:** Jellyfish (*Cassiopea*) — sleep-like states documented (Nath et al. 2017, *Curr Biol* 27: 2984-2990) but no evidence of two-stage cycling.
  - **Simple invertebrates:** Sponge, sea anemone, planarian, leech, *Aplysia*, crayfish, lobster — no documented sleep or only simple sleep-like quiescence.
  - **Insects:** Fruit fly (*Drosophila*) — sleep-like states documented but no evidence of two-stage cycling. Honeybee — sleep documented but unihemispheric, not two-stage cycling as in mammals/birds (though a debated case; coded N conservatively).

- **Prediction:** Two-stage sleep evolves only in lineages with cognitive niches (behavioral flexibility, learning, memory). The set of lineages with two-stage sleep should be a subset of lineages with cognitive niches. The converse (cognitive niche → two-stage sleep) is not predicted — some cognitive lineages may not have evolved two-stage sleep, or it may have been lost.

- **Method:** Fisher's exact test on 2×2 table (two-stage sleep Y/N × cognitive niche Y/N). If a phylogenetic tree is available, phylogenetic logistic regression as a robustness check.

- **Coding criteria (pre-registered):**
  - **Two-stage sleep = Y:** Peer-reviewed evidence of two electrophysiologically or behaviorally distinct sleep states in the lineage (NREM/REM or quiet/active).
  - **Two-stage sleep = N:** No documented evidence of two-stage sleep, despite sleep-like states being studied.
  - **Cognitive niche = Y:** Evidence of behavioral flexibility, complex learning, long-term memory, or tool use in the lineage. Based on consensus in comparative cognition literature.
  - **Cognitive niche = N:** No evidence of behavioral flexibility or complex learning beyond simple habituation.

## Pre-registration Statement

The taxa list and coding criteria are defined from the literature before any analysis. The coding is binary (Y/N/unknown) with explicit criteria. The score file is frozen at `p8_sleep_cognitive_niche.tsv` before any statistical test. Unknown codings are excluded from the primary analysis and reported separately. This is a pre-registered a priori contrast: the prediction is that two-stage sleep and cognitive niches co-occur beyond chance.

## Caveats (pre-registered)

1. **Literature-based coding is a reading.** The presence/absence of two-stage sleep and cognitive niches depends on how they're defined and what evidence exists. "Absence of evidence" is a known limitation. The coding follows the consensus in comparative sleep and cognition literature; a skeptic could contest individual assignments.
2. **Small n, constrained test.** With ~25 taxa and a 2×2 table, Fisher's exact test is the right tool but has limited power. The test's role is structural corroboration, not standalone proof.
3. **Phylogenetic non-independence.** Taxa are not independent — the Fisher test assumes independence. A phylogenetic logistic regression is the proper robustness check if a tree is available.
4. **Bearded dragon is a boundary case.** One reptile species shows two-stage sleep but is not generally considered a cognitive-niche lineage. Its coding affects the result. Pre-registered coding: Y two-stage, N cognitive niche. Sensitivity analysis should check both codings.
5. **Honeybee is a boundary case.** Honeybees show complex learning and cognitive abilities (cognitive niche = Y) but the two-stage sleep coding is contested. Pre-registered coding: N (conservative). Sensitivity analysis should check both codings.

## Next

After analysis: compute Fisher's exact test. If a phylogenetic tree is available, also run phylogenetic logistic regression. Write P8-RESULTS.md with honest statistical limits and discussion of boundary cases.