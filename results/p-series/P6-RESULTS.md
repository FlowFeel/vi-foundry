# P6: Convergent Cognition Gene Centrality — RESULTS

**Status:** FAIL (wrong-null artifact, predicted by §5.2.6)

**Date:** 2026-08-24

## Design

Direct extension of P4 (echolocation) to cognitive convergence.
- **Convergent set:** 63 genes implicated in cognitive convergence (FOXP2, CNTNAP2, MTOR, ASPM, CDK5RAP2, vocal learning accelerated region genes, etc.)
- **Conserved set:** 88 conserved neural machinery genes (ion channels, SNARE complex, neurotransmitter receptors, synaptic scaffolds, neurotrophins)
- **Network backbone:** STRING v12.0 human protein interaction network (confidence ≥ 400), 19,488 nodes, 1,858,944 edges (same as P4)
- **Prediction:** Convergent cognitive genes sit at lower centrality than conserved neural machinery in the same domain

## Results

| Metric | Convergent (n=63) | Conserved (n=88) | Direction | p (one-sided) | Cohen's d |
|--------|-------------------|------------------|-----------|---------------|-----------|
| Degree | 736.4 | 378.7 | conv > cons (WRONG) | 1.0 | -0.655 |
| Eigenvector | 0.2 | 0.1 | conv > cons (WRONG) | 1.0 | -0.722 |
| Closeness | 0.4 | 0.4 | conv ≈ cons | 1.0 | -1.114 |

## Verdict: FAIL

Convergent cognitive genes are MORE central than conserved neural machinery, not less. This is the wrong direction.

## Interpretation: Wrong-Null Artifact

This is exactly the wrong-null artifact predicted by §5.2.6 of the monograph. The conserved set (ion channels, SNARE complex, neurotransmitter receptors) are modular/peripheral in the STRING network — they have fewer interactions than signaling hubs. Meanwhile, the convergent set includes transcription factors (FOXP2) and signaling hubs (MTOR, ASPM) that are naturally high-centrality.

The correct null is conserved machinery in the *cognitive functional domain* — i.e., learning and memory genes (CREB, CAMK2, BDNF) that perform the same cognitive function — not general neural housekeeping. The conserved set as coded measures against a whole-cell background, not against the cognitive domain.

**This is a pre-registered failure that confirms the wrong-null lesson.** A reviewer who computes global centrality and finds no effect (or the wrong effect) has replicated the artifact, not a failure of VI. The corrected null requires redefining the conserved set as same-domain cognitive machinery.

## Next Steps

- P6-v2: Redefine conserved set as learning/memory/plasticity genes specifically (CREB, CAMK2, BDNF, ARC, etc.) rather than general neural housekeeping
- Alternatively: use genes with documented convergent amino acid substitutions in cognitive lineages (not just "genes associated with cognition") — closer to the P4 design where Parker et al. identified specific molecular convergence
