# Phosphene R Engineering Standards

These documents are the authoritative reference for the standards
used in this repository. They are reproduced here from the
[Phosphene R Artifact Foundry](https://github.com/FlowFeel/r-artifact-foundry)
so that this repository is self-sufficient — a reader or contributor
does not need to consult external sources to understand the conventions.

## Documents

| Document | What It Covers |
|----------|---------------|
| [PHOSPHENE_R_STANDARDS.md](PHOSPHENE_R_STANDARDS.md) | Consolidated R engineering standards: deterministic environments, quality gates, testing strategy, CI/CD, code organization, dependency management, S3 class design, documentation, anti-patterns |
| [MPI_HANDOFF_BLUEPRINT.md](MPI_HANDOFF_BLUEPRINT.md) | Architecture specification: pure functions, contract enforcement, guarded main, three-pillar separation (data munging → model fitting → result extraction) |
| [STDD_SPEC.md](STDD_SPEC.md) | Stochastic Test-Driven Development: decoupling deterministic math from simulation, seed discipline, parameter recovery, distributional verification, convergence assertions |
| [LITERATE_DOCS.md](LITERATE_DOCS.md) | Three-layer literate documentation: function-level (@section Theoretical Context), package-level (vignette), analysis-level (literate report) |
| [CI_CD_GUIDE.md](CI_CD_GUIDE.md) | GitHub Actions CI pipeline architecture: lint → test → coverage, container strategy, caching, Stan/brms CI strategy |
| [DEPENDENCY_STRATEGY.md](DEPENDENCY_STRATEGY.md) | R package dependency selection, evaluation criteria, tier system, renv workflow, Posit Package Manager |
| [GETTING_STARTED.md](GETTING_STARTED.md) | How to scaffold a new foundry artifact using `phosphene.foundry` |
| [BDD_IN_R.md](BDD_IN_R.md) | Behavior-Driven Development in R with cucumber and testthat |
| [DEVEX_APPROACH.md](DEVEX_APPROACH.md) | Developer experience best practices for R engineering |

## License

These standards documents are licensed under MIT, consistent with the
[repository license](../../LICENSE). They are reproduced from the
[Phosphene R Artifact Foundry](https://github.com/FlowFeel/r-artifact-foundry).

## Author

**[Ed Phillips](https://github.com/phosphene)** — Phosphene R engineering
standards, foundry architecture, and design principles.
