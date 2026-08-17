---
uri: vi-foundry/genealogy-models
owner: edphos
status: living
updated: 2026-08-17
---

# Genealogy Models — Runnable Precursor Environments

Each stage in the mathematical genealogy of the VI formula is implemented as a
runnable simulation that **generates data from the equations of that era**.
The genealogy is not prose — it is executable code that reproduces the
behavior of each precursor environment.

## Stages

| Stage | Environment | Equation | Output |
|-------|-------------|----------|-------|
| 1 | Ising (1925) | H = -J Σ σᵢσⱼ - h Σ σᵢ | Magnetization vs T/Tc |
| 2 | Landau mean-field (1937) | F(M) = aM² + bM⁴ + hM | Free energy landscape |
| 3 | Thom cusp (1972) | V(x) = ¼x⁴ + ½ax² + bx | Bifurcation diagram |
| 4 | Percolation on networks | Z(S) = {v : dep(v) ⊆ S} | Zero-dependency fraction vs provision |
| 5 | Drift-selection boundary | P(retain|δ>0) - P(retain|δ=0) | ρ_sat from population genetics |
| 6 | VI formula | ρ(θ) = ρ_sat · H(θ - θ*) | Step function |

Each stage produces a data frame with known ground-truth parameters,
following the simulacrum protocol (Cartwright 1983). The chain is
compositional: each stage's output is the input to the next.
