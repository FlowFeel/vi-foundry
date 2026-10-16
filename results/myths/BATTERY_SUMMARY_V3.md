# Split-Layer Battery — consolidated results (v3 era)

**Date:** 2026-10-16 · **Script:** `scripts/myth/split_layer_battery_v3.py` · single source of truth for T1-T5, P1, P2, P5 status

## 1. Content layer: before (v1 parse) vs after (v3 parse)

| Test | v1 (3,188 motifs, noisy regions) | v3 (3,484 motifs, 0 unmapped) | Verdict |
|---|---|---|---|
| T1 hemisphere signal | 3.44x (0.048 / 0.047 / 0.014) | 1.77x (0.194 / 0.171 / 0.1029) | sign holds, magnitude halves |
| T2 PC1 variance | 10.3% | 19.299999237060547% | stronger continental axis |
| T2 PC1-hemisphere alignment | qualitative | r = 0.717 | quantified |
| T3 isolation-by-distance | rho = -0.49 (n=2016) | rho = -0.46 (n=1891) | holds |
| T4 language family | 3.6x | 2.04x | holds, diluted |
| T5 family beyond distance | not run | delta = 0.0466, perm p = 0.0005 | NEW: survives control |

**Reading:** magnitudes were inflated ~2-4x by v1's noisy region keys; every direction/ranking survives. The corrected content layer is *less* hemisphere-bimodal — consistent with a borrowing-fair motif layer, which is what the split-layer contrast needs.

## 2. Grammar layer: new results

### P1 — split-layer pairing (7 regions, 30 entries, 15 pairs)
- content x grammar orthogonality: rho = -0.191 (mytheme), -0.355 (primitives); grammar layers agree rho = 0.843
- P5 falsifier (r > 0.3 redundant): **NOT triggered** — layers orthogonal at pilot n
- 9/15 pairs grammar >> content (ratio 2-10x); 0 grammar << content pairs

### P2 — prayer-register universality: set-level vs ordering-level

| Pair | set Jaccard | bigram | position agreement | strict order % | 0.6 bar |
|---|---|---|---|---|---|
| Psalms x RigVeda | 0.575 | 0.177 | 0.697 (null 0.693±0.022, p=0.44, null) | 0.0% | fail |
| Psalms x Egyptian | 0.302 | 0.098 | 0.75 (null 0.722±0.032, p=0.19, null) | 0.0% | fail |
| Psalms x Mesopotamian | 0.362 | 0.1 | 0.734 (null 0.714±0.022, p=0.23, null) | 0.0% | fail |
| Psalms x Hittite | 0.404 | 0.15 | 0.72 (null 0.722±0.026, p=0.575, null) | 0.0% | fail |
| RigVeda x Egyptian | 0.27 | 0.107 | 0.799 (null 0.736±0.031, p=0.01, SIG) | 0.0% | PASS |
| RigVeda x Mesopotamian | 0.34 | 0.098 | 0.718 (null 0.7±0.023, p=0.23, null) | 0.0% | fail |
| RigVeda x Hittite | 0.388 | 0.154 | 0.785 (null 0.719±0.026, p=0.005, SIG) | 0.0% | PASS |
| Egyptian x Mesopotamian | 0.667 | 0.279 | 0.735 (null 0.774±0.054, p=0.745, null) | 0.0% | fail |
| Egyptian x Hittite | 0.359 | 0.206 | 0.81 (null 0.814±0.039, p=0.57, null) | 0.0% | fail |
| Mesopotamian x Hittite | 0.495 | 0.269 | 0.813 (null 0.815±0.042, p=0.535, null) | 0.0% | fail |

**Verdict:** 2/10 pairs clear the pre-registered 0.6 bar on ordering metrics **after** beating the shuffled-chain null. First pass without the null scored 10/10 PASS — an artifact: random-order chains agree ~0.7 under the position metric by construction. Strict REQ→SACR→CURS first-occurrence order is near-absent even within traditions (Psalms 14%, RV 0%). SURVIVING P2 signal: set-level mytheme overlap (Psalms×RV 0.575, ancient NE sphere 0.36-0.67) vs myth-content cross-hemisphere 0.10 — grammar ~5x more shared than content, but NOT a 0.6-universal. Honest status: P2 as pre-registered FAILS at current operationalization.

### P3 / P4 — from coded docs (provenance reported, not recomputed here)
- P3 deictic transposition: Egypt 2.07->4.69, Akkadia 3.13->9.98, Hittite 2.37->8.82, Ugaritic Baal 5.69 (ANCIENT_GRAMMAR_DEICTIC.md)
- P4 diachronic congealing: Mesopotamia ORDERING%xroyal 0.7->14.7 rising; Egypt 5.4->0.6 declining (DIACHRONIC_POLITICAL_RELIGION.md)

### P6 — Polyphemus phylogeny: PENDING (d'Huy RMN-9 variant list not yet in repo)
