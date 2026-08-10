# Key Results — Discriminating Core

## The Six Tests That Distinguish VI

| Test | Key result | What it rules out |
|------|-----------|-------------------|
| T3: Endosymbiont biphasic | R² = 0.920, threshold_biphasicity = 1.0 | Constant-rate (Lynch), accelerating (Muller's ratchet) |
| T4: Niche vs Ne | Niche R² = 0.343 vs Ne R² = 0.198 | Drift (Lynch) — Ne as sole driver |
| T5: Pan-genome fluidity | Lifestyle subsumes Ne | Ne-only model |
| T6: Gene-loss ordering | ρ = 0.955, permutation p = 0.0083 | Random loss |
| Formal model (GLM) | dep = +0.84 (p = 0.0008) | Random loss (dep ≤ 0), relaxed selection (para ns) |
| L3: Cross-kingdom transfer | ρ = 0.755, p = 0.031 | Substrate independence |

These six results cannot be explained by the named competitor hypotheses without additional assumptions. They are the discriminating core of the evidence.

## The Three Tests That Support VI But Do Not Discriminate

| Test | Key result | Why it doesn't discriminate |
|------|-----------|---------------------------|
| T1: Orobanchaceae PGLS | β = −23.5, R² = 0.652, p < 10⁻⁹ | Relaxed selection predicts the same gradient |
| T2: Between-family correlation | r = −0.934, p = 1.39 × 10⁻⁴¹ | Also predicted by relaxed selection on photosynthetic genes |
| T7: LTEE co-segregation | 36.4% vs 61.7% (depletion) | Hitchhiking confound; null is misspecified |

These results are consistent with the VI framework, but they are also consistent with alternatives. They are reported honestly as non-discriminating, not omitted.

## Honest Tagging

Every oracle entry is tagged with two boolean fields:

- `supports_vi`: does the result support the VI prediction?
- `distinguishes_from_competitor`: does the result distinguish VI from the named competitor?

Where `distinguishes_from_competitor: false`, the caveat field explains why. The foundry does not hide non-discriminating results — it labels them. This is the inferential standard the monograph adopts in §12 and §11.3.
