# VI Foundry

Production-grade R artifacts for the **Valence-Ingression (VI) monograph**.

## What is this?

The VI Foundry provides the full empirical pipeline for the VI framework
monograph — PGLS comparative methods, integration-depth ordering tests,
biphasic genome reduction models, cross-kingdom parameter transfer, the
formal dynamical model of threshold-gated capacity reallocation, and a
simulacrum test bed for parameter recovery.

Every function follows the MPI Handoff Blueprint (pure functions, contract
enforcement, guarded main) and the 6 DFT axioms. Stochastic operations use
STDD (Stochastic Test-Driven Development) with injectable seeds.

## How to reproduce

```bash
# 1. Run all tests (unit + integration + simulacra + regression)
make all

# 2. Or run individually
make unit          # Pure unit tests (no Docker, 0ms)
make integration   # testcontainers simulacrum + BDD
make regression    # Baseline oracle comparison
```

## What are the results?

Key results (from `baseline/oracle.yml`):

| Test | Key Value | Distinguishes VI? |
|------|-----------|-------------------|
| T1: Orobanchaceae PGLS | β=-23.5, R²=0.652, p<10⁻⁹ | No (relaxed selection) |
| T6: Gene-loss ordering | ρ=0.955, perm p=0.0083 | Yes |
| Cross-kingdom L3 | ρ=0.755, p=0.031 | Yes |

## What data does it use?

See `data/README.md` for provenance of all bundled datasets.

## How is it tested?

- 14 unit test files (pure math, contracts, 0ms)
- 3 integration test files (testcontainers simulacrum)
- 5 simulacrum test files (parameter recovery from synthetic data)
- 5 BDD feature files (statistical contract in Gherkin)
- Baseline oracle comparison (YAML ground truth, numerical tolerance)
- Coverage gate: ≥ 80%

## Who wrote it?

Ed Phil, Jan Ritch-Frel, Flow Feel (AI platform engineer)

## License

MIT
