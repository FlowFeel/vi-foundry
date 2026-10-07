---
title: "Review: Bentz & Dutkiewicz 2026 — Conventional Signs of the Swabian Aurignacian"
source: "Bentz, C. & Dutkiewicz, E. (2026). PNAS 123(9), e2520385123."
foundry_review_id: "CR-001"
---

# Review: Bentz & Dutkiewicz (2026)

## Summary

The paper presents a systematic quantitative corpus analysis of geometric sign sequences on mobile artifacts from the Swabian Aurignacian (43–34 kya), applying information-theoretic statistical features (TTR, unigram entropy, entropy rate, repetition rate) and comparing them to protocuneiform (Uruk V, IV, III) and modern writing (TeDDi sample). The core empirical findings are solid: Aurignacian sign sequences are statistically indistinguishable from the earliest protocuneiform (Uruk V), clearly distinguishable from modern writing, and were applied selectively — ivory figurines carry significantly higher information density than tools.

## Review Items

### R1 — Title/evidence gap (mild M-failure)

**Finding:** The title claims humans "developed a system of conventional signs." The evidence supports *structured, differential, patterned usage* — which is strong — but "conventional" in the Peircean sense requires demonstrated shared arbitrary meaning. The evidence shows systematic application by object type (crosses never on anthropomorphs, dots never on tools), which is consistent with conventionalization, but does not strictly prove shared arbitrary meaning.

**Severity:** Mild. The discussion section is appropriately cautious ("hard—or impossible—to prove that Aurignacian sign systems served the same numero-ideographic functions"). The overclaim is confined to the title and significance statement.

**Recommendation:** Cite with qualification. Use the paper's statistical results (aurignacian ≈ Uruk V in feature space; selective object-type usage) without attributing full Peircean conventionality.

### R2 — Underutilized semiotic evidence

**Finding:** The strongest evidence for conventionalization — the sign-type × object-type selectivity (crosses vs. dots, SI Appendix Fig. S5) — is mentioned in the discussion but never formally tested. No chi-square or Fisher exact test is reported for these contingency patterns. The paper foregrounds the PCA overlap with Uruk V instead, which is weaker evidence.

**Severity:** Minor. The selectivity finding is real but under-analyzed. A formal significance test would strengthen the conventionalization argument.

**Recommendation:** Future work should apply a chi-square or exact test to the sign-type × object-type contingency table.

### R3 — Aurignacian ↔ Uruk V analogy

**Finding:** The paper claims statistical similarity between Aurignacian and Uruk V protocuneiform sequences. This is well-supported (PCA ellipses fully overlap; classifiers at chance). However, the strong disanalogies — hunter-gatherer vs. urban temple economy; stable for 10ky vs. complexified in 1ky; disappeared vs. → cuneiform — mean that statistical similarity does not license functional equivalence.

**Severity:** Moderate. The paper appropriately hedges in the discussion but the rhetorical framing ("comparable complexity," "developed a system of conventional signs") implies functional similarity.

**Recommendation:** The statistical similarity result is real and valuable. Use it as evidence for *computational capacity* rather than *functional equivalence*.

### R4 — Single-region limitation

**Finding:** All 260 artifacts come from 4 caves in the Swabian Jura within hiking distance of each other (Vogelherd, Hohle Fels, Geissenklösterle, Hohlenstein-Stadel). The paper does not discuss whether these results generalize to other Aurignacian regions (Dordogne, Belgium) or other periods (Gravettian, Magdalenian).

**Severity:** Minor. The paper accurately describes its data provenance but should state the generalizability boundary explicitly.

**Recommendation:** Test the same method on Dordogne Aurignacian material (Abri Blanchard, etc.) and on African MSA material (Blombos, Diepkloof).

### R5 — No African MSA comparison

**Finding:** The paper's framing — "first hunter-gatherers arriving in Europe already developed a system" — implicitly treats sign system development as correlated with the European Aurignacian expansion. The same statistical methodology applied to African MSA engraved material (Blombos 100 kya, Diepkloof 60 kya) would test whether this capacity is species-wide or specific to the European context.

**Severity:** Moderate. This is the most obvious extension the paper does not discuss.

**Recommendation:** Apply the 4-feature statistical fingerprint to African MSA sign sequences if available in SignBase or related databases.

### R6 — Inter-rater reliability

**Finding:** Cohen's κ = 0.29–0.44 for alternative sign type codings. This is moderate agreement (Landis & Koch: "fair to moderate"). The paper reports this transparently but does not test how alternative coding assignments affect the results (sensitivity analysis).

**Severity:** Minor. The κ values are moderate but the agreement score (91–94%) appears higher, suggesting the κ is depressed by skewed marginal distributions rather than genuine disagreement. A sensitivity analysis would strengthen confidence.

## Numerical Baseline

See `baseline/convsigns.yml` for oracle values. Key numerical targets:

| Output | Expected value | Tolerance |
|--------|---------------|-----------|
| Regression R² | 0.25 | ±0.01 |
| Regression F | 8.5 | ±0.1 |
| Zoomorph β | +0.23 | ±0.01 |
| Personal ornament β | −0.32 | ±0.01 |
| Tube/flute β | −0.22 | ±0.01 |
| Fragmented preservation β | −0.2 | ±0.01 |
| Semipartial ΔR² for object type | 0.13 | ±0.01 |

## WCI Score

**70.6/100 — Tier 2 (Promising)**

Core empirical work is strong. The statistical fingerprinting method is replicable and the open-data/open-code practice is excellent. The mild M-failure in the title and the weak Aurignacian ↔ Uruk V analogy are the main constraints.

| Dimension | Score | Verdict |
|-----------|-------|---------|
| Novelty | 7/9 | Strong |
| Evidence Density | 7/9 | Strong |
| Predictive Power | 5/9 | Moderate |
| Theoretical Coherence | 7/9 | Strong |
| Parsimony | 7/9 | Strong |
| Scope | 5/9 | Moderate |
| Literature Integration | 7/9 | Strong |
| Claim-Evidence Match | 6/9 | Good (one mild M-failure) |
| Demarcation | 6/9 | Good |

## Test Suite Coverage

Test files in `tests/testthat/`:

| Test file | What it covers | Status |
|-----------|----------------|--------|
| `test-convsign-features.R` | TTR, entropy, entropy rate, repetition rate, volume | ✅ |
| `test-convsign-regression.R` | Regression coefficients, PCA, entropy rate bounds | ✅ |

## Data

Data loaded from SignBase v2.0 (Dutkiewicz et al. 2020, doi: 10.5281/zenodo.18401937), stored in `inst/extdata/convsigns/`.

## Known Limitations

1. **LZ78 entropy rate estimator:** Overestimates for short sequences (≤10 tokens). The paper's SI Appendix Figs. S9–S12 show stabilization properties.
2. **Missing MLP tests:** The paper's neural network classification requires Python/TensorFlow and is not replicated in the R-based test suite. KNN alone gives the core result (Aurignacian ≈ Uruk V statistically).
3. **Protocuneiform data not bundled:** The CDLI data requires API access. The foundry tests only reproduce the Aurignacian-side analysis (feature computation, regression, PCA). Classification comparisons against protocuneiform/TeDDi require external data download.