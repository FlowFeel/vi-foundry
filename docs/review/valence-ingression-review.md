# Valence-Ingression Framework — Critical Review

**Reviewer:** Ed Phillips ([@phosphene](https://github.com/phosphene))
**Date:** August 2026
**Status:** Living document — review of the monograph (Ritch-Frel, *The
Valence-Ingression Framework*, v9, June 2026) and of the `vi-foundry`
computational artifacts that test its predictions.
**License:** MIT

---

## Scope

This review covers two things, and it is important to keep them distinct:

1. **The monograph** — Ritch-Frel's VI framework (v9). The framework proposes
   that organisms are problem-solving agents that commit to ecological spaces
   offering adaptive returns (*valence*), are reshaped by those spaces through
   *capacity reallocation*, and that evolution is the record of this process
   rather than its driver. It makes three headline predictions: convergent
   neural crest cell (NCC) genomic signatures in lineages entering
   social-tolerance niches; behavioral commitment preceding morphological
   change; and the *Homo* macroevolutionary inversion (positively
   diversity-dependent speciation) as a substrate-shift signature.

2. **The foundry** — this repository. The foundry does **not** test the
   monograph's three headline predictions directly. It tests the *§12 results*:
   the integration-depth / capacity-reallocation sub-prediction applied to
   genome reduction — Orobanchaceae plastome PGLS, endosymbiont biphasic
   kinetics, gene-loss ordering, LTEE co-segregation, cross-kingdom parameter
   transfer, niche-vs-Ne, and pan-genome fluidity. These are real VI
   predictions, but they are a narrower evidentiary register than the
   monograph's NCC / *Homo*-inversion claims (see Remark R3).

The review is written so that every finding the code depends on is stated here
by number. The foundry's test suite and pipeline cite **Remarks** (R1…) and
**Review Items** (1–6) directly; a `skip()` or a divergence message should
always resolve to a paragraph below.

---

## Executive summary

The framework's strongest contribution is mechanistic: the endogenous-`K`
account of van Holstein & Foley's (2024) *Homo* diversification inversion is,
as far as this review can establish, the only mechanism-level explanation in
the current literature for why *Homo* exhibits positively diversity-dependent
speciation. That alone justifies taking the framework seriously.

The framework's weakest point is empirical: several of its load-bearing
predictions have not been tested against data, and where the foundry *can* test
the §12 results, the bundled data does not yet reproduce the manuscript's
reported values. This is not a defect of the framework — it is a
data-reconciliation gap in the foundry (items 4–6) — but it means the foundry
currently *corroborates the methodology* (the math is correct, the gates run,
parameter recovery succeeds on synthetic data) without yet *corroborating the
numbers*.

The review's actionable findings are six numbered **Review Items**. Items 1–3
concern the framework and its framing; items 4–6 concern the foundry's data and
are the reason the regression gate currently `skip()`s rather than enforces.

---

## Remarks

Remarks are critical observations on the framework and the foundry. They are
not action items (those are the Review Items); they are the reasoning behind
them.

### R1 — The name is ambiguous

"Valence-Ingression" requires reading the internal definitions before it
becomes meaningful, and the abbreviation "VI" is ambiguous within the Phosphene
ecosystem (it collides with other uses of "VI"). Neither token is
self-explanatory to a reader encountering the framework cold. The glossary in
the root [`README.md`](../../README.md) flags this. A future revision should
either adopt a self-describing name or commit to the expansion in every
context. This is cosmetic but it affects adoption and searchability.

### R2 — "Agency" is used instrumentally, not metaphysically

The framework describes organisms as "problem-solving agents" that "navigate
toward valence-states." Read literally this is a strong ontological claim
(agency precedes replication). The monograph is careful to use the agency
vocabulary *instrumentally* — it is productive and non-metaphorical at
sub-organismal scales (Levin's TAME work), and the empirical case rests on the
paleontological and comparative record, not on the agency framing. Reviewers
should not reject the framework on the strength of the agency language, and
proponents should not overclaim it. The foundry is agnostic to this debate: it
tests integration-depth predictions, which hold regardless of whether
valence-seeking is agency or selection-with-a-trajectory.

### R3 — The foundry's evidentiary scope is narrower than the monograph's headline claims

The monograph's three headline predictions (NCC convergence;
behavioral-before-morphological; the *Homo* inversion) are **not** what the
foundry tests. The foundry tests the §12 genome-reduction results, which are
the integration-depth / capacity-reallocation prediction applied to a specific
domain (plastome and endosymbiont genome reduction, gene-loss ordering, LTEE
function-loss co-segregation, cross-kingdom transfer). This is a legitimate and
important sub-prediction, but a reader should not conclude that a green foundry
"confirms VI" in its broadest form. The foundry confirms the *capacity-
reallocation-by-integration-depth* mechanism in the genome-reduction domain.
The NCC and *Homo*-inversion predictions require their own test artifacts,
which the foundry does not currently provide.

### R4 — Some oracle entries corroborate VI but do not discriminate it from competitors

The baseline oracle ([`baseline/oracle.yml`](../../baseline/oracle.yml))
annotates each entry with `distinguishes_from_competitor`. T1 (Orobanchaceae
PGLS), T2 (cross-family), and T7 (LTEE co-segregation) are marked
`distinguishes_from_competitor: false`: the competing hypotheses (relaxed
selection, stochastic loss, independent assortment) predict the same pattern.
These results *corroborate* VI but do not *discriminate* it. The discriminating
evidence in the foundry is concentrated in T3 (biphasic kinetics), T4
(niche-vs-Ne), T5 (pan-genome fluidity), T6 (gene-loss ordering), and L3
(cross-kingdom transfer). Of these, T6 and L3 currently have no bundled data
(items 4–5) and T3/T4/T5 drift (item 6). The honest summary is: **the
foundry's discriminating tests are precisely the ones not yet passing.**

### R5 — The data gap is real and must not be hidden

The foundry's bundled data does not reproduce the manuscript oracle for T1–T5
(data drift / known statistical bugs), and T6 / L3 have no bundled data at all.
The prior failure mode — silently no-op'ing the regression gate so a green CI
hides the gap — is exactly what the gate redesign prevents. Each entry now
*runs and compares*, and divergent or unavailable entries `skip()` with an
exact actual-vs-expected reason that cites items 4–6. The gate is honest: it
reports 9 skips, not 9 silent passes. Closing items 4–6 converts those skips
into enforced `expect_equal` checks automatically.

---

## Review Items

Actionable findings. Items 1–3 are framework-level; items 4–6 are the
foundry's data-reconciliation work and are cited by the code.

### Item 1 — Resolve the naming (framework)

Adopt a self-describing name or commit to the "Valence-Ingression" expansion in
every context; disambiguate the "VI" abbreviation. Tied to Remark R1. **Owner:**
monograph author. **Foundry impact:** none (cosmetic); tracked here so the
glossary's "under review" note resolves to a concrete item.

### Item 2 — Settle the NCC mechanism question (framework)

The Gleeson & Wilson (2023) challenge — that domestication-syndrome traits
reflect non-specific reproductive-disruption rather than selection specifically
on NCC pathways — is only partially answered by Rubio & Summers (2022), who
show the positive-selection signal is concentrated in NCC genes and absent from
controls. The mechanistic pathway (direct NCC selection vs. upstream regulator
→ NCC) remains open. Prediction 1 as stated is agnostic to this distinction,
which is the right call, but the framework should state explicitly that
*distinguishing* the two mechanisms is an open problem rather than implying it
is settled. **Owner:** monograph author. **Foundry impact:** none currently;
would matter if a future foundry artifact tests NCC convergence directly.

### Item 3 — Estimate the endogenous-K / bifurcation parameters (framework)

The endogenous-`K` model (`K(N,c) = K_eco + c·γ·N^β`) and its transcritical
bifurcation condition are mathematically sound but have **no parameter
estimates from real systems**, and the bifurcation's three testable predictions
(pre-threshold hominins show negative diversity-dependence; the transition is
relatively sudden, not gradual; the threshold correlates with cumulative
culture, not just tool use) have not been tested against the fossil record.
This is the framework's strongest contribution and simultaneously its least
empirically constrained. **Owner:** monograph author / follow-up work.
**Foundry impact:** none currently; the foundry does not test diversity-
dependence parameter recovery against the hominin record (the `autocatalytic`
simulacrum tests the *sign* of diversity-dependence on synthetic data, not the
bifurcation).

### Item 4 — Bundle the gene-category dataset (foundry, **cited by code**)

T6 (gene-loss ordering) requires a gene-category dataset with columns
`category`, `dependency_score`, `*_loss_rank` (e.g.
`orobanchaceae_loss_rank`, `cuscuta_loss_rank`). It is not bundled with the
package, so the regression gate `skip()`s T6 with
`"gene-category dataset not bundled (items 4-6)"`. The unit tests use an
in-memory fixture (`.fixture_gene_categories` in
[`helper-fixtures.R`](../../tests/testthat/helper-fixtures.R)), which proves the
*math* but not the *empirical* result. **Action:** source the real
gene-category dependency scores and per-lineage loss ranks, document provenance
in [`data/README.md`](../../data/README.md), and add the file to `data/`. Once
bundled, the regression skip becomes an enforced `expect_equal` against the T6
oracle (ρ = 0.955 / 0.986, permutation p = 0.0083).

### Item 5 — Bundle the island-bird morphology dataset (foundry, **cited by code**)

L3 (cross-kingdom parameter transfer) requires `island_bird_morphology.csv`
(`structure`, `dependency_score`, `observed_rank`). It is not bundled, so the
regression gate `skip()`s L3 with `"island_bird_morphology.csv not bundled
(items 4-6)"`. The loader ([`load_island_birds()`](../../R/data_loaders.R))
exists and errors gracefully; the data does not. **Action:** source the
island-bird morphology + dependency scores, document provenance, add to
`data/`. Once bundled, the L3 skip becomes an enforced `expect_equal` against
the cross-kingdom oracle (bird ρ = 0.755, p = 0.031).

### Item 6 — Reconcile T1–T5 and T7 numerical drift (foundry, **cited by code**)

For the entries that *do* have bundled data, the pipeline output diverges from
the manuscript oracle beyond tolerance:

| Entry | Oracle | Bundled-data output | Status |
|-------|--------|---------------------|--------|
| T1 Orobanchaceae PGLS | β = −23.5, R² = 0.652, n = 12 | β = −24.17, R² = 0.736, n = 19 | drift (sample/set differs) |
| T2 cross-family | r = −0.934, n = 91 | r = −0.899, n = 15 | drift (n differs) |
| T3 endosymbiont biphasic | R² = 0.920, BF = 6.7 | R² = 0.169, BF = NA | drift / method gap |
| T4 niche-vs-Ne | niche R² = 0.343 | niche R² = 0.134 | drift |
| T5 pan-genome fluidity | lifestyle subsumes Ne | lifestyle = NA | NA / method gap |
| T7 LTEE co-segregation | observed 36.4%, p = 1e-4 | observed 36.4%, p = 3.4e-16 | p diverges (null model) |

Each divergent field `skip()`s with `"drift; items 4-6"`. This is a real
discrepancy, not a styling issue: the bundled datasets are not the same
samples the manuscript analyzed (n differs for T1/T2), and several methods
have known gaps (T3/T5 produce `NA`; T7's p-value reflects a different null).
**Action:** for each entry, either (a) reconcile the bundled data to the
manuscript sample and re-run, or (b) update the oracle with proof if the
method has legitimately improved. Do **not** loosen tolerances to hide drift —
that is the failure mode the gate exists to prevent.

---

## Mapping: oracle entries → review items → status

| Oracle entry | Distinguishes VI? | Review item | Regression status |
|--------------|-------------------|-------------|-------------------|
| T1 Orobanchaceae PGLS | no (R4) | 6 | skip (drift) |
| T2 cross-family | no (R4) | 6 | skip (drift) |
| T3 endosymbiont biphasic | **yes** | 6 | skip (drift / NA) |
| T4 niche-vs-Ne | **yes** | 6 | skip (drift) |
| T5 pan-genome fluidity | **yes** | 6 | skip (NA) |
| T6 gene-loss ordering | **yes** | 4 | skip (no data) |
| T7 LTEE co-segregation | no (R4) | 6 | skip (drift) |
| formal model (threshold) | **yes** | — | passing |
| L3 cross-kingdom | **yes** | 5 | skip (no data) |

The pattern is stark: **every entry that discriminates VI from its competitors
is currently skipped**, pending items 4–6. The foundry's methodology is sound
(unit + simulacra + integration gates are green); its empirical corroboration
of the discriminating predictions is not yet in place.

---

## What the foundry *does* establish today

Despite the open data items, the foundry already establishes several things
that are themselves substantive:

- **Mathematical correctness.** 309 unit tests pass, covering the pure
  functional library (PGLS, biphasic kinetics, threshold model, autocatalytic
  set, cusp detection, contracts). The deterministic math is verified exactly.
- **Method validity on synthetic data (STDD).** 107 simulacrum tests pass:
  every analysis recovers known parameters from synthetic data within the
  credible interval, and every null control correctly *fails* to recover
  (specificity). If the methods can recover known signal, they can be trusted
  to detect unknown signal — the data gap is the blocker, not the methods.
- **Pipeline integrity.** 13 integration tests pass: the pipeline runs
  end-to-end, is idempotent, conforms to its manifest (DFT A3), and is
  seed-reproducible (DFT A2).
- **Honest reporting.** The regression gate does not pass silently; it reports
  exactly which entries diverge and why, citing the review items that own the
  fix.

The foundry is, in short, a trustworthy instrument awaiting calibrated data.
