# Simulacra — Parameter Recovery Tests

## What These Tests Prove

A simulacrum (STDD — Synthetic Test with Deterministic Data) generates synthetic data from known parameters, runs it through the pipeline, and asks: can the pipeline recover the parameters that generated the data? If it can, the methods are sound. If it cannot, the methods cannot be trusted on real data — no matter how significant the real results appear.

Each simulacrum includes a **null control**: a condition where no signal is present. If the pipeline reports signal in the null condition, the test fails — the methods are producing false positives.

## Simulacra Summary

| Simulacrum | True parameter | Recovered | Recovery | Null control | Result |
|------------|----------------|-----------|----------|-------------|--------|
| Autocatalytic diversity-dependence | slope = 1.0 | 1.051 | 100% within CI | Pass | ✅ |
| Biphasic kinetics | rate = 0.08 | 0.0796 | 100% within CI | Pass | ✅ |
| Cross-kingdom transfer | slope = 0.6 | 0.833 | 100% within CI | Pass | ✅ |
| Cusp bifurcation | b = 0.1361 | 0.4094 | 100% within CI | Pass | ✅ |
| Parameter recovery | slope = −48750 | −46652 | 100% within CI | Pass | ✅ |

## What Each Simulacrum Tests

### Autocatalytic Diversity-Dependence

Tests whether the pipeline can detect positive diversity-dependent speciation — the pattern VI predicts for the *Homo* lineage after the substrate shift from ecological to cultural niche exploitation. The simulacrum generates data where speciation rate increases with diversity (slope = 1.0). Recovery tests whether the pipeline's diversity-dependence detection correctly identifies the positive slope.

**What a failure would mean:** If the pipeline cannot detect diversity-dependent speciation in synthetic data where it exists by construction, the positive diversity-dependence reported for *Homo* (§3) could be a false negative or a mischaracterized signal. The null control verifies that the pipeline does not report diversity-dependence when none is present.

### Biphasic Kinetics

Tests whether the pipeline can detect biphasic decay — the characteristic two-phase trajectory (rapid initial shedding, slow equilibrium erosion) that VI predicts for capacity reallocation. The simulacrum generates data following a biphasic exponential decay model. Recovery tests whether the biphasic fit correctly identifies both phases.

**What a failure would mean:** If the pipeline cannot distinguish biphasic from monophasic decay in synthetic data, the biphasic kinetics reported for endosymbiont genome reduction (§12.1.4, R² = 0.920) could be an artifact of the fitting method rather than a genuine two-phase trajectory. The null control verifies that monophasic data is not misclassified as biphasic.

### Cross-Kingdom Parameter Transfer

Tests whether a parameter measured in one substrate can predict outcomes in another — the L3 cross-kingdom claim that is the most discriminating test of the framework. The simulacrum generates data where the same underlying parameter governs loss ordering across two independent substrates. Recovery tests whether the pipeline correctly identifies the transfer.

**What a failure would mean:** If the pipeline cannot detect parameter transfer in synthetic data where it exists by construction, the cross-kingdom transfer reported for plants → birds (ρ = 0.755, §12.3.5) could be a chance concordance rather than a genuine shared principle. The null control verifies that unrelated substrates are not reported as concordant.

### Cusp Bifurcation

Tests whether the pipeline can detect hysteresis (path dependence) — the formal analog of irreversibility in the VI framework. The cusp catastrophe is the mathematical structure VI uses to formalize the specialization trap: once a lineage crosses the commitment threshold, reversing the environmental parameter does not restore the ancestral state. The simulacrum generates data from a cusp catastrophe with known bifurcation parameter. Recovery tests whether the pipeline correctly identifies the hysteresis.

**What a failure would mean:** If the pipeline cannot detect hysteresis in synthetic data where it exists by construction, the irreversibility claims throughout the monograph (§§10.7, 10.8, 10.9) lack computational support. The null control verifies that non-hysteretic systems are not misclassified.

### Parameter Recovery

Tests whether the pipeline can recover a known slope parameter from synthetic data with realistic noise structure. The true slope is steep (−48750) to stress-test the pipeline's ability to recover extreme parameter values.

**What a failure would mean:** If the pipeline cannot recover parameters in the simple case, no parameter estimate in the monograph can be trusted. This is the foundational test — the floor of credibility.
