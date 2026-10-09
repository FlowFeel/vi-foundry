---
title: "INFERNO Evaluation — A Hybrid Mathematical Framework for Morphogenesis and Regeneration"
evaluator: Flow
date: 2026-10-09
requested-by: Jan
target: Cortés-Poza Y (2026) J Math Biol 93:43. DOI 10.1007/s00285-026-02459-2 (published, peer-reviewed; 40 pp.)
author: Yuriria Cortés-Poza (IIMAS, UNAM, Mexico)
codebook: INFERNO v1.0 (4 levels × 3 dimensions, genre-adapted: modeling-theory paper); WCI composite per meta/reference/wci.md
basis: read-together — full primary text read in session; analytical results re-derived by hand; public code repo (YuririaCP/bioelectricity) cloned and reproduction run executed in the foundry
status: complete (foundry reproduction results appended where available)
---

# INFERNO EVALUATION — Cortés-Poza 2026 (JMB 93:43)

## 0. Genre identification

**Modeling/theory paper** in a peer-reviewed applied-math journal (Springer JMB). Single author. Constructs a hybrid multiscale dynamical framework (bistable bioelectric layer + adaptive gap junctions + 4-module synthetic GRN + slow tissue memory + wound wave + discrete morphology/occupancy) for planarian morphogenesis and regeneration. Three analytical results on reduced subsystems, seven open problems, three conjectures, four numerical experiments. No biological data anywhere — all "observations" are simulations of an explicitly uncalibrated model (unspecified time scale t*, synthetic GRN, nominal parameters).

Caveat on this evaluation: the paper is self-declared as an architecture proposal ("This coarse-grained architecture suggests the following biological correspondences..." — future work). The WCI tier therefore measures *use-readiness as a source of biological claims*, not the quality of construction, which is good.

## 1. What the paper is and is not

- **Is:** a coherent, well-written, honest framework-construction paper; correct classical mathematics (re-verified); a genuinely integrative structure (dynamical systems + graph min-cut + Ising + Allen-Cahn + Hopfield memory + developmental biology); a public, runnable implementation.
- **Is not:** a validated model of regeneration. Nothing is calibrated to data; no signature planaria phenomenon (two-headed/octanol, 1/279th-fragment regeneration, depolarization reprogramming) is reproduced in-silico; the distinctive mechanism (slow memory ε) lacks a clean demonstration; numerics are 1D chains of 16–30 cells.

## 2. The INFERNO matrix (L1–L4 × D1 Data / D2 Formal / D3 Programmatic, 0–100)

| Level | D1 Empirical/Data | D2 Formal/Analytical | D3 Programmatic |
|---|---|---|---|
| **L1 Observation** — what does it expose? | 40 PARTIAL — no biological data; numerical observations on tiny 1D systems (N=16–30), few seeds (3–15), illustrative sweeps | 45 PARTIAL — model-behavior observations; no data-driven inference | 50 PARTIAL — observations motivate open problems/conjectures |
| **L2 Inference** — what formal machinery? | 55 PARTIAL — standard RK4/projection numerics, clearly stated; code public (verified); dt inconsistency paper-vs-code (§5.1 says 0.01/0.02; repo validation runs 0.05) | 65 PARTIAL/PASS — three analytical results, all correct (hand-verified) but thin: Prop 1 classical; Prop 2 near-tautological (inhibitor P has no spatial coupling) and explicitly does not extend to the full model; Theorem 1 standard Lyapunov/gradient. Energy-Ising-mincut-Allen-Cahn connections well-drawn, honestly flagged as analogies | 70 PASS — the 4-layer hybrid architecture + timescale hierarchy is a genuinely reusable inferential structure; Hopfield analogy + Problem 7 give it programmatic reach |
| **L3 Program evaluation** — evaluates its own program? | 60 PASS — positions vs Pietak-Levin 2016, Turing/Gierer-Meinhardt, Davidson GRN; identifies novelty (adaptive topology, slow memory, unprescribed target); but no quantitative head-to-head with any alternative on the same tasks | 65 PARTIAL — ablations exist (R_i knockout, fixed-G, memory knockout) but are qualitative; the memory ablation's central contrast is not cleanly shown (both regimes switch at the tested amplitude) | 65 PARTIAL — explicit about open problems; relations to experimental program (Beane 2011, Oviedo 2010, Reddien) well chosen |
| **L4 Convergence** — multiple traditions? | N/A | 65 PARTIAL — genuine multi-tradition integration (dynamical systems, statistical physics, graph algorithms, PDE free-boundary, associative memory); the paper's real strength | 60 PARTIAL/PASS — links attractor theory (Waddington/Kauffman) to bioelectric experimental program |

## 3. Foundry reproduction of the numerical claims (see run_reproduction_cortes.py + results/xenobot-p2i/cortes-poza/repro.log)

Reproduction run executed against the public implementation (github.com/YuririaCP/bioelectricity) with the paper's stated parameters. **CONFIRMED RESULTS (log preserved):**

