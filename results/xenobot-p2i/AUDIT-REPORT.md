---
title: "Xenobot P2I Figure Audit — arXiv:2610.02247 (Le, Blackiston, Levin, Bongard)"
date: 2026-10-07
evaluator: Flow
foundry: vi-foundry
status: complete
artifacts:
  - data/xenobot-p2i/figures/ (11 hi-res figures from arXiv source tarball)
  - results/xenobot-p2i/mechanics_metrics.json (sim lineage run, see sim-report)
  - results/xenobot-p2i/mechanics_positions.png
---

# Figure-Level Forensic Audit — "Toward Controlling Biology with Language"

Source: arXiv:2610.02247v1 source tarball (LaTeX + 11 figures; no code, no data, no supplementary deposited).

## Findings

### F1. Figure 6 vs main text: batch counts disagree (101 vs 100; 26 vs 25 faster)
- **Figure 6** (vlm_validation_scatter.png): x-axis categories `true: slower (n=75)` and `true: faster (n=25)`; annotation `r = 0.843, p ≈ 3.6e-28 (n=100)`; "97% sign agreement (open circles = 3 near-zero mismatches)"; exactly 3 open circles visible (1 grey ~y=0.05, 2 red at y=0).
- **Main text §3.2**: "101 batches remain classified (26 'faster', 75 'slower')". §3.4: reward table = "101×33 = 3,333".
- If the validation figure was computed on 100 batches, either one batch was dropped from J-scoring (making the reward table 100×33 = 3,300, contradicting the stated 3,333) or the text count is wrong. Also: sign agreement on n=100 with 2 points exactly at s(b)=0.0 is boundary-dependent (a score of exactly 0 is a tie, not a sign).
- Verdict: internal inconsistency; N used in the actual training pipeline is ambiguous (100 vs 101).

### F2. Figure 7 panel titles vs main text: |P_train| = 33 is wrong; the real split is 18 train / 15 test
- **Figure 7** (vlm_curves_all33.png): panel titles read `motion_increase (11 prompts: 6 train solid, 5 test dashed)`, `motion_reduction (11 prompts: 6 train solid, 5 test dashed)`, `stop (11 prompts: 6 train solid, 5 test dashed)`. ⇒ **33 prompts TOTAL = 18 train + 15 test**.
- **Main text §3.4**: "For each of the |P_train|=33 training prompts… 101×33 = 3,333"; Related Work: "we train and evaluate on 33 prompts".
- Corroboration that 15 test is right: GT2 80.0±0.0% = 12/15 (5 per bucket); the 8× paraphrase stress set = 120 = 8 × 15. Both fit 15 test prompts exactly; neither fits "33 train".
- **Implication:** the reward table is 101×18 = 1,818, not 3,333 (the abstract/intro number is inflated ~45%). And the headline GT2 result is 12/15 held-out prompts → exact binomial 95% CI [51.9%, 95.7%], which **includes the 66.7% chance baseline**: the headline generalization claim is statistically indistinguishable from chance at 95% confidence under the paper's own displayed split.
- Bonus: subtitle says curves are fit on "90 points each" — 90 (batch, score) points per prompt, not 101. Eleven batches are absent from the fits; not explained in main text.
- Curve content matches the "within-category near-indistinguishable" claim: tight ribbons per panel, monotone sigmoids (motion_increase decreases with duration; motion_reduction/stop increase), no outliers.

### F3. Figure 8 vs main text: the permutation-test p-value disagrees (5.79e-6 in figure vs 1.57e-4 in text)
- **Figure 8** (permutation_test.png): title "Permutation test: is the real duration->behavior pattern stronger than anything this search finds in shuffled (fake) data?"; x-axis `-log10(best p-value found by the full grid search)`; red line at ≈5.2 annotated **p ≈ 5.79e-6**; null histogram (200 shuffles) mass between -log10 ≈ 1.5–3.5.
- **Main text §4.2**: chosen config separates by behavior at Mann–Whitney **p=1.57×10⁻⁴** ("against a best-achievable p=1.6×10⁻⁵ elsewhere in the same 112-point grid"); "the real configuration's p=1.57e-4 is more extreme than all 200 shuffled best-case results (Figure 8)".
- -log10(1.57e-4) = 3.80; -log10(1.6e-5) = 4.80; -log10(5.79e-6) = 5.24. The red line matches **only** the 5.79e-6 annotation. If the real p were 1.57e-4, the red line would sit at 3.8 — inside the right tail of the null histogram (which reaches ≈4), materially weakening the "more extreme than all 200" claim.
- Verdict: figure and text report different p-values (factor ~27); the strength of the permutation defense as claimed in text is not what the figure shows. Which value is the real config's? Author clarification required.

