---
uri: vi-foundry/ticket-queue
owner: edphos
status: living
updated: 2026-09-05
---

# VI Foundry — Ticket Queue

## Design Principles

1. **One generator per file.** No monoliths. No mere scripting.
2. **Pure functions (A1).** Seeded determinism (A2). Proof objects (A6).
3. **Solver separation.** Math decoupled from I/O.
4. **Compositional chain.** Each stage's output feeds the next.
5. **Honest claims.** Simulacra test what the paper claims. If a claim fails, the paper changes.
6. **Formula alignment.** All tickets serve the relaxation formula dρ/dt = −k₁(ρ − ρ₁) − k₂(ρ − ρ₂), not the deprecated step function ρ(θ) = ρ_sat · H(θ − θ*).

---

## Resolved Tickets (T1–T9)

### T1: Fix pre-existing test failures — ✅ DONE
`generate_dd_series` implemented in `R/speculative.R`. Suite green.

### T2: ρ_sat from drift-selection — ✅ DONE (FALSIDIED)
Wright-Fisher simulation (`inst/genealogy/measure_rho_sat.R`) tested ρ_sat across N ∈ {100, 500, 1000} × delta_range ∈ {[0,0.01], [0,0.05], [0,0.1]}. **Result:** ρ_sat varies from ~0.0 to ~0.99. The value 0.35 is not recovered. Closest: 0.247 (N=1000, delta=[0,0.05]). The ρ_sat ≈ 0.35 claim is not supported by the simulation. Paper updated to relaxation formula — ρ_sat is no longer a parameter.

### T3: Small-n discrimination — ⚠️ STALE (SUPERSEDED)
Step-vs-sigmoid discrimination on n=3 points. Under relaxation formula, the cross-sectional question is bi-exp vs mono-exp vs breakpoint. **Covered by foundry Simulacrum 4** (discrete levels → step) and the island bird analysis (breakpoint model preferred, ΔAICc = 18.2). No further work needed.

### T4: Landau→Step pipeline — ⚠️ STALE (NEEDS REFRAMING)
Was: does Landau data run through step-fitter recover a step? Under relaxation formula: does Landau mean-field data, interpreted as relaxation toward equilibrium, produce bi-exponential decay? This is T11 (relaxation simulation). Reframed ticket created as T11.

### T5: Percolation — repair or remove — ❌ OBSOLETE
Percolation θ*=0 claim falsified. Genealogy doc already warns: "percolation and drift-selection links have been tested and do not hold." Dropped. The relaxation formula does not require a percolation threshold.

### T6: Ising→Landau formal verification — ⚠️ STALE (NEEDS REINTERPRETATION)
Algebraic identity is valid (Ising mean-field = Landau free energy). But the chain was framed as phase transition → step function. Under relaxation formula, the chain describes relaxation dynamics: Landau free energy defines the potential well; the Landau-Lifshitz equation is the time-dependent relaxation toward that well. This is the relaxation ODE itself. Reframed in T10.

### T7: Extended simulacra for GitHub Pages — ⚠️ STALE (NEEDS RELAXATION CONTENT)
GitHub Pages simulacra should show relaxation formula content: bi-exp fits, cross-kingdom parameter transfer, substrate independence. The existing simulacra 9-13 (Python) cover this. R/viz.R would need updating. Deferred until T13 (R package update).

### T8: Banking — upcycle model (Bagehot→Marx→equations) — ✅ KEEP
Independent of formula change. Ed's banking program. State variables: P_K, P_c, Q, D, W, λ. Goodwin predator-prey + Minsky debt accumulation. Start from Bagehot's Lombard Street. Effort: Large.

### T9: Genealogy — cusp→percolation mapping — ❌ OBSOLETE
Percolation link broken (T5). Cusp catastrophe still valid as the potential landscape, but the connection to percolation theory is not supported. Dropped.

---

## Active Tickets (T10–T15)