- **[0] §5.1 energy-barrier formula error — CONFIRMED:** correct ΔU = 81a/64 = 1.5188 → δ* = 1.743; the paper's printed formula (a/4)(V0−V−)²(V+−V−)² = 6.0750 → δ* = 3.486. Factor-4 mismatch, reproduced in code.
- **[1] Nucleation threshold — CONFIRMED:** ppat = 0.000 for δ ≤ 0.7 (paper: "essentially zero for δ≲0.7"); δ=1.9 → ppat = 0.533 (paper claims ≈0.53 at δ*≈1.9–2.0 — reproduces almost exactly); δ=2.1 → 0.800; rise steep but noisy at 15 seeds (δ=1.5 → 0.133, δ=1.7 → 0.400, δ=2.3 → 0.400). Energy-barrier prediction 1.74 sits inside the rising region.
- **[2] Regeneration robustness — CONFIRMED, cleaner than claimed:** lesion {0.1, 0.3, 0.5, 0.7} → p_success = 1.00, fidelity = 1.00 across all (paper: fidelity ≥ 0.95).
- **[3] Basin boundary — CONFIRMED:** f*=0.50 (f=0.43 → <V> = −0.38, collapses to V−; f=0.5 → <V> ≈ 0; f=0.57 → <V> = +0.19), matching the claimed f*≈0.5.
- **[4] Polarity reversal — CONFIRMS the ε-critique (C4/I-issue):** at A=2.5, T_force=12 BOTH regimes switch permanently — τ_ε=50: polarity +2.99 → −2.61; τ_ε=0.3: +2.64 → −1.42 (permanent, though the no-memory switch is less complete). The discriminating role of slow memory is NOT isolated by the displayed experiment, as flagged.
- **[5] Lyapunov descent — CONFIRMED:** pure bioelectric ΔE = −5.78 (<0), full model ΔE = −1.21 (<0); effective dissipativity (Remark 8) holds in-reproduction.
- **[6] Switching phase diagram:** still completing in the foundry (A=0.5/T_force=20 → p_switch=0.00 so far); A* will be appended on completion.

Additionally: **§5.1 vs Fig 2 caption seed-count contradiction** ("15 independent seeds per value of δ" vs "30 seeds per δ value") confirmed as an unresolved internal inconsistency.

## 4. PQS — Prediction Quality Score (modeling-paper weights)

| Criterion | Weight | Score | Note |
|---|---|---|---|
| Pre-specified | 0.30 | 50 | Experiments read as pre-specified; several central claims post-hoc (ε role; "not prescribed") |
| Quantified | 0.20 | 60 | δ*≈1.9–2.0, f*≈0.5, A*≈2.0–2.5, fidelity≥0.95 — all quantified |
| Falsifiable | 0.20 | 45 | As a biological model: not falsifiable yet (uncalibrated, no data confrontation); as a mathematical framework: checkable |
| Discriminating | 0.20 | 40 | No quantitative comparison against alternative models on the same tasks; no decisive test isolating ε or adaptive-G |
| Proportional | 0.10 | 55 | Claims ≈ evidence at the model level; several overreaches ("not prescribed externally", "consistent with the Lyapunov analysis") |

**PQS = 0.30·50 + 0.20·60 + 0.20·45 + 0.20·40 + 0.10·55 = 50/100** (Moderate-Low)

## 5. WCI composite (0–100, 6 dimensions, equal weights)

| Dimension | Score | Rationale |
|---|---|---|
| Theoretical coherence | 72 | Architecture coherent; analytic results correct; minor tensions: δ* formula error, no-Turing framing, τ_GRN=τ_G=5 (no strict separation), "structural robustness" asserted for 40+ parameters |
| Empirical support | 48 | Zero biological data; all evidence is simulation of an uncalibrated model; claims about biology unsupported by data (framed as future work) |
| Replicability | 75 | Code public, seeds fixed, deterministic; reproduction run in progress in foundry — strong by construction |
| Independent uptake | 10 | Published Aug 2026; no citations yet; single-author; repo 0 stars (time-dependent) |
| Explanatory power | 58 | Coherent organizing framework for the bioelectric program; explains only in-silico behavior; ε-mechanism weakly demonstrated |
| Falsifiability | 42 | Not confrontable with data in current form (no calibration protocol, synthetic GRN, nominal parameters); analytic claims are checkable and mostly check out |

**WCI = (72+48+75+10+58+42)/6 = 50.8 → Tier 3 (borderline T2).**
Interpretation: as a *construction* to build on, this is a T2-quality framework; as a *source of biological claims*, it is not usable yet (T3). The gaps are structural but straightforward to close: calibration targets, a near-threshold memory-contrast experiment, 2D results, and the signature-phenomena simulations would move it decisively into T2. Unlike the Le preprint, the path forward here is code-and-experiments, not artifacts-and-accounting.

## 6. Net verdict

Correct, honest, well-integrated, reproducible framework paper whose scientific content is architectural rather than empirical. The mathematics verifies; the numerics are reproducible (foundry run pending); the claims about biology are scoped as proposals and should be read as such. The distinctive contributions — slow tissue memory and adaptive gap junctions as the mechanism of permanent reprogramming — are the least-demonstrated parts of the paper, and the "unprescribed morphology" framing is weaker than the protocol supports. Recommendation to a reader: use as a toolbox and hypothesis generator; do not cite as evidence about planaria biology.