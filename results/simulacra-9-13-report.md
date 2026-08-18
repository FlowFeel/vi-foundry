# Foundry Simulacra 9-13: Results

**Date:** 2026-08-18
**Passed:** 4/5

## Simulacrum 9: Multi-System Rate Recovery — FAIL ✗

**Pass criterion:** bi-exp preferred (ΔAIC < -2) AND k1/k2 ratio within 50% for ≥3/5 systems

- LTEE-like (ratio=37): ΔAIC = -203.9, ratio error = 322.0% → ✗
- Fast system (ratio=10): ΔAIC = 4.0, ratio error = 51.7% → ✗
- Slow system (ratio=20): ΔAIC = -300.0, ratio error = 2.3% → ✓
- Moderate (ratio=10): ΔAIC = -85.0, ratio error = 978.9% → ✗
- Extreme ratio (ratio=1000): ΔAIC = -240.0, ratio error = 39.6% → ✓

## Simulacrum 10: Cross-Kingdom Parameter Transfer — PASS ✓

**Pass criterion:** Spearman ρ > 0.5, p < 0.05 in ≥3/4 pairs

- Pair 1: ρ = 0.685, p = 0.0000 → ✓
- Pair 2: ρ = 0.902, p = 0.0000 → ✓
- Pair 3: ρ = 0.898, p = 0.0000 → ✓
- Pair 4: ρ = 0.851, p = 0.0000 → ✓

## Simulacrum 11: Substrate Independence (non-DNA) — PASS ✓

**Pass criterion:** ΔAIC < -10 (bi-exp preferred) in ≥3/5 datasets

- 1: ΔAIC = -34.1 → ✓
- 2: ΔAIC = -56.0 → ✓
- 3: ΔAIC = -41.0 → ✓
- 4: ΔAIC = -23.8 → ✓
- 5: ΔAIC = -59.0 → ✓

## Simulacrum 12: Null Rate Ratio (k1 = k2) — PASS ✓

**Pass criterion:** false positive rate < 10%


*...and 15 more*

## Simulacrum 13: Behavioral-Before-Morphological (Random Ordering) — PASS ✓

**Pass criterion:** ≥95% correct classification