### T10: Rewrite genealogy doc for relaxation formula
**Problem:** `mathematical-genealogy.md` (3,500 words) presents the step function ρ(θ) = ρ_sat · H(θ − θ*) as the formula. The monograph has moved to dρ/dt = −k₁(ρ − ρ₁) − k₂(ρ − ρ₂). The Ising → Landau → Cusp chain is valid but framed as phase transition dynamics; it should be framed as relaxation dynamics.

**Design:**
- Keep stages 1–3 (Ising, Landau, Cusp) with reinterpretation: the Landau free energy defines the equilibrium well; the Landau-Lifshitz equation dM/dt = −∂F/∂M is the relaxation ODE — same form as our formula.
- Archive stages 4–5 (percolation, drift-selection) as historical hypotheses that were tested and falsified. Keep the code; label honestly.
- Add new stage 5 (was 6): the relaxation formula as synthesis. Show that the Landau-Lifshitz relaxation equation with two channels (fast + slow) IS our formula.
- Update the chain diagram: Ising → Landau → Cusp → Relaxation (drop percolation and drift-selection from the active chain).

**Output:** Rewritten `mathematical-genealogy.md`.
**Effort:** Medium.
**Depends on:** T14 (honest labels first).

### T11: Add relaxation simulation (genealogy stage 6)
**Problem:** No code simulates dρ/dt = −k₁(ρ − ρ₁) − k₂(ρ − ρ₂) in the genealogy chain. The existing scripts simulate Ising (static equilibrium), Landau (static free energy), Cusp (bifurcation), but not the actual relaxation dynamics.

**Design:**
- New script `generate_relaxation.py` (or `.R`) that:
  1. Generates bi-exponential decay data from the formula with known k₁, k₂, ρ₁, ρ₂
  2. Shows two-phase decay: fast phase (k₁) shedding, slow phase (k₂) erosion
  3. Fits bi-exp, mono-exp, and linear; computes AIC comparison
  4. Produces proof object: parameter recovery within tolerance
- Compositional: feeds from the Cusp stage — the cusp potential defines the equilibrium well; relaxation is the trajectory toward it.
- Follows simulacrum protocol: seeded, deterministic, ground-truth known.

**Output:** `inst/genealogy/generate_relaxation.py` + test.
**Effort:** Small.
**Depends on:** T10 (goes in rewritten genealogy doc).

### T12: Port R genealogy scripts to Python
**Problem:** 6 R scripts in `inst/genealogy/` are solid code (real Metropolis MC, real Wright-Fisher), but the rest of the foundry is Python. Two-language stack creates friction for reproducibility and INFERNO Labs registration.

**Design:**
- Port `generate_ising.R` → `generate_ising.py` (Metropolis MC on 2D lattice)
- Port `generate_landau.R` → `generate_landau.py` (free energy minimization on M grid)
- Port `generate_cusp.R` → `generate_cusp.py` (cubic root finding, bifurcation set)
- Port `generate_drift_selection.R` → `generate_drift_selection.py` (Wright-Fisher)
- Keep R versions as reference implementations in `inst/genealogy/reference/`
- Include T11 (new relaxation simulation) as Python-native

**Output:** Python genealogy suite in `inst/genealogy/` (or `scripts/genealogy/`).
**Effort:** Medium.
**Depends on:** T11 (include relaxation stage in the port).

### T13: Update R package for relaxation formula
**Problem:** R package has 22 source files, 31 test files, ~9,000 lines, 443 tests passing. Core modules reference the old step-function formula:
- `fit_step.R` fits the step function — needs `fit_biexp.R` equivalent
- `formal_model.R` implements the threshold model — needs relaxation ODE
- `economics_formula.R` may reference old formula
- `cusp_catastrophe.R` — still valid but context changes
- `proofs.R` — needs relaxation formula proofs

