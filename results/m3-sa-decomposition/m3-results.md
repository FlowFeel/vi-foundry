---
uri: vi-foundry/results/m3-sa-decomposition/m3-results
author: Flow
date: 2026-08-24
status: complete
---

# M3: S+A Decomposition — Are VI Dynamics Purely Dissipative?

## The Test

Decompose the trait-loss Jacobian into symmetric (S, dissipative) and antisymmetric (A, rotational) components. If A ≈ 0, dynamics are purely dissipative (thermodynamic character). If A ≠ 0, there are non-dissipative biological components.

## Results

### System 1: LTEE single-trait (trivial)

J = −(k₁ + k₂) = −18.17 (scalar). S = J, A = 0. Trivially dissipative — a 1D system can't have rotation.

### System 2: LTEE multi-trait (2 bins — low-dependency vs high-dependency genes)

62 gene loss events from LTEE data, split by dependency score:
- Low-dependency (n=54): mean loss at generation 15,989
- High-dependency (n=8): mean loss at generation 10,083

The coupling between bins is **asymmetric** — low-dependency genes lose first, and this state affects high-dependency loss rate, but not vice versa. This creates off-diagonal asymmetry in the Jacobian.

**Result:**
- ||S|| = 0.000345 (dissipative)
- ||A|| = 0.000324 (rotational)
- **Dissipation ratio: 0.515** (51.5% dissipative, 48.5% rotational)
- Classification: **NON-CONSERVATIVE** — significant rotational component

**This means the dynamics are NOT purely dissipative.** Nearly half the dynamic structure is rotational (circulatory), not dissipative.

## What This Means

The S+A decomposition shows that when you move from single-trait to multi-trait dynamics, the VI rate law's clean dissipative character breaks down. The coupling between trait categories introduces rotational components that don't have a thermodynamic analogue.

In chemistry, coupled reactions can have catalytic cycles (rotational), but the overall system is still dissipative (entropy increases). The question is whether the 48.5% rotational component is:
- **Catalytic cycling** (still thermodynamic — just coupled reactions with intermediates) → MEP survives
- **Non-dissipative feedback** (biological — regulatory hierarchy, not thermodynamic) → MEP weakened

The biological interpretation favors the second: regulatory networks are hierarchical (master regulators → downstream), creating asymmetric coupling. This is not catalytic cycling — it's directed control flow, which has no chemical analogue.

## Caveats

1. **Coupling estimation is approximate.** The off-diagonal terms were estimated from temporal ordering, not from direct interaction measurements. A proper test would use GRN data to measure coupling directly.
2. **The VI model treats traits independently.** The coupling we observe is OUTSIDE the VI model. This means VI is a simplification — the real dynamics are richer than the rate law captures.
3. **The rotational component might be an artifact** of how we binned genes. With different binning, the asymmetry might disappear. Needs sensitivity analysis.
4. **Small sample in high-dependency bin (n=8).** The high-dependency rate is estimated from 8 genes, which is noisy.

## Verdict

**MEP is weakened but not ruled out.** The dynamics have a significant rotational component (48.5%) when multi-trait coupling is considered. This is inconsistent with purely dissipative thermodynamic relaxation. However, the coupling estimation is approximate, and the rotational component might be catalytic cycling (which is still thermodynamic).

**The honest conclusion:** The single-trait VI rate law is purely dissipative. The multi-trait dynamics are not. The VI model is a simplification of a richer system that includes non-dissipative coupling. Whether this coupling is thermodynamic (catalytic) or biological (regulatory) is undetermined.
