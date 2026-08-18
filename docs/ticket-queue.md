---
uri: vi-foundry/ticket-queue
owner: edphos
status: living
updated: 2026-08-18
---

# VI Foundry — Ticket Queue

## Design Principles

1. **One generator per file.** No monoliths. No mere scripting.
2. **Pure functions (A1).** Seeded determinism (A2). Proof objects (A6).
3. **Solver separation.** Math decoupled from I/O.
4. **Compositional chain.** Each stage's output feeds the next.
5. **Honest claims.** Simulacra test what the paper claims. If a claim fails, the paper changes.

---

## T1: Fix pre-existing test failures
**Problem:** `test-unit-speculative.R:297,302` — `generate_dd_series` missing.
**Fix:** Implement `generate_dd_series(n, slope, n_points, feedback, seed)` in `R/speculative.R` or mark tests as skipped if the function was intentionally removed.
**Effort:** Small.

## T2: ρ_sat from drift-selection
**Problem:** Paper claims ρ_sat ≈ 0.35 is "empirically observed, proposed as drift-selection boundary." Never tested whether the Wright-Fisher simulator actually produces ~0.35.
**Design:** Run `generate_drift_selection` with realistic parameters (N=100-1000, delta=0.01-0.1, n_reps=5000). Measure ρ_sat. If ≠ 0.35, the label is wrong.
**Output:** Data + test. Paper updated if claim fails.
**Effort:** Small.
**Depends on:** None.

## T3: Small-n discrimination
**Problem:** AIC = −11.01 vs −9.46 is on 3 data points. Can 3 points distinguish a step from a sigmoid?
**Design:** Generate step data with n=3,5,10,20,40. Run step-fitter. Plot delta_AIC vs n. Find the minimum n where step wins decisively (delta_AIC > 2).
**Output:** Simulacrum + parametrized test. 
**Effort:** Small.

## T4: Landau→Step pipeline
**Problem:** Paper claims "consistent with Landau mean-field theory." Never tested whether Landau mean-field data, run through the step-fitter, recovers a step.
**Design:** Generate data from F(M)=aM²+bM⁴ (Landau), normalize to (theta, rho) space, run step-fitter. Does it recover a step? At what a-range does the step appear?
**Output:** New generator `generate_landau_step.R` + test.
**Effort:** Small.

## T5: Percolation — repair or remove
**Problem:** Simulacrum found θ* ≠ 0 for connected networks. Paper says "proposed (proof sketch)."
**Options:**
- (a) Find the right graph-theoretic condition. Candidate: site percolation threshold on the dependency network, which depends on min-degree/density, not connectivity.
- (b) Reframe: θ* ≈ 0 is an empirical observation (Sodalis at θ=0.044), not a percolation result. Drop the percolation argument.
- (c) Test on real metabolic networks (E. coli, Buchnera) — do they have the structure that gives θ* ≈ 0?
**Decision needed:** Which path?
**Effort:** Medium if (a) or (c); Small if (b).

## T6: Ising→Landau formal verification  
**Problem:** Paper claims formal algebraic identity between Ising mean-field and Landau. The derivation is in the genealogy docs but not verified numerically.
**Design:** Write the partition function expansion. Show that Z = Σ exp(−βH) reduces to F(M) = aM² + bM⁴ in mean-field. Verify: (a) algebraically in the docs, (b) numerically — does the Ising MC data match the Landau prediction near Tc?
**Output:** Updated genealogy doc + numerical comparison test.
**Effort:** Medium.

## T7: Extended simulacra for GitHub Pages
**Problem:** Foundry site needs extended simulacra showing the math is real.
**Design:** New pages:
- `docs/ising.md` — Ising MC visualization (magnetization vs T/Tc)
- `docs/landau.md` — Landau free energy landscape
- `docs/cusp.md` — Cusp bifurcation diagram
- `docs/genealogy-chain.md` — Compositional chain: Ising→Landau→Cusp→VI
Each page: embedded generator, plot, parameters, null control.
**Effort:** Medium.

## T8: Banking — upcycle model (Bagehot→Marx→equations)
**Problem:** Ed's banking program. Model the upcycle from first principles.
**Design:**
- State variables: P_K (capital goods price), P_c (consumer goods price), quasi-rents Q, credit volume D, wage bill W, employment λ.
- Equations: Goodwin predator-prey (dω/dt, dλ/dt) + Minsky debt accumulation (dD/dt).
- Upcycle focus: P_K > P_c, credit expansion, three financing postures emerge.
- Collapse is downstream: Ponzi→Speculative→Hedge re-coupling.
- Start from Bagehot's Lombard Street, not Minsky.
**Output:** New generator `generate_upcycle.R` + simulacrum + test.
**Effort:** Large.
**Depends on:** T2 conceptually (ρ_sat as drift-selection boundary may appear in credit dynamics).

## T9: Genealogy — cusp→percolation mapping
**Problem:** Genealogy docs label this connection "structural analogy." Chain has a gap between cusp and percolation.
**Options:**
- (a) Make it formal: show that the cusp bifurcation set describes the percolation transition on specific network topologies.
- (b) Drop the connection. The chain is Ising→Landau→Cusp→VI, with percolation as a separate empirical observation (θ* ≈ 0 measured, not derived).
**Decision needed:** Which path?
**Effort:** Medium if (a); Small if (b).
**Related to:** T5.

---

## Status

| Ticket | Status | Assigned |
|--------|--------|----------|
| T1 | Ready | — |
| T2 | Ready | — |
| T3 | Ready | — |
| T4 | Ready | — |
| T5 | Blocked (decision needed) | — |
| T6 | Ready | — |
| T7 | Ready | — |
| T8 | Ready (large) | — |
| T9 | Blocked (decision needed) | — |

## Dependencies

```
T2 ──┐
     ├── T8 (banking)
T3 ──┘
T4 ── T6 (formal verification)
T5 ── T9 (percolation/cusp mapping)
```
