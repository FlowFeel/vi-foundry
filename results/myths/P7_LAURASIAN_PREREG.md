# P7 — Laurasian Grammar Test (PRE-REGISTRATION)

**Date:** 2026-10-17 · **Status:** pre-registered before analysis (Jan directive: "Let's test Laurasian")
**Hypothesis under test:** Witzel's Laurasian claim — that a story-grammar ("Laurasian novel") was inherited from a common source across Africa, Eurasia, and the Americas, and is *absent* (or much weaker) in the non-Laurasian band (Australia, Melanesia-Andaman, San).

## Data (fixed at registration)

- Grammar layer: all 2,385 event-chain entries from our own coding corpus, deduplicated by source file (Coder A/B formosan batches superseded by FORMOSAN_CONSENSUS; HITTITE_CODING subsumed in ANCIENT region means are merged at region level where provenance differs — log any entry used twice).
- Region assignment (fixed map in script): 17 Near East (ancient+Psalms), 14 Egypt, 29 Caucasus-Asia Minor, 23 S Asia (RigVeda), 25 Taiwan-Philippines (Formosan consensus + Tinguian + Philippines), 26 China (Davison Han), 37 Amur (Nanai), 38 Japan (Kojiki + Ainu), 39 NE Asia (Koryak), 42 NW Coast (Tsimshian), 59 Guiana (Brett), 20 Polynesia-Micronesia (Grey Māori), 18 Australia (outgroup).
- **Groups:** Laurasian = all above except 18. Gondwanan outgroup = 18 Australia. New World is Laurasian per Witzel (claimed derivation from the same novel), America regions stay inside Laurasian.
- Content layer: v3 Berezkin matrix (`trait_matrix_full.json`), restricted the same way.
- Distance: great-circle between the same first-order centroids as content_layer_tests_v3.py.

## Metrics (fixed)

For entry pairs: (a) mytheme-set Jaccard; (b) adjacent-primitive bigram Jaccard. Region-pair value = mean over entry pairs. Content pair value = motif-set Jaccard. All three similarity layers are residualized on log(1+distance) (linear fit) before group contrast.

## Contrasts (fixed)

1. **Delta (per layer):** mean residual similarity within-Laurasian minus mean residual similarity Laurasian×Australia. Positive delta for grammar layers = Laurasian affinities exist beyond distance and beyond content.
2. **Key ordering prediction:** delta_grammar ≥ delta_content on the same regions (grammar is the more conserved layer even where content is washing out).
3. **Ex exchangeability check:** leave-one-out — mean residual similarity of each region vs the rest; Australia's rank among the 13 regions for grammar vs content.

## Nulls and error control (fixed before running)

- Pair bootstrap over regions-within-group (B=10,000) for CI of each delta.
- Permutation of region group labels (shuffle which regions sit in Laurasian vs outgroup is NOT warranted — instead permute the outgroup set: randomly draw one region as pseudo-outgroup, B=13 draws incl. actual; the observed Australia delta's one-sided rank in that distribution = per-region p). This dodges the asymmetric-group trap.
- Shared-vocabulary artifact control: grammar similarities computed on bigrams of event types (order, not vocabulary) and re-checked against the shuffled-chain-within-entry null used in P2. If position/bigram signal dies under within-entry shuffle, the grammar signal is a coding-vocabulary artifact, not structure.
- Coder non-blindness is a known limitation: all chains are our own codings; coder-B kappa pilot (running in parallel) is the mitigation; if kappa fails the bar, P7's grammar layer is flagged as provisional regardless of result.

## Falsification thresholds (declared prior)

- Grammar delta ≤ 0 → Laurasian grammar claim dead at current coverage.
- 0 < grammar delta but delta_grammar < delta_content → layers carry same signal; split-layer framing weakens for this hypothesis.
- Grammar delta survives distance control and exceeds content delta, but collapses under within-entry shuffle → the "grammar" was coding vocabulary, not narrative structure (method artifact, hypothesis unresolved).
- Pass: grammar deltas positive with CI excluding 0 on ≥2 of the 2 grammar metrics, ordering prediction holds, shuffle-robust. Anything else is explicit provisional/failed.