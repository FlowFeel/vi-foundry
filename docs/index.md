# VI Foundry — Landing Page

## Purpose

The VI Foundry is the computational verification layer for the Valence-Ingression Framework. It provides reproducible, deterministic verification of every quantitative claim made in §12 of the monograph. The foundry does not test the hypothesis against new data — it verifies that the computational pipeline reproduces the manuscript's reported values, and that the statistical methods can recover known parameters from synthetic data.

## What This Site Contains

| Page | What it proves |
|------|---------------|
| [Simulacra](simulacra.html) | The pipeline can recover known parameters from synthetic data. If the methods cannot recover ground-truth parameters when the answer is known, they cannot be trusted on real data. |
| [Baseline Oracle](baseline-oracle.html) | The pipeline reproduces every §12 manuscript value within tolerance. Each result is tagged with whether it supports the VI prediction and whether it distinguishes VI from named competitor hypotheses. |
| [Key Results](key-results.html) | Summary of the discriminating core: 6 of 9 tests distinguish VI from alternatives; 3 are consistent with VI but do not discriminate it, and are stated as such. |
| [Toy Realms](toy-realms.html) | Interactive explorers for genome reduction, irreversibility, the *Homo* inversion, and cross-kingdom parameter transfer. These are speculative, not tests. |
| [Economics Extrapolations](economics-extrapolations.html) | The relaxation formula applied to firm specialization, credit upcycles, tech adoption, and option value. Speculative — not tests. |
| [Formula Analysis](formula-analysis.html) | Three-move derivation of VI's functional form: Ohta (inductive), Fisher (decompositional), Wimsatt (triangulation). Data suggests a step-function (first-order phase transition), consistent with the monograph's cusp catastrophe. |
| [Mathematical Genealogy](mathematical-genealogy.html) | Formal chain from Ising (1925) through Thom's catastrophe theory, percolation theory, and the drift-selection boundary to the VI formula ρ(θ) = ρ_sat · H(θ − θ*). Each step's mathematical statement, connection type, and evidential status. |
| [Implementation Audit](implementation-audit.html) | Equation-to-function mapping, test coverage audit, monograph number traceability, and identified gaps between formal claims and computational verification. |

## How to Read This Site

The foundry is designed for a reader who encounters a claim in the monograph (e.g., "ρ = 0.955, p = 0.003") and wants to verify: (a) that the code produces that number from the data, (b) that the statistical method can recover known parameters when the answer is provided, and (c) whether the result distinguishes VI from its named competitors. Each page links to the R source code, the oracle configuration, and the test that gates the result.

The full review documentation — including the line-by-line math audit, the formal model reproduction, and the refactoring log — is available in the [review directory](review/).

## Verification Standard

All quantitative results were independently verified through computational testing by Ed Phillips. The verification pipeline uses:

- **Oracle baseline** (`baseline/oracle.yml`): every manuscript value stored as ground truth with absolute tolerance bands
- **Regression gates**: CI fails if pipeline output deviates from oracle values beyond tolerance
- **Parameter-recovery simulacra**: synthetic data with known ground truth, testing whether the pipeline can recover the parameters that generated it
- **Null controls**: each simulacrum includes a null condition where no signal should be recovered — if the pipeline reports signal in the null, the test fails

Source: [https://github.com/FlowFeel/vi-foundry](https://github.com/FlowFeel/vi-foundry)