**Design:**
1. Audit all 22 R files for step-function dependencies
2. Add `fit_biexp.R` alongside `fit_step.R` (don't remove — keep for reproducibility)
3. Add `relaxation_model.R` alongside `formal_model.R`
4. Update tests: add bi-exp tests, keep step-function tests as regression
5. Verify 443 tests still pass; add new tests for relaxation formula

**Output:** Updated R package, all tests green, relaxation formula supported.
**Effort:** Large.
**Depends on:** None (independent of T10-T12).

### T14: Honest provenance labels on genealogy stages
**Problem:** Genealogy stages 4–5 (percolation θ*=0, drift-selection ρ_sat≈0.35) are falsified by the foundry's own simulations but still presented without clear labeling in some contexts.

**Design:**
- Stage 1 (Ising): valid, label as "relaxation dynamics precursor"
- Stage 2 (Landau): valid, label as "equilibrium landscape"
- Stage 3 (Cusp): valid, label as "bifurcation geometry of relaxation"
- Stage 4 (percolation θ*=0): falsified, label as "historical hypothesis — tested in T2, not supported by simulation"
- Stage 5 (drift-selection ρ_sat≈0.35): falsified, label as "historical hypothesis — tested in T2, not supported by simulation"
- Stage 6 (relaxation formula): current formula, supported by 8/8 predictions

**Output:** Updated labels in `inst/genealogy/README.md` and `docs/mathematical-genealogy.md` header.
**Effort:** Small.
**Depends on:** None.

### T15: INFERNO Labs transposition — genealogy as registered pipeline
**Problem:** Genealogy simulations are R scripts in a directory. For INFERNO Labs, each stage should be a registered, versioned, DOI-trackable artifact with provenance chain.

**Design:**
- Each genealogy stage becomes an INFERNO Labs registered simulation:
  - Stage 1: Ising MC → registered with seed, params, output hash
  - Stage 2: Landau free energy → registered computation
  - Stage 3: Cusp bifurcation → registered computation
  - Stage 6: Relaxation formula → registered simulation
- Provenance chain: each stage's output is input to the next
- DOI-trackable: each stage gets a Zenodo DOI on archive
- Reproducibility: anyone can re-run the chain from Ising to relaxation with one command

**Output:** INFERNO Labs registered pipeline for the genealogy chain.
**Effort:** Medium-Large (depends on INFERNO Labs registration infrastructure).
**Depends on:** T12 (Python versions needed for registration).

---

## Resolved Tickets (T16–T21): INFERNO Lab Registrations

### T16: ASJP bimodality BIC test — ✅ DONE (FALSIFIED — registered negative)
`inferno-asjp-175.md` (2026-09-05). The ΔBIC = +175.3 "bimodal" result promoted the §5.10 linguistics row to Quantitative; the corrected analysis reverses it.

**Result:** 1-component Gaussian preferred (ΔBIC = −8.45). The bimodality label is false.

**Bug:** hand-rolled EM omitted the 1/√(2π) normalization constant, inflating the 2-component BIC by ~183.8 units (`gauss_ll()` included the factor; the E-step `p1`/`p2` scaled by `exp(-0.5*((x-mu)/s)^2)/(s+1e-9)` did not — EM converged to a bogus optimum). Class labels were an artifact.

**Action:** withdrawn from paper (§5.10 Quantitative → Qualitative, 2026-09-05). Registered as a negative per the labbook's inference-honesty protocol. Surviving corrected prediction: graded deceleration with Pagel-core at the conserved end, carried by T17.

### T17: Graded-ordering survival + bird cross-kingdom battery — ✅ DONE
`bird-blind-scoring-results.md` (2026-09-05). Three-part registration from Jan's directives (blind scoring, functional-dependency candidates, phylo trait fit), all material in hand (8 scored structures, non-flight role lists, >60 flight-loss events, Livezey 2003 / Wright, Steadman & Witt 2016).

1. **Blind-scoring ensemble (non-blindness discharged):** 2,000 simulated raters given only published non-flight role lists recover the dependency→loss-order relationship. Ensemble mean ρ = 0.668, 95% CI [0.310, 0.905], 99.9% positive, author's 0.755 inside the CI.
2. **Functional-dependency candidates:** graded metrics carry the ordering — multiplicity ρ = 0.752, grade ρ = 0.755, peripheral-weighted ρ = 0.755; binary flight-specificity FAILS (ρ = −0.577). The continuum prediction is itself supported: graded works, categorical fails.
3. **Phylo-style trait fit (rank-based):** permutation p = 0.0211 (10,000 draws).

Verdict: the ordering is not an artifact of the author's scoring; the graded (biphasic) form survives, the binary form is falsifiable-and-failed.

### T18: Wright 2016 supplement acquired + reallocation registration — ✅ DONE
`data/wright2016/` (2026-09-05). Acquired the Wright, Steadman & Witt 2016 PNAS paper + supplement (42 pp, wrightlab.org), decrypted, extracted (`wright2016-full.txt`), full Table S1 analyzed (`wright2016-results.md`).

**Result:** 15 focal taxa, **all 15 negative** keel↔tarsometatarsus slopes (forelimb→hindlimb reallocation), 13/15 significant; sign test P = 3.05×10⁻⁵, binomial P(≥13 sig) = 1.17×10⁻¹⁵. ~1,590 specimens. Median slope −0.88. This is external, specimen-level, quantitative confirmation of the outbound reallocation gradient.

**Critical correction to T17/paper:** the monograph's "n = 15" is **15 focal TAXA** (Wright's families/genera), NOT 15 scored skeletal structures. The ocal scored set is 8 structures. The supplement contains NO per-structure loss-order data — continuous morphology only (keel, coracoid, humerus, femur, tarsometatarsus). The full OU fit still requires per-event loss-order data, which Wright 2016 does not provide; Livezey 2003 (Ornithological Monograph 53) is the source, but paywalled/print and its morphological phylogeny is contested by molecular work (García-R et al. 2014).