### F4. Figure 5 content vs its caption: middle row is NOT untrained-vs-trained
- **PDF caption (Fig 5)**: "Top and bottom rows show a clean wrong-vs-right contrast; the middle row's untrained and trained predictions both land on the correct direction for this particular prompt."
- **Actual figure** (anecdotal_combined.png), middle row: two **TRAINED** panels — left: `TRAINED network -- CORRECT / "the bot's movements should visibly slow down" → 156.6s → batch 80 (155.0s, label: slower) ✓`; right: `TRAINED network -- WRONG (same model) / "the xenobot ought to feel noticeably more sluggish and tired" → 69.7s → batch 133 (60.0s, label: faster) ✗`.
- Caption/figure mismatch: the caption's description of the middle row does not describe the actual panels. (The wrong case itself is honest and revealing: a slowdown-intent paraphrase routed to the faster head — exactly the failure class the 80% aggregate hides.)
- Bonus: batch IDs in the figure reach **276** ("batch 276 (194.0s)", "batch 250 (166.0s)", "batch 133 (60.0s)") — the underlying trial pool was ≥276, of which 149 were tracked and 101 classified. The main text never mentions a pool larger than 149. Exclusion chain 276+ → 149 → 101 means ≥46% of original trials never enter the analysis.
- Also: Fig 5 predicted durations (38.5s / 156.6s / 185.8s) are model outputs of a different run than Fig 10's text values (74.0 / 131.0 / 194.0); the figure-to-figure mapping of "the three demo prompts" is not consistent across main text and figures.

### F5. Figure 9 (loss): consistent with text, but note the scale of "comparable"
- Both curves reach machine-zero: VLM-fit target final loss **5.61e-16**, numerical target **4.14e-15** (embedded legend text). Consistent with §4.3's claim that fit difficulty doesn't explain the GT2 gap.
- But: machine-zero MSE means exact memorization of the (≈2) discrete per-category targets. This is empirical support for the reading that the task is degenerate — a 26,786-param network memorizing 2–3 target durations — and that all generalization load sits on prompt→head routing + target placement, not on prompt-conditioned continuous control.

### F6. Figure 4 (generalization): mixed metric + an unexplained baseline
- y-axis: "Ground-truth accuracy (%) / oracle-probability x100 (baseline only)" — the text discloses this figure uses a different oracle-probability metric for baselines, "not for a direct numeric comparison to Table 1". Plotted REINFORCE values (~71.1/71.1/69.3/69.3) differ from Table 1 (69.4/69.4/66.9/66.9); explained only partially by the metric note.
- **"Probabilistic fitness baseline"** (grey triangles) sits flat at ≈73–74% on ALL four cells, including GT2. This prompt-agnostic baseline beats the 66.7% chance level on the fully held-out cell by ~7pp, narrowing backprop's demonstrated edge (80.0) considerably. The baseline is not defined in the main text (supplementary-only); it should be.

## Audit method note
All transcription was done by vision-model inspection of the hi-res source figures (1114KB–7.1MB PNGs from the arXiv tarball). Numeric annotations (n=100, n=25, p≈5.79e-6, panel train/test counts, batch IDs) were read directly from rendered text in the figures. Programmatic pixel-level recomputation (e.g., re-fitting r from the Fig 6 scatter) is a possible next step.

## Bottom line
Four concrete figure-vs-text inconsistencies (F1–F4), one degenerate-fit observation (F5), one undisclosed-baseline issue (F6). F2 is the most consequential: under the paper's own displayed split the headline GT2 result is 12/15 prompts and not statistically separable from the chance baseline; F3 undercuts the strength of the permutation-test defense as written.