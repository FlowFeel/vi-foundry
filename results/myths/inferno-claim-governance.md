---
uri: inferno/methods/claim-governance
owner: feelingflowingbot
status: living
updated: 2026-10-17
---

# INFERNO Evaluation: Claim-Strength Governance & Null Discipline

**Method evaluated:** the testing-characterization stack — pre-registration-first workflow (P2, P7 precedents), mandatory null baselines (shuffled chains, label/phase permutations), claim-strength tiers S/M/P/X (`CLAIM_TIERS_V1.md`), genre-gating, codebook hashing, equal-prominence negative-result reporting. Evaluated per `meta/reference/wci.md` on the 0–100 scale.

## Scores

| Dimension | Score | Rationale |
|---|---|---|
| **Theoretical coherence** | **74** | The tier structure has crisp entry/exit criteria (S = prereg + null + permutation survival + κ≥0.7; P = registered-hypothesis-only with named killing test; X = prohibited phrasings). It operationsomewhat resolve real distinctions: confidence in a direction vs confidence in an effect size. Weaknesses: tier assignment is currently self-administered by the same agents who ran the tests (no adversarial review step); the boundary between M and P is partly judgment. |
| **Empirical support** | **48** | The framework demonstrated bite on its own outputs: downgraded v1 headline magnitudes 2–4×, caught the P2 trivial-0.7 artifact, split P4 (Egypt confirmed / Sumer retired to spike-reading), degraded P7 to instrument-heterogeneity rather than letting a null masquerade either way. That is 12+ tests processed with 3 self-inflicted downgrades — a working system. But there is no outcomes track record beyond this program, and each tier's threshold (κ≥0.7, p<0.05-perm) is convention rather than calibrated. |
| **Replicability** | **72** | Every audit is a committed deterministic script with fixed inputs (`content_layer_tests_v3.py`, `null_audit_p3_p4.py`, `split_layer_battery_v3.py`, `p7_laurasian_test.py`), pre-registrations written before runs, SSOT summary docs. Weakness: raw data layer is gitignored (a lab needs the mirror); session interruptions corrupted intermediate artifacts twice — mitigated by on-disk outputs but not fully. |
| **Independent uptake** | **0** | Internal only. No external lab has applied the tiering or the null-audit method. |
| **Explanatory power** | **60** | Explains the *pattern of falls* (parser noise → inflated fractions; missing nulls → trivial passes; vocabulary floor → saturated grammar contrasts). It converts failures into information (P2 → gradient claim; P7 → resolution diagnosis). Does not yet predict ex ante which of our claims will survive at scale — needs a track record. |
| **Falsifiability** | **68** | Emits testable meta-predictions: (1) κ pilot ≥0.7 will move grammar claims from M toward S, <0.6 will quarantine them; (2) genre-gated / predicate-resolution re-coding will change grammar deltas materially or confirm the saturation diagnosis; (3) any S-tier revoked on external replication would falsify the tiering's calibration. Two of these are in flight (κ pilot; grammar re-instrumentation). |

## Composite (weights: coherence .20, empirical .15, replicability .15, uptake .15, explanatory .25, falsifiability .10)

**WCI = 54 — T3** (1 point below the T2 line)

## What would move this to T2

| Needed delta | How |
|---|---|
| Empirical +8 | κ pilot verdict actually applied (≥0.7 → grammar claims re-tiered; <0.6 → quarantine executed) |
| Explanatory +5 | one ex-ante registered prediction of tier-outcome at re-instrumentation (predict grammar delta sign under predicate coding *before* running) |
| Coherence +3 | adversarial tier-review step (a second agent audits assignments before commit) |
| Uptake +15 | one external group applying the protocol |

## Bottom line

The governance framework eats its own outputs — the same null discipline that audited the science audited the audits — and the verdict is symmetrical: T3, one point short, with the binding self-test (κ) literally running. The framework is good enough to enforce on ourselves now; it is not yet good enough to market as method until the κ and re-instrumentation tests resolve.