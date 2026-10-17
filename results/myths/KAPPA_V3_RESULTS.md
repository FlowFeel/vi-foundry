# Kappa re-pilot round 2 (v3 predicate instrument) — results & verdict

**Date:** 2026-10-17 · coders: B and C, both blind, same staging (`KAPPA_V3_STAGING.json`), same fixed codebook · agreement computed locally (Stage 3, deterministic)

## Numbers

| entry | nB | nC | aligned κ | bigram J | mytheme J |
|---|---|---|---|---|---|
| Two Brothers (Egypt) | 19 | 20 | **0.45** | 0.42 | 0.75 |
| Horus & Seth (Egypt) | 18 | 24 | 0.10 | 0.29 | 0.50 |
| Meamei Seven Sisters (Aus) | 19 | 20 | 0.27 | 0.33 | 0.50 |
| Psalm 1 (Hebrew) | 7 | 6 | 0.20 | 0.10 | 0.67 |
| Big-Raven A (Koryak) | 21 | 10 | −0.01 | 0.00 | 0.17 |
| Amis 1 (Formosan) | 6 | 6 | 0.36 | 0.11 | 1.00 |
| **pooled** | | | **0.307** (n=78 slots, po=0.37) | | **0.597** |

## What improved vs round 1 (κ 0.167, 10 slots)

- **Mytheme parent-category normalization WORKED**: 0.21 → 0.60 (Amis 1.00, Two Brothers 0.75) — essentially at the 0.6 bar with n=6.
- Segmentation stabilized on 4 of 6 entries (nB≈nC within 10%); literary prose segments cleanly, as predicted.
- Round-over-round κ rose 0.17 → 0.31. The instrument is learnable, not random.

## What still fails and why

- Event-type label agreement at aligned slots stays low (κ 0.31 vs 0.70 bar): the 19-code closest-match instruction leaves too much subjective mapping space.
- Segmentation still diverges on ORAL material — Koryak (21 vs 10 predicates) is the catastrophic case: the staged excerpt spans tale boundaries, and clause-vs-episode unitization differs exactly where genre-gating warned it would.

## Verdict (per protocol) and governance actions

**VERDICT: REVISION-THEN-REPILOT (round 2 of 2 failed the bar). Standing decisions:**

1. **Event-grammar cross-tradition contrasts: QUARANTINE CONFIRMED.** Two independent rounds with materially different instruments both failed κ. Cross-coder event-chain statistics may not support any cross-tradition claim. Within-pipeline grammar work (same coder, within-corpus diachronic — e.g., P3/P4-style ancient analyses) is unaffected, because it never relied on cross-coder agreement.
2. **Parent-category mytheme layer: promoted to the cross-tradition structural layer** (provisional M-tier, borderline κ≈0.60): an 18-category mytheme space with areal codes. Registered follow-up (P8): re-run the lineage-contrast battery (P7 protocol, same nulls) on parent-mytheme region sets — cheap, uses existing data.
3. **Round 3 preregistration duty:** any third attempt must change the *unit*, not the labels — proposal: fixed episode segmentation AND doubled-codebook (event_type × agent_role as the unit label, which gives coders less room), plus cleanly bounded tales (no arbitrary file chunks). Only run after P8's outcome is known; if the parent-mytheme layer carries the lineage signal, event-grammar may be retired rather than repaired.
4. Koryak staging flaw logged: excerpt chunks must be complete titled tales; re-stage before any future Koryak coding.