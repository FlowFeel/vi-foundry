# vi-foundry Math Refactoring Plan

**Author:** Ed Phillips ([@phosphene](https://github.com/phosphene))
**Date:** August 2026
**License:** MIT
**Status:** Proposal — awaiting go/no-go per phase

---

## Purpose

This is the execution plan for addressing the seven issues in
[`math-review.md`](math-review.md). For each issue it states the proposed
refactoring, the blast radius (tests / oracle / simulacra / docs touched), the
risk, and a recommendation. Issues are grouped into three phases ordered
safest-first, so each phase is independently shippable and the suite stays
green between phases.

A preliminary correction to the math review is recorded first, because it
changes the Issue 4 plan.

---

## Correction to `math-review.md` (Issue 4)

The math review stated `cusp_hysteresis_check` "cannot detect hysteresis by
construction" and is "always FALSE." **This was overclaimed.** The cusp
simulacrum passes `has_hysteresis = TRUE` because
`make_cusp_equilibrium_fn()` (in `inst/simulacra/generate_cusp_system.R`) is a
**stateful closure** — it uses `<<-` to track the previous state and follow the
nearest equilibrium branch across calls. So hysteresis *is* detected, but
through an **undocumented contract**: the caller must pass a stateful closure
that does branch-following via side effects. `cusp_hysteresis_check` itself
carries no state; with a pure `equilibrium_fn` (e.g. `function(x)
ifelse(x>0, x^2, -x^2)`) it returns `has_hysteresis = FALSE` always, which is
what the review observed.

The real defect is therefore a **misplaced contract**: the hysteresis logic
lives in the caller's closure, not in the function under test, and the
`@param equilibrium_fn` docstring implies a pure function (`Maps control value
→ equilibrium state`). The unit test never asserts `has_hysteresis = TRUE`
(only that `max_difference` is numeric), so unit coverage of hysteresis
detection is zero. `math-review.md` should be corrected to say "detects
hysteresis only via an undocumented stateful-closure contract; cannot detect it
with a pure equilibrium_fn" rather than "cannot detect by construction."

---

## Recommendations at a glance

| Issue | Severity | Proposed action | Phase | Risk |
|-------|----------|-----------------|-------|------|
| 2 — formal model docstring ODE | severe | **Fix docs** (add the `C_i` factor) | 1 | trivial |
| 1 — T7 sign error (naming) | severe | **Rename + fix docs** (`enrichment_ratio`→`depletion_ratio`) | 1 | low |
| 5 — T2 not a replication test | moderate | **Reframe claim** (family-mean correlation); defer per-family method | 1 | low |
| 3 — k1/k2 mislabeled | moderate | **Add `threshold_biphasicity` metric; demote k1/k2** | 2 | low |
| 6 — `sign` ≠ diversity-dependence | moderate | **Add real diversity-dependence metric; relabel `sign`→`growth_direction`** | 2 | medium |
| 7 — transfer_test one-draw null | minor | **Null distribution + `null_p`; reframe as ordering transfer** | 2 | low |
| 4 — cusp hysteresis misplaced contract | moderate | **Move branch-following state into the function** | 3 | medium |

**What we will NOT do now** (documented, not refactored):
- Per-family T2 slope analysis — small n per family (~6); defer to a method-design task.
- T3 cross-sectional method redesign — already documented as R6; needs within-lineage data.
- Loosening any oracle tolerance to hide drift.

---

## Phase 1 — Documentation & naming (no math change)

No function's math changes in this phase, so no simulacrum needs re-validation.
Field renames require lockstep test/oracle updates but no re-fitting.

### 1a. Issue 2 — Fix the formal model docstring ODE

**Change.** The header and `threshold_model()` docstring state
`dC_i/dt = -λ·M(t)·I(d_i < θ)` (no `C_i` factor — a linear ODE whose solution
is a nonsensical negative retention). The code actually integrates
`dC_i/dt = -λ·M(t)·C_i·I(d_i < θ)` (exponential), matching the closed-form
`retention_at_time()`. Correct the documented equation to include `C_i`.
Apply the same fix to `equilibrium_retention()`.

**Blast radius.** `R/formal_model.R` docstrings only. No code, no tests, no
oracle. Zero risk.

### 1b. Issue 1 — T7: rename `enrichment_ratio` → `depletion_ratio`, fix the claim

**Change.** The result is depletion (observed 0.364 < expected 0.617;
`enrichment_ratio = 0.589 < 1`), consistent with passive drift in unused genes.
The unit test already enforces `< 1` and is literally named *"depletion, not
enrichment."* Rename the value to match the math, and rewrite the docstring to
say "co-segregate **less** than chance (consistent with passive drift in unused
genes)" instead of "more than chance."

**Blast radius.**
- `R/empirical_tests.R` — rename field + rewrite `@section`.
- `tests/testthat/test-unit-empirical-tests.R` — update the field name and test
  label (the assertion `expect_lt(..., 1.0)` stays, now reading
  `depletion_ratio`).
- `R/viz.R` — the T7 viz docstring already says "significantly lower than"; fix
  any label using "enrichment."
- `baseline/oracle.yml` — update the T7 `prediction` text to "less than chance."
- `scripts/render_pages.R` — label text.

**Risk.** Low. No math change; the test already enforces the correct direction.

### 1c. Issue 5 — T2: reframe the claim to match the implementation

**Change.** `pgls_cross_family()` aggregates 91 species to 15 family means and
correlates those — a between-family association, not a within-family
replication test. Reframe the docstring and oracle to "family-mean plastome
size correlates with family-mean parasitism across independent parasitic
lineages." Update the oracle `n` to 15 (family-level) and mark the entry's
caveat. The per-family slope method is deferred (small n per family).

**Blast radius.**
- `R/empirical_tests.R` — `pgls_cross_family` docstring.
- `baseline/oracle.yml` — T2 `prediction` text and `n` (91 → 15, family-level).
- `tests/testthat/test-regression-baseline.R` — T2 stage unchanged (still runs
  the function); the oracle `n` change makes the skip reason honest.
- No dedicated T2 unit test exists (only regression + integration gates).

**Risk.** Low. Claim/doc change only.

**Phase 1 exit gate.** `make all` green; oracle T7/T2 framing honest; formal
model docstring matches the integrated equation.

---

## Phase 2 — Honest metrics & reframes (math stays, metrics added/relabelled)

The existing math is retained; we add correctly-named metrics and relabel
misleading ones. Oracle and test updates are lockstep. Because the formal model
and autocatalytic functions are deterministic, new oracle values are exact.

### 2a. Issue 3 — Add `threshold_biphasicity`; demote `k1_k2_ratio`

**Change.** `k1_k2_ratio` (≈281,000) is a temporal displacement ratio (ΔC in
the first 10% of time / last 90%), not a rate ratio of two phases; it is large
by arithmetic because the exponential decay finishes early. The genuine
biphasic signal is the **threshold gate**: protected traits (`d ≥ θ`) retain at
1.0, unprotected traits shed to ~0. Add:

```r
threshold_biphasicity <- mean(retention[protected]) - mean(retention[unprotected])
```

(≈ 1.0 when the gate works). Keep `k1_k2_ratio` but rename it
`early_late_displacement_ratio` and document it as descriptive (how completely
Phase 1 finished early), not as the biphasic signature.

**Blast radius.**
- `R/formal_model.R` — add the metric, rename the field, update `@return`.
- `baseline/oracle.yml` — formal_model entry: add `threshold_biphasicity: 1.0`,
  rename `k1_k2_ratio` → `early_late_displacement_ratio` (value unchanged).
- `tests/testthat/test-unit-formal-model.R` — rename the `k1_k2_ratio`
  assertion to `early_late_displacement_ratio > 1`, add
  `expect_equal(threshold_biphasicity, 1.0, tolerance=...)`.
- `tests/testthat/test-regression-baseline.R` + `scripts/run_pipeline.R` —
  field name follows.

**Risk.** Low (deterministic). The unit test's "produces biphasic kinetics"
assertion becomes meaningful (it now checks the threshold gate, not a
displacement artifact).

### 2b. Issue 6 — Add a real diversity-dependence metric; relabel `sign`

**Change.** `sign` ("positive"/"negative") is the slope of count-vs-time — it
means "increasing," not "diversity-dependent." Diversity-dependence is about
per-capita rate vs standing diversity. Relabel `sign`→`growth_direction`,
`slope`→`growth_slope`, and add a genuine metric:

```r
N <- innovation_counts
rate <- diff(N) / N[-length(N)]            # per-capita innovation rate
dd_fit <- lm(rate ~ N[-length(N)])
diversity_dependence_slope <- coef(dd_fit)[2]
diversity_dependence_sign <- ifelse(...>0, "positive", "negative")
```

Keep `is_superlinear` (log-log slope > 1) but document it as an exploratory
proxy, not the diversity-dependence test.

**Blast radius.**
- `R/autocatalytic_set.R` — relabel + add metrics.
- `tests/testthat/test-unit-autocatalytic.R` — update `sign`→`growth_direction`
  in the two trend tests; add a diversity-dependence test.
- `tests/testthat/test-simulacrum-autocatalytic.R` — asserts `sign=="positive"`
  and `is_superlinear`; update to `growth_direction=="positive"` (still true:
  autocatalytic data is increasing) and keep `is_superlinear`. Optionally assert
  `diversity_dependence_sign=="positive"`.
- `inst/simulacra/generate_autocatalytic.R` — comment update.

**Risk.** Medium. The autocatalytic simulacrum must stay green; the new metric
should read "positive" on superlinear synthetic data and "negative"/zero on
linear null data. Verify before committing.

### 2c. Issue 7 — `transfer_test`: null distribution + honest framing

**Change.** Two fixes:
1. Replace the single `runif(1, -1, 1)` null with a **distribution** (e.g. 1000
   random slopes) → add `null_rho_distribution` (or summary stats) and
   `null_p = mean(null_rhos >= bird_rho)`. The existing `null_rho` (one draw)
   is replaced by `null_p`.
2. **Reframe, do not change the ranking.** `rank(plant_slope × dep) =
   rank(dep)` for positive slope, so the plant slope *magnitude* is discarded —
   only the *sign* transfers. This actually matches the oracle caveat
   ("Ordering transfers across kingdoms; rate does not"), so keep the ranking
   but rename the claim from "parameter transfer" to "ordering transfer
   (slope-sign concordance)."

**Blast radius.**
- `R/cross_kingdom_transfer.R` — null distribution + `null_p`; docstring reframe.
- `tests/testthat/test-unit-cross-kingdom.R` — asserts `null_rho` exists;
  update to `null_p`.
- `tests/testthat/test-simulacrum-cross-kingdom.R` — **unaffected**: its null
  control passes *null bird data* to `transfer_test`, not the function's own
  `null_rho`, so it stays valid. (Verify.)
- `baseline/oracle.yml` — L3 `prediction` text → "ordering transfer
  (slope-sign concordance)."

**Risk.** Low. The L3 simulacrum's null control is sound (null data, not the
one-draw field); only the function's own `null_rho` field was weak.

**Phase 2 exit gate.** `make all` green; simulacra re-validated (especially
autocatalytic); oracle formal_model + L3 reframed honestly.

---

## Phase 3 — Implementation fix (math/contract change, simulacrum re-validation)

### 3a. Issue 4 — Move branch-following state into `cusp_hysteresis_check`

**Change.** Today hysteresis is detected only because the caller passes a
stateful closure (`make_cusp_equilibrium_fn` with `<<-`). Move the
branch-following into the function under test so the contract is honest:

- `equilibrium_fn` becomes a **pure** function `function(control, state) ->
  new_state` (returns the equilibrium nearest `state`), OR
  `function(control) -> roots_vector` and `cusp_hysteresis_check` picks the
  branch nearest the carried state.
- `cusp_hysteresis_check` carries `state` forward through the forward sweep
  (initialized at the first control) and the reverse sweep (initialized at the
  last control), so the two paths can settle to different branches → real
  hysteresis detection with a pure function.
- Move the `polyroot` + nearest-branch logic out of
  `make_cusp_equilibrium_fn` into a pure helper owned by the function (or pass
  `a` as a parameter).

**Blast radius.**
- `R/cusp_catastrophe.R` — rewrite `cusp_hysteresis_check` to carry state;
  change `equilibrium_fn` contract.
- `inst/simulacra/generate_cusp_system.R` — `make_cusp_equilibrium_fn` becomes
  a pure roots-function (no `<<-`), or is replaced by passing `a` + a pure
  solver.
- `tests/testthat/test-simulacrum-cusp.R` — update the closure usage; the
  `has_hysteresis = TRUE` assertion must still hold via the function's own
  state-carrying.
- `tests/testthat/test-unit-cusp-catastrophe.R` — **add a real
  `has_hysteresis = TRUE` assertion** with a folded system (currently only
  checks `max_difference` is numeric).

**Risk.** Medium (highest in the plan). The cusp simulacrum must still detect
hysteresis after the contract change; re-validate carefully. This is the one
change that alters what a function *does* (not just what it *reports*).

**Phase 3 exit gate.** `make all` green; cusp simulacrum re-validated; unit
test now genuinely asserts `has_hysteresis = TRUE` on a folded system and
`FALSE` on a monotone one.

---

## Cross-cutting: test-suite gap to close

The math review's overarching finding is that **the tests check that functions
return values and recover parameters on synthetic data — not that the claims
match the math.** Each phase above adds the missing assertion where relevant
(T7 direction, threshold_biphasicity, diversity_dependence_sign, cusp
`has_hysteresis = TRUE`). As a cross-cutting rule, for every renamed/reframed
metric, add a unit assertion that the metric reads correctly on (a) synthetic
VI-supporting data and (b) the null control — so the claim is enforced, not
just the arithmetic.

---

## Suggested commit structure

One commit per issue (7 commits), or one per phase (3 commits) if preferred.
Each commit: code + tests + oracle + docs in lockstep, `make all` green on the
branch before push. Phase 1 first (safe), then 2, then 3 — each phase is a
reviewable, shippable unit.

---

## Open question for review

1. **Issue 3** — Option A (rename only, cheap) vs. Option B (add
   `threshold_biphasicity`, recommended). Proceed with B?
2. **Issue 5** — reframe now (recommended) and defer per-family slopes, or
   attempt per-family slopes despite small n?
3. **Issue 4** — move state into the function (recommended), or just document
   the stateful-closure contract and add the missing unit assertion (cheaper,
   but leaves the contract implicit)?
4. **`math-review.md`** — apply the Issue 4 correction as part of Phase 1?

If approved, I'll execute Phase 1 first and report before proceeding to 2 and 3.
