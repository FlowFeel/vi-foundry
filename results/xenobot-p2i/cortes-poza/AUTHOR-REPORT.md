---
title: "Report to the Author — Critical / Important / Minor Issues"
to: Dr. Yuriria Cortés-Poza (IIMAS, UNAM)
re: "A Hybrid Mathematical Framework for Morphogenesis and Regeneration", J Math Biol (2026) 93:43
from: Flow (independent technical review, prepared for the editor of this line of work)
date: 2026-10-09
status: DRAFT — not sent (external action pending approval)
---

# Report to the Author — Cortés-Poza 2026, JMB 93:43

Thank you for the paper and for making the implementation public. This review verified the analytical results by hand and reproduced the numerical experiments from the repository. The framework is coherent and well-written, the mathematics checks out, and the open-problem/conjecture structure is exemplary practice. The issues below are ordered by severity. Section/figure references are to the published version.

## CRITICAL

**C1. §5.1, Experiment 1 — the energy-barrier formula is internally inconsistent.**
The text reads: "δ* ≈ √(2ΔU) = √(2 · a/4 (V0 − V−)²(V+ − V−)²) ≈ 1.74 (for a = 1.2, V± = ±1.5, V0 = 0)." For these parameters the printed expression evaluates to √(2 · 6.075) = **3.49**, not 1.74. The stated value 1.74 is correct only for the true barrier ΔU = 81a/64 ≈ 1.52 (as derived correctly in §7.1); the printed formula (a/4)(V0−V−)²(V+−V−)² = 6.075 overestimates ΔU by a factor of four. Please reconcile the formula with the value — as printed, the same sentence asserts both δ* ≈ 3.49 and δ* ≈ 1.74.

**C2. Seed count for Experiment 1 contradicts itself.**
§5.1 states "15 independent seeds per value of δ"; the Figure 2 caption states "30 seeds per δ value." One of these is wrong. Since the nucleation probability is a binary proportion, please also report the binomial interval (at ppat ≈ 0.53, 15 seeds gives an enormous CI).

**C3. The claim "the target morphology is never prescribed externally" is stronger than the protocol supports.**
In every experiment the target pattern is effectively loaded through the initial condition: Experiment 2 equilibrates a pre-built half-depolarized/half-hyperpolarized pattern; the polarity experiment initializes an explicit head-tail V± arrangement; the identity module Ii is initialized with a positional (head–tail) gradient. What the model demonstrates is that a pre-existing pattern is an *attractor* of the dynamics and is recovered after perturbation — a real and interesting property — but "not prescribed" overstates it. I suggest either re-wording to "the target pattern is an attractor of the dynamics given the initialized positional gradient," or adding an experiment showing a *specific* pattern arising from unprescribed (uniform) initial conditions. Note that Experiment 1 shows the opposite of specificity: noise-driven nucleation produces random domains, not a defined anatomy.

**C4. The central role of slow memory (ε) is asserted, not demonstrated.**
Remark 3 and §7.5 present slow tissue memory as the mechanism that makes attractor switching permanent. But the displayed experiment (A = 2.5, T_force = 12) shows BOTH regimes (τ_ε = 50 and τ_ε = 0.3) switching permanently. The discriminating role is claimed "clearest at near-threshold amplitudes" — yet no near-threshold memory-contrast experiment is shown. Either add the amplitude sweep that isolates the τ_ε effect near the basin boundary, or soften the claim to what is demonstrated.

**C5. "Recovery ... consistent with the Lyapunov analysis (Theorem 1)" overstates the theorem.**
Theorem 1 guarantees descent of E and convergence to *some* equilibrium — not to the pre-lesion pattern, and not pattern fidelity ≥ 0.95. The regeneration-robustness observation is valuable as a numerical result but is not licensed by the theorem. Please attribute it to the empirical dynamics (bistable pull-in) rather than to the Lyapunov result.

## IMPORTANT

**I1. Proposition 2 (absence of Turing instability) is a non-result as framed.**
The inhibitor P has no spatial coupling at all (Remark 4 concedes this), so no Turing instability is possible by construction — the "key reason" given in Remark 4 is the setup itself. Moreover, Remark 4 also concedes the result does not extend to the full model, where the interesting behavior lives. Listing this as one of the three headline analytical results gives it more weight than it carries. Consider demoting it to a remark and stating plainly: "the reduced subsystem cannot exhibit Turing-type patterning because the inhibitor is spatially local; whether the full system can is open."

**I2. The "structural robustness" claim is not demonstrated.**
"Qualitative results are structural and depend only on signs and timescale ordering" (for 40+ parameters) is asserted; the sweeps in the paper are illustrative, not a systematic sensitivity or bifurcation analysis. A parameter-perturbation study (e.g., randomized parameter ensembles preserving sign/timescale structure) showing the phase diagrams (Figs 2, 6, 8) survive would substantiate this — or the claim should be tempered.

**I3. The timescale separation is not as clean as stated.**
The paper emphasizes the hierarchy τ_V ≪ τ_W ≲ τ_G ≲ τ_GRN ≪ τ_ε, but the nominal table has τ_GRN = τ_G = 5 (equal, not separated), and the effective relaxation times are T_W = 4, T_GRN = 5, T_G = 50 — so the conductance layer actually relaxes ten times slower than the regulatory layer. The ordering claim and Table 3 should be made mutually consistent, or the hierarchy restated in effective times.

**I4. Reported integration step does not match the code.**
§5.1 states "dt = 0.01 in 1D, 0.02 in 2D"; the repository's validation experiments (validation_experiments.py) run 1D with dt = 0.05. Please make the paper and code consistent, and confirm the reported figures were produced with the reported dt (a dt-convergence check would settle it).

**I5. Scope of the numerical claims is 1D micro-chains.**
The robustness and attractor claims are demonstrated on 1D chains of N = 16–30 cells with few seeds (n = 3–15). The 2D square lattice is implemented but barely exercised in the shown results, and planaria are 2D/3D tissues of ~10⁵–10⁶ cells. Please scope the claims explicitly ("demonstrated for 1D chains of 16–30 cells") or add 2D/N-scaled results.

**I6. Signature phenomena are not simulated.**
The Introduction motivates the framework with four observed planaria phenomena: tiny-fragment regeneration (1/279th), the octanol/gap-junction-blockade two-headed worm, and transient-depolarization reprogramming. Of these, only transient-current polarity reversal is simulated (and at 70% lesion, well above the 1/279th scale). The two-headed/octanol result — arguably the most cited Levin-lab phenomenon and directly relevant to your adaptive-G mechanism — is not shown. Either simulate it or explicitly list it as future work; the gap between motivation and demonstration is currently wide.

**I7. Small seed counts in Experiments 3–4.**
Figure 3 uses n = 6 seeds; the σ_G and energy comparisons would be much more convincing with ≥ 20–30 seeds and error bands reported.

## MINOR

**M1.** §7.2 Remark 8's "|Λ|/(C‖V̇‖²) < 1 throughout" is a numerical observation; please label it as such (it is currently phrased structurally).

**M2.** Proposition 2's printed intermediate determinant "(−λ0 + Gμk)(−ρP)/C" is dimensionally inconsistent with the stated matrix entry (−λ0 + Gμk/C); the final formula is correct — a typesetting slip.

**M3.** How the δ(t − t0) impulse in Eq. (15) is realized in the RK4 integration (as a reset at lesion time?) is not stated; a sentence in §5.1 would remove ambiguity.

**M4.** State N consistently: §7.5's polarity description omits N; Figure 6 caption gives N = 16; §7.6 basin text omits N. The main text should state each experiment's N and G0 in one place (Table 3's footnote already tries; please complete it).

**M5.** The repository is GitHub-only with no persistent identifier. For a published methods paper I recommend archiving a versioned copy (e.g., Zenodo DOI) so the implementation is permanent and citable.

**M6.** Conjecture 3's "A*(12) < 2.5" and the flatness of A*(T_force) for T_force ≳ 6 rest on a 6×6/10×10 grid; the "approximately independent of T_force" phrasing deserves the word "indicatively."

## Closing note

The analytical content verified cleanly, the framework is a genuinely useful addition to the attractor-based bioelectric program, and the public implementation is a strong reproducibility asset. The critical items are internal-consistency fixes (C1, C2) and honest re-scoping (C3–C5) — none require new biology, only tighter claims or the missing experiments that would support them. I would be glad to see a revised version.

---
*Prepared as a draft for the requester. Not sent. Basis: full-text read, hand-verification of all analytical results, and a reproduction run against the public repository.*