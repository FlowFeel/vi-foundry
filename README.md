# VI Foundry

**Production-grade computational artifacts for testing predictions from the Valence-Ingression (VI) framework monograph.**

---

## What This Is

This repository contains the complete empirical and theoretical computational pipeline for the Valence-Ingression framework — a theory of adaptive evolution that predicts organisms committing to specific ecological niches undergo ordered capacity reallocation, losing traits in proportion to their integration depth (how deeply a trait is embedded in the organism's functional architecture) rather than at random.

The artifacts here do not merely reproduce numbers from the monograph. They constitute the proof machinery: every claim is a pure, testable function with contract enforcement; every statistical method is validated against synthetic data with known ground truth; and every result is traceable to its computational environment.

The package serves three audiences:

- **Researchers** evaluating the VI framework's empirical support
- **Reviewers** checking whether the statistical methods are sound
- **Replicators** reproducing the results on different data or platforms

---

## How to Reproduce

```bash
# Clone and enter
git clone [https://github.com/FlowFeel/vi-foundry](https://github.com/FlowFeel/vi-foundry).git
cd vi-foundry

# Restore the R environment (exact package versions)
renv::restore()

# Run all gates (lint → unit tests → simulacra → integration → regression → check)
make all

# Or run individual gates
make unit          # Pure unit tests — mathematical correctness, no Docker
make integration   # Full pipeline on real data via Docker simulacrum stack
make regression    # Compare all results to the baseline oracle
```

---

## Key Results

Every value below is the manuscript-reported result, stored as ground truth in [`baseline/oracle.yml`](baseline/oracle.yml). The pipeline must reproduce these within numerical tolerance (0.001).

| Test | What It Measures | Key Value | Distinguishes VI from Competitors? |
|------|-----------------|-----------|-----------------------------------|
| T1: Orobanchaceae PGLS | Plastome genome size vs parasitism depth | β = −23.5 kb/level, R² = 0.652, p < 10⁻⁹ | No — relaxed selection predicts the same gradient |
| T3: Endosymbiont biphasic | Genome reduction kinetics shape | R² = 0.920, BF = 6.7 (logistic vs exponential) | Yes — constant-rate and ratchet predict different shapes |
| T6: Gene-loss ordering | Functional dependency vs retention order | ρ = 0.955, exact permutation p = 0.0083 | Yes — random loss predicts no ordering |
| L3: Cross-kingdom transfer | Plant parameters predict bird morphology | ρ = 0.755, p = 0.031 | Yes — substrate independence predicts no transfer |

---

## Glossary

### Framework Terms

**Valence-Ingression (VI)** — The framework's name. "Valence" refers to the adaptive returns an ecological space offers an organism; "Ingression" refers to the process of committing to that space. Together: the hypothesis that organisms enter ecological spaces offering adaptive returns, are reshaped by those spaces, and that this commitment process directs evolutionary trajectory more fundamentally than selection alone. The name is currently under review (see Remark R1 in the review file) because "VI" is ambiguous within the Phosphene ecosystem and "Valence-Ingression" requires reading internal definitions before it becomes meaningful.

**Integration depth** — A trait's position in the functional architecture of an organism. Traits that participate in many developmental pathways (e.g., ribosomal RNA genes) have high integration depth; traits serving a single function (e.g., NADH dehydrogenase in non-photosynthetic parasites) have low integration depth. VI predicts that high-integration-depth traits resist loss during capacity reallocation.

**Capacity reallocation** — The process by which an organism shedding traits (due to niche commitment) preferentially loses low-integration-depth functions first, reallocating the saved maintenance budget to the remaining high-integration-depth functions. This produces an ordered pattern of trait loss, not random loss.

**Substrate shift** — The transition point where an organism's primary adaptive challenges move from one ecological substrate (e.g., photosynthesis) to another (e.g., parasitism). VI predicts this shift is autocatalytic — innovations in the new substrate generate further innovations faster than they are lost.

**Homo inversion** — The observation that the Homo lineage shows positively diversity-dependent speciation (more species over time), which is the inverse of the standard pattern in most clades (negatively diversity-dependent, or niche-filling). VI explains this via the cultural substrate's autocatalytic dynamics.

### Statistical Methods

**PGLS (Phylogenetic Generalized Least Squares)** — A regression method that corrects for the non-independence of species due to shared evolutionary history. Without PGLS, correlations between traits across species can appear significant simply because closely related species share traits by descent, not because of a real functional relationship. PGLS uses a phylogenetic tree and a parameter (λ, lambda) that measures the strength of phylogenetic signal in the residuals. When λ = 1, traits evolve under Brownian motion; when λ = 0, traits are independent of phylogeny (equivalent to ordinary least squares).

**Exact permutation test** — A non-parametric significance test that enumerates all possible orderings of the data to compute a p-value. For 6 items, there are 720 permutations (6! = 720), which is small enough to compute exactly. The p-value is the proportion of permutations that produce a test statistic at least as extreme as the observed one. This is preferred over asymptotic approximations when sample sizes are small.

**Biphasic kinetics** — A pattern of change with two distinct rates: a fast phase followed by a slow phase. In genome reduction, this means rapid initial gene loss (Phase 1, unprotected traits) followed by slow loss (Phase 2, protected traits). The mathematical signature is a logistic (saturation) curve, distinguishable from a linear (constant-rate) or exponential (accelerating) curve via model selection (ΔAICc).

**Cross-kingdom parameter transfer** — A test where parameters estimated on data from one biological kingdom (e.g., plants) are applied to data from another kingdom (e.g., birds) without refitting. If the ordering transfers, the underlying principle is substrate-independent. This is the strongest test in the monograph because it controls for kingdom-specific confounds.

**Bayes Factor (BF)** — A ratio of marginal likelihoods comparing two statistical models. BF > 6 is moderate evidence for the numerator model; BF > 10 is strong. Here, BF compares the biphasic (logistic) model to the constant-rate (exponential) model.

### Software Engineering Terms

**MPI Handoff Blueprint** — A code organization principle from the Phosphene R standards. Every analysis is decomposed into three pillars: (A) data preparation — pure function, validates inputs and outputs; (B) model fitting — seed-locked, deterministic given the same inputs; (C) result extraction — pure function, returns structured data. Input/output operations (file reading, writing) are isolated to thin wrapper functions called `main()`, which never runs when the file is `source()`d — only when executed via `Rscript`.

**DFT axioms (Design For Testability)** — Six principles adapted from production software engineering for scientific code:

- **A1 — Pure IO separation**: Statistical logic (estimation, inference, hypothesis testing) never touches the filesystem, network, or databases. I/O is isolated to thin loader functions. This makes the mathematical core testable in zero milliseconds with inline data.
- **A2 — Determinism**: No `set.seed()` hidden inside logic functions. The random seed is injected by the caller, making every stochastic operation reproducible. Cross-platform reproducibility requires specifying the RNG algorithm (`Mersenne-Twister`) and normal inversion method (`Inversion`) explicitly.
- **A3 — Manifest conformance**: The analysis pipeline is declared as a YAML manifest (`pipeline.yml`). Every stage lists its inputs, outputs, and the function that executes it. Tests verify the actual pipeline matches the manifest — if someone adds a stage without updating the manifest, the test fails.
- **A4 — Documentation**: Every source file declares its testability contract in a `@dft` roxygen2 block, stating which axioms it satisfies.
- **A5 — Real in-process fakes**: Instead of mocking `read.csv()` with a mock that records "you called read.csv," a `FakeDataLoader` returns real dataframes from in-memory fixtures. The fake executes real behavior — it returns data your logic can actually process.
- **A6 — Check-result**: Functions that do work return a proof object: a list containing `values` (the results) and `metadata` (seed, sample size, convergence status, elapsed time). A function returning `invisible(NULL)` provides no proof of what happened.

**STDD (Stochastic Test-Driven Development)** — Standard test-driven development breaks on probabilistic code: `expect_equal(mcmc_draw, 1.234)` is meaningless because the output varies with seed, data, and platform. STDD solves this by decoupling deterministic math from stochastic transitions:

1. **Deterministic functions** (log-likelihoods, matrix transforms, exact permutation enumeration): tested with exact assertions. Same input → same output, always.
2. **Stochastic transitions** (sampling, bootstrap, permutation when exhaustive is infeasible): tested under controlled seeds with structural and statistical assertions:
   - **Parameter recovery**: generate synthetic data from known parameters (θ*), run the pipeline, verify the recovered estimates (θ̂) fall within the credible interval of θ*. If the pipeline can recover known signal, it can be trusted to detect unknown signal.
   - **Null control**: generate synthetic data with no signal (random parameters), run the pipeline, verify it does NOT recover. This tests specificity — the pipeline must not produce false positives.
   - **Distributional verification**: for conjugate models, compare empirical draws to analytical distributions using a Kolmogorov-Smirnov test (p > 0.05 means "cannot reject the hypothesis that the samples come from the same distribution").

**Simulacrum** — Borrowed from Nancy Cartwright's philosophy of science: a model that captures essential properties of the target system while being explicitly not the target system. In practice: a Dockerized environment with known test data where you verify the pipeline produces correct results before running against real data. The simulacrum is the only place where you have a known baseline. On real data, you don't know the right answer — that's why you're running the analysis.

**Baseline oracle** — A YAML file ([`baseline/oracle.yml`](baseline/oracle.yml)) containing every manuscript-reported result as ground truth. Each entry includes: the prediction being tested, the competing hypothesis, the expected values (with numerical tolerance), whether the result supports VI, whether it distinguishes VI from the named competitor, and any caveats. The regression gate compares pipeline output to the oracle — if results diverge, either the code regressed (fix it) or the method improved (update the oracle with proof).

### Biological Terms

**Orobanchaceae** — The broomrape family, a clade of parasitic plants spanning the full gradient from autotrophic (self-feeding, full plastome) to extreme holoparasitic (entirely dependent on host, severely reduced plastome). This gradient makes it the primary test system for VI's integration-depth predictions.

**Endosymbiont** — A bacterium living inside a host cell in a permanent, obligate symbiosis. Examples: *Buchnera* (aphid endosymbiont), *Wigglesworthia* (tsetse fly), *Carsonella* (psyllid), *Blochmannia* (ants). These bacteria undergo severe genome reduction over evolutionary time, making them a test system for VI's biphasic kinetics prediction.

**LTEE (Long-Term Evolution Experiment)** — Richard Lenski's ongoing experiment (since 1988) tracking 12 populations of *E. coli* over 75,000+ generations. Used here to test whether metabolic function loss co-segregates with beneficial mutations (VI's drift prediction) or is independently assorted (competitor's pleiotropy prediction).

**NCC (Neural Crest Cell)** — A population of migratory embryonic cells in vertebrates that give rise to facial morphology, pigmentation, and parts of the nervous system. NCC-derived traits are predicted by VI to change early in domestication because they have low integration depth in the developmental architecture.

### Data Structures

**Mark (simulacrum mark)** — A structured YAML entry logged during a simulacrum run, capturing: the true parameters (the vertex in parameter space being tested), the recovered parameters (where the pipeline landed), whether recovery succeeded (within credible interval), the null control result, and the random seed. Marks can be projected into 2D visualizations: true vs recovered scatter plots, recovery trajectories, parameter-space projections, and rolling recovery-rate plots.

**Proof object** — The standard return value of every function in this package (DFT axiom A6). A list with two elements: `values` (named numeric vector of the results) and `metadata` (list with seed, sample size, convergence status, elapsed time). A function returning a bare number provides no proof; a proof object lets a reviewer trace every result back to its computational conditions.

---

## Standards

This repository is self-sufficient. The Phosphene R engineering standards —
including the MPI Handoff Blueprint, DFT axioms, STDD specification, literate
documentation requirements, CI/CD guide, and dependency strategy — are
reproduced in [`docs/standards/`](docs/standards/) so that a reader or
contributor does not need to consult external sources to understand the
conventions used here.

All standards documents are authored by **Ed Phillips**
([@phosphene](https://github.com/phosphene)) and licensed under MIT.

## How It Is Tested

The testing strategy is a pyramid:

```
              ┌─────────┐
              │  E2E    │  5% — Full pipeline on real data via Docker simulacrum
              │ Tests   │      + BDD features (Gherkin: simulation, data integrity, pipeline)
              ├─────────┤
              │Integration│ 15% — Real data through the full pipeline
              │  Tests   │      + baseline oracle comparison
              ├─────────┤
              │ Simulacra │  5% — Synthetic data with known parameters
              │  Tests   │      + parameter recovery + null controls (STDD)
              ├─────────┤
              │  Unit   │ 80% — Pure math, contracts, deterministic
              │  Tests  │      0ms each, no Docker, no filesystem
              └─────────┘
```

- **17 test files**, **201 test cases** (`test_that` blocks)
- **5 simulacra** — each generates synthetic data with known ground truth, runs the pipeline, verifies parameter recovery, and confirms the null control does NOT recover (specificity)
- **Baseline oracle** — YAML ground truth for every manuscript value, compared within numerical tolerance
- **5 BDD feature files** — statistical contracts in Gherkin (same seed → same output, pipeline idempotency, numerical stability, parameter recovery)
- **Coverage gate** — minimum 80%, enforced in CI

---

## Continuous Integration

Seven gates, each depends on the previous:

| Gate | What It Checks | Artifact |
|------|---------------|----------|
| 1. Lint | Code style and static analysis | — |
| 2. Unit | Mathematical correctness + contracts + coverage ≥ 80% | Coverage report |
| 3. Simulacra | Parameter recovery from synthetic data + null controls | Simulacra report (PDF) + marks (YAML) + visualizations (HTML) |
| 4. Integration | Full pipeline via Docker simulacrum stack + BDD features | Integration results |
| 5. Regression | All results match baseline oracle within tolerance | — |
| 6. R CMD check | Package validation (no errors, warnings, or notes) | Check report |
| 7. Pages | Deploy simulacra visualizations to GitHub Pages | [https://flowfeel.github.io/vi-foundry/](https://flowfeel.github.io/vi-foundry/) |

---

## Data

All data files are bundled in `data/` with provenance documented in [`data/README.md`](data/README.md) (YAML format). Sources include NCBI GenBank (plastome sizes, phylogenies), Bobay & Ochman (2017) Table S1 (niche breadth data), Dewar et al. (2024) supplementary (pan-genome data), and Good et al. (2017) (LTEE metagenomic data).

---

## Repository Structure

```
vi-foundry/
├── R/                    Pure functional library (10 files, 14+ exported functions)
├── tests/                Test suite (17 files, 201 test cases)
├── baseline/             Ground truth oracle (YAML — human-readable)
├── data/                 Bundled datasets with provenance
├── inst/simulacra/       Synthetic data generators (5 files)
├── inst/examples/        Literate analysis report (R Markdown)
├── vignettes/            Package vignette (R Markdown)
├── compose/              Docker simulacrum stack (docker-compose)
├── docker/               Dockerfiles (R runtime, Verifier; Postgres via compose)
├── scripts/              Utility scripts (viz generation)
├── archive/              Pre-foundry scripts (with migration map)
├── pipeline.yml          Pipeline manifest (DFT A3: manifest conformance)
├── .github/workflows/    CI pipeline (7 gates)
├── Makefile              Single-command reproduction
└── DESCRIPTION           R package metadata
```

---

## Authors

- **Ed Phil** — Systems architect, foundry standards, R package design
- **[Jan Ritch-Frel](https://github.com/janfrel)** — Author of the VI monograph, data curation
- **Flow Feel** — AI platform engineer, implementation, testing, CI/CD

## License

MIT

## Related

- VI Monograph: "A Trajectory Account of Adaptive Evolution from Homo to the Wider Animal Kingdom" (Jan Ritch-Frel, 2026)
- Phosphene R Standards: `docs/standards/PHOSPHENE_R_STANDARDS.md`
- Review: [`docs/review/valence-ingression-review.md`](docs/review/valence-ingression-review.md) — critical review of the VI monograph and the foundry artifacts (numbered Remarks R1… and Review Items 1–6; the code cites these directly)
- Calculation review: [`docs/review/calculation-review.md`](docs/review/calculation-review.md) — literate walkthrough of the calculation audit: each divergence traced to its root cause, with the data, the broken output, the diagnosis, and the fix
- Math review: [`docs/review/math-review.md`](docs/review/math-review.md) — audit of the mathematics vs. the implementation vs. the claims (seven issues ranked by severity; two severe: a T7 sign error and a wrong formal-model ODE docstring)
- Refactoring plan: [`docs/review/refactoring-plan.md`](docs/review/refactoring-plan.md) — execution plan for the math-review issues: proposed refactoring, blast radius, risk, and three-phase ordering (safest-first)
- Phased breakdown: [`docs/review/vi-foundry-phased-breakdown.md`](docs/review/vi-foundry-phased-breakdown.md) — phase-by-phase build, gate status, and the open data-reconciliation work (items 4–6)
- Algorithms & findings: [`docs/review/algorithms-and-findings.md`](docs/review/algorithms-and-findings.md) — formal literate survey of every algorithm, its prediction and competitor, and a synthesis of what the results indicate for the framework
- Empirical-testing expansion plan: [`docs/review/empirical-testing-expansion-plan.md`](docs/review/empirical-testing-expansion-plan.md) — proposal for moving the three "testable but not yet tested" modules (Homo inversion, cusp irreversibility, cross-kingdom transfer) toward tested; fixes a latent L3 wiring bug
- Modeling, simulation & visualization review: [`docs/review/modeling-sim-viz-review.md`](docs/review/modeling-sim-viz-review.md) — review of the author's existing modeling (finds the original empirical GLM was broken; the foundry hid this with a theoretical simulation), evaluation of the sim/viz infrastructure (three latent viz bugs found and fixed), and a proposal for a speculative simulation capacity extending VI into four toy realms
- Formal model reproduction: [`docs/review/formal-model-reproduction.md`](docs/review/formal-model-reproduction.md) — deep-dive reproduction of the broken GLM. Root cause: a data-flattening bug (`as.vector(t(retention))` misaligns dep and retention). Fix: remove one `t()` — the additive GLM then gives dep = +0.84 (p = 0.0008), para p < 0.0001, cross-kingdom ρ = +0.755, all matching VI. Contrasts five model specs against the foundry's non-empirical ODE. Executable companion: `inst/examples/formal-model-comparison.R`. Recorded as Remark R7.