**Reporting decision:** Wright reallocation → paper (external quantitative cross-domain anchor). The n=15-vs-8 correction → lab notebook + paper wording fix (state n = 8 scored structures; cite Wright's 15 taxa as the reallocation sample, not the ordering sample).

### T19: R1 cavefish independent-metric test — ⚠️ WITHDRAWN → REBUILT (T21), MIXED
*Original registration (2026-08-24):* `vi-foundry/results/r1-cavefish-sequence/r1-results.md` — STRING degree (string-db.org, zebrafish orthologs, 22 genes / 4 categories) did NOT predict cavefish trait-loss order (ρ = −0.013, p = 0.956; permutation p = 0.521), claimed reverse of VI prediction.

**Re-audit (`r1-audit.md`, 2026-09-05 — Jan's challenge, INFERNO-style):** the registered negative is **not clean** and is **withdrawn as interpreted**:

1. **Labeling confound:** the "loss_timing" rank is actually **developmental expression onset (hpf)** — 10hpf/24hpf/36hpf/72hpf+ — NOT evolutionary trait-loss order. The dependent variable measures the wrong thing for the claim.
2. **Category-block artifact:** only 4 distinct rank values assigned to 4 whole categories (pigment=1, eye=2–3, circadian=4, metabolic=4). Within-category degree variance is huge (eye: 28–225; pigment: 58–229) yet labels are shared. Effective n ≈ 4 categories, not 22 genes.
3. **Design inversion:** the recast R1 design called for developmental timing as an INDEPENDENT integration-depth metric; execution used it as the DEPENDENT variable.
4. **Provenance gap:** no citations for gene inclusion or rank assignment in the TSV.

**Status:** withdrawn as an independent-metric falsification; re-queued as needs-rebuild (loss-order labels must come from cave-population comparative data, e.g. E7 raw-traits dataset, not hpf onset). No active paper claim depends on R1, so nothing falls — but the foundry record now says what it can and cannot support. E7 (raw trait regression, WCI 79) is NOT implicated.

### T21: R1 rebuild on proper ground — ✅ DONE (mixed result)
`vi-foundry/results/r1-cavefish-sequence/r1-rebuild.md` (2026-09-05). Rebuilt with proper design: dependent variable = actual regression magnitude from the E7 cave-population age gradient; documented gene sets (eye: Jeffery 2009/Yoshizawa 2012; pigment: Jeffery 2009; sleep: Jaggard 2018 — hcrt causal); STRING re-queried live with defined degree protocol (partner count at combined score ≥ 0.4, Danio rerio 7955).

**Result — MIXED:**
- Sleep-first onset (0.77 at 7 kya) with the single causal gene hcrt at depth 0 — VI-consistent.
- Behavioral-leads-morphological direction (sleep 0.77 vs eye 0.55 at 7 kya) — VI-consistent direction, but n=2, p=0.333.
- Eye pathway (Jeffery 2009): lens crystallins (depth 1.3) earlier than regulators (1.5) — directional, but ρ=0.047, p=0.905, n=9.
- **Inconsistent:** pigment regresses early (0.95 by 20 kya) despite highest documented depth (4.4) — the same anomaly class that sank the original R1, now on proper grounds.
- Aggression never fully regresses (max 0.80 at 525 kya) — VI-plausible, unscored (no gene list).

**Lesson:** STRING PPI degree is not a good operationalization of integration depth for pleiotropic-but-lossable traits (pigment). Directional signals across three independent angles, but underpowered; the metric lesson (dependency depth in GRN, not PPI degree) constrains any future attempt.

### T20: Wright 2016 five-element VI scoring — ✅ DONE
`data/wright2016/wright2016-five-element-scoring.md` (2026-09-05). Scored the 5 skeletal elements Wright et al. measured (keel, coracoid, humerus, femur, tarsometatarsus) by VI functional multiplicity and tested against documented island reallocation directions.

**Result: 5/5 direction match** (VI score ≤ 1.5 → shrink; > 1.5 → grow). Spearman ρ = 0.889, p = 0.044 (n=5); sign test P = 0.031. Quantitative anchor for the extremes: Table S1 keel↔tarsometatarsus slopes 15/15 negative, 13/15 significant, median −0.88, ~1,590 specimens — external, hypothesis-free specimen-level data.

**Caveats (lab notebook):** n=5; keel + tarsometatarsus directional calls quantitative, coracoid/humerus/femur qualitative (text-documented). Spearman on 5 points fragile; sign test is the clean statistic.

**Reporting:** into paper §3.3 cross-domain table as a quantitative row alongside T18.

## Status

| Ticket | Status | Effort | Assigned |
|--------|--------|--------|----------|
| T1 | ✅ Done | — | — |
| T2 | ✅ Done (falsified) | — | — |
| T3 | ⚠️ Stale (superseded) | — | — |
| T4 | ⚠️ Stale → T11 | — | — |
| T5 | ❌ Obsolete | — | — |
| T6 | ⚠️ Stale → T10 | — | — |
| T7 | ⚠️ Stale → deferred | — | — |
| T8 | ✅ Keep | Large | — |
| T9 | ❌ Obsolete | — | — |
| T10 | **Ready** | Medium | — |
| T11 | **Ready** | Small | — |
| T12 | **Ready** (after T11) | Medium | — |
| T13 | **Ready** | Large | — |
| T14 | **Ready** | Small | — |
| T15 | **Ready** (after T12) | Med-Large | — |
| T16 | ✅ Done (falsified, registered negative) | Small | — |
| T17 | ✅ Done | Small | — |
| T18 | ✅ Done | Small | — |
| T19 | ⚠️ Withdrawn (rebuilt → T21) | — | — |
| T20 | ✅ Done | Small | — |
| T21 | ✅ Done (mixed) | Medium | — |

## Dependencies

```
T14 ── T10 (honest labels before rewrite)
T10 ── T11 (relaxation sim goes in rewritten genealogy)
T11 ── T12 (Python port includes relaxation stage)
T12 ── T15 (INFERNO needs Python versions)
T13 (R package — independent, large, can parallelize)
T8 (banking — independent, keep as-is)
```

## Recommended Execution Order

1. **T14** — Honest provenance labels (quick, unblocks T10)
2. **T10** — Rewrite genealogy doc for relaxation formula
3. **T11** — Add relaxation simulation
4. **T12** — Port R scripts to Python
5. **T13** — Update R package (large, parallelizable with T12)
6. **T15** — INFERNO Labs transposition
7. **T8** — Banking upcycle (independent, anytime)
