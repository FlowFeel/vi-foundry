---
title: "Errors & Problems Inventory — arXiv:2610.02247"
subtitle: "Itemized, severity-tagged problem inventory (fleshed-out descriptions)"
date: 2026-10-07
evaluator: Flow
basis: full-text extraction (data/xenobot-p2i/paper-fulltext.txt) + hi-res figure forensics + arXiv source tarball audit
severity key: CRITICAL = undermines a headline claim or result · MAJOR = materially weakens an argument or its interpretation · MINOR = reporting/consistency defect
---

# ERRORS & PROBLEMS INVENTORY — "Toward Controlling Biology with Language"

Evidence base: 576-line full-text extraction of the 15-page PDF, forensic transcription of all 11 hi-res figures (arXiv source tarball), and the public simulation lineage. Every numeric claim below traces to a specific text passage or figure annotation. All transcriptions are reproducible from `data/xenobot-p2i/`.

## A. Internal inconsistencies & counting errors

**A1. The training set is mislabeled: |P_train| = 33 is false; the real split is 18 train / 15 test. [CRITICAL]**
The text says (§3.4) "For each of the |P_train|=33 training prompts… 101×33 = 3,333." Figure 7's three panels each read "11 prompts: 6 train solid, 5 test dashed" — so 33 is the TOTAL number of prompts (18 train, 15 test), not the training count. Corroboration is airtight: GT2 80.0±0.0% = 12/15 exactly; the 8×-paraphrase stress set is 120 = 8×15 test prompts. Consequences: (a) the reward table is 101×18 = 1,818 pairs, not 3,333 — the abstract-level quantitative framing is inflated ~45%; (b) the headline generalization result is 12/15 prompts, 95% CI [51.9%, 95.7%] — it includes the 66.7% chance baseline (A/B below); (c) every downstream sentence built on "33 training prompts" (Related Work, §3.4, abstract-adjacent framing) inherits the error. Either the text or Fig 7 is wrong; they cannot both be right.

**A2. The headline N is unrecoverable and statistically indistinguishable from chance. [CRITICAL]**
|P_test| is never stated anywhere in the main text. The reported cells force the reading GT2 = 12/15 (A1). Exact binomial 95% CI at n=15: [51.9%, 95.7%] — chance baseline (66.7%) is inside the interval. Even at the implausible n=45, [65.4%, 90.4%] still contains 66.7%. The headline "80.0% held-out accuracy, matching ground-truth-trained" is therefore not statistically separable from a mode-collapsed always-slower policy at the paper's own displayed N, and no CI is reported anywhere to let the reader see this.

**A3. Batch count mismatch: n=100 / faster n=25 in Fig 6 vs 101 / 26 in text. [MAJOR]**
Fig 6 ("VLM trajectory-only reward vs. independently-tracked true behavior") annotates "slower (n=75), faster (n=25)" and "r = 0.843, p ≈ 3.6e-28 (n=100)". The text says 101 batches, 26 faster, and a 101×33 = 3,333 reward table. One batch is missing from the validation figure. Either J was never scored on one trajectory (reward table = 3,300, contradicting the text) or one batch was dropped downstream without annotation. The N used in the actual training pipeline is ambiguous. Given A1, the reward table is 100–101 × 18 regardless; the paper's stated 3,333 is wrong twice over (A1 + A3).

**A4. The permutation-test p-value disagrees between figure and text. [CRITICAL]**
Fig 8's red line is annotated "p ≈ 5.79e-6" (red line sits at −log10 ≈ 5.2); the text (§4.2) says the chosen configuration achieves Mann–Whitney p=1.57×10⁻⁴, against best-achievable 1.6×10⁻⁵ in the 112-point grid. Log-check: −log10(1.57e-4) = 3.80, −log10(1.6e-5) = 4.80, −log10(5.79e-6) = 5.24. The figure's marker matches ONLY the figure's own annotation. If the text value were plotted, the red line would sit inside the null distribution's right tail (null reaches ≈4), and "more extreme than all 200 shuffled best-case results" would be visibly much weaker. The paper is presenting two different strengths of its own statistical defense: the figure claims ~27× stronger separation than the text does (or vice versa). This must be reconciled — the permutation defense is a load-bearing element of the label-validity argument.

**A5. "Cross-validated against four independent optimizers" — only three exist. [MAJOR]**
Related Work claims four; Methods §3.4 describes and Table 1 reports exactly three (backprop, CMA-ES diagonal, REINFORCE). No fourth optimizer appears anywhere. A stated methodological quantity is wrong in the paper's own abstract-adjacent text.

**A6. The "optimizer agreement validates the optimum" claim is contradicted by Table 1. [CRITICAL]**
The three optimizers do NOT agree on the cells that matter: GT2 = 80.0 (backprop) vs 62.9±6.7 (CMA-ES) vs 66.9±8.7 (REINFORCE) — the two gradient-free routes sit at or below the chance baseline on every held-out cell (at-chance ≈ 66.7). Worse, the routes optimize different objectives: backprop fits the smooth curve-fit target (Eq. 3); CMA-ES/REINFORCE optimize the discrete snapped-score reward (Eq. 1). "Agreement … validates the optimum found" is true only of the in-reward optima — i.e., all three maximize the same reward landscape — while the generalization outcomes diverge maximally. The sentence structure implies the optima agree; the data show the opposite where it matters.

**A7. The ablation undersells its own meaning: "VLM reward is not redundant" is not what was tested. [CRITICAL]**
The numerical-velocity target is the single most-extreme real batch duration per category. Its GT2 failure (59.1±2.3%, below chance; GT3 exactly 66.7±0.0%) is diagnosed correctly as placement failure. But because Figure 7 shows within-category VLM curves are effectively identical, the demonstrated contrast is "curve-fit midpoint across the duration distribution vs one extreme real point" — not "language model judgment vs velocity numbers." The experiment cannot distinguish two very different claims: (i) VLM judgment carries signal that numbers don't, vs (ii) any robustly chosen per-category duration (e.g., a median, or the same sigmoid fit applied to raw velocity deltas) outperforms an extremal point. The missing control is one line of code away and is the single most important experiment not run.

**A8. Figure 5 does not match its own caption. [MAJOR]**
The caption describes the middle row as untrained-vs-trained "both correct"; the actual middle row shows two TRAINED panels — "TRAINED network -- CORRECT" ("visibly slow down" → 156.6s → batch 80, 155.0s, slower ✓) and "TRAINED network -- WRONG (same model)" ("noticeably more sluggish and tired" → 69.7s → batch 133, 60.0s, faster ✗). The caption is describing a different figure version. (The failure example itself is a model of honesty — and it is also the live demonstration of the routing failure class the merged metric hides.)

**A9. The curve fits use 90 points each, not 101. [MAJOR]**
Fig 7's subtitle: "sigmoid(w*duration_norm+b) fit per prompt, 90 points each." The text says every archive point is scored (N=101). Eleven batches are absent from the per-prompt logistic fits, unexplained. Combined with A3, two different "missing batch" counts now exist (1 in Fig 6, 11 in Fig 7), and neither is acknowledged.

**A10. The trial pool is ≥276, not 149. [MAJOR]**
Fig 5 panels reference "batch 276 (194.0s)", "batch 250 (166.0s)", "batch 133 (60.0s)". Batch numbering reaching 276 means the original pool was ≥276 trials; the text says "149 tracked batches" with no mention of the parent pool. The exclusion chain is ≥276 → 149 tracked → 48 excluded → 101 classified. The 48/149 "unreliable" drop is thus at most 17% of the original pool (48/276), and ≥46% of all trials vanish before tracking — a selection funnel never described, with bias unquantified.

**A11. Demo-prompt durations don't reconcile across text and figures. [MINOR]**
§4.5's Fig 10 description gives d̂ = 74.0s ("speed up"), 131.0s ("slow down"), 194.0s ("stop"); Fig 5's panels show predicted 38.5s / 156.6s / 185.8s. Notably 194.0s appears in Fig 5 only as an ARCHIVE batch duration ("batch 276 (194.0s)"), not a prediction — §4.5's "stop" d̂ may conflate the predicted duration with the nearest-archive duration. Needs author clarification, but the demo numbers as presented mix prediction and archive values.

**A12. 13 of 75 'slower' batches are unaccounted for. [MINOR]**
The retrospective sub-split yields 48 genuine stops + 14 mild slowdowns = 62; 75 − 62 = 13 slower batches are neither. The text never states what those 13 were. Either the sub-classification is incomplete or there is a third sub-class; unstated either way.

## B. Statistical problems

**B1. ±0.0 SD across 30 seeds is metric discreteness, presented as precision. [MAJOR]**
GT3 (88.9±0.0) and GT2 (80.0±0.0) show literally zero variance across 30 seeds. With discrete targets and kNN vote evaluation, predictions are deterministic in the bucket-routing + duration choice; "30 seeds" implies stability analysis while the ±0.0 conveys certainty the evaluation cannot support (a single prompt flip = 2.2pp at n=45, 6.7pp at n=15). The variance reporting across cells is also inconsistent (89.1±1.0 vs 88.9±0.0 vs 80.0±0.0) with no explanation of which cells are deterministic and why.

**B2. "97% sign agreement" counts boundary ties as sign matches. [MAJOR]**
Two of the three open circles in Fig 6 sit exactly at score 0.0 — ties, not sign disagreements. A strict sign test with ties excluded changes both the numerator and denominator; the 97% figure depends on a tie-handling rule that is never stated. The r=0.843 is fine as a correlation; the "97% sign agreement" phrasing overstates the dichotomy it implies. (Also: the p≈3.6e-28 at n=100 with a 75/25 split is a base-rate artifact, not evidence of discrimination quality.)

**B3. Chance baseline depends on prompt sampling, and always-slower ≈ 66.7%. [MAJOR]**
With even three-bucket prompt sampling and a merged two-class evaluation, the trivial policy "always predict slower" scores 66.7% — and the kNN vote for a slower-routed prompt on the 30/40-slower test archive is near-certain to be correct. The prompt-level accuracy therefore measures almost entirely the prompt→head routing correctness, not duration placement quality; the evaluation cannot separate "understood the prompt" from "guessed the base rate." The paper states the 66.7% baseline honestly (credit), but the metric's inability to decompose routing vs placement is not discussed.

**B4. Machine-zero training loss documents exact memorization. [MAJOR]**
Fig 9: final MSE 5.61e-16 (VLM target) vs 4.14e-15 (numerical target) — floating-point zero. A 26,786-parameter network memorizing ~2 discrete targets to machine zero is not "fitting comparably"; it is exact memorization with zero generalization margin by construction. The "optimization difficulty cannot explain the gap" claim is true but trivial at machine zero; the two targets are so few that train-loss comparison cannot probe generalization at all.

**B5. The retrospective sub-label split is post-hoc on the same data. [MINOR]**
The stop-vs-mild sub-classes (p=7.5×10⁻⁶, non-overlapping IQRs) were discovered by inspecting the merged 'slower' class of the very archive used for evaluation; no split-half/holdout validation of these sub-classes is reported, and multiple-exploration correction for the sub-class search is not mentioned. It is presented as a robustness check, which is fair; it is not presented as a pre-specified analysis, which is also fair — but the headline metric remains the merged one, so the sub-split is evidence-bearing only in the direction that shows the metric's coarseness (B6).

**B6. The merged metric credits 33.3% of 'motion reduction' outputs — full stops — as correct. [CRITICAL]**
Table 3: 'motion reduction' prompts land on genuine stops 33.3% of the time; 'stop' prompts land on true stops 97.8% of the time. Because stop and slower are merged, the 33.3% overshoots are scored as correct — i.e., the headline 80% counts, as successes, commands whose stated reduction overshot into full immobilization. The paper shows the data can distinguish these (p=7.5×10⁻⁶) and nevertheless evaluates at the coarser grain. The headline number therefore embeds a behavioral failure mode it claims to have measured.

**B7. "Max 0.60 Jaccard overlap" is a loose deduplication bound. [MINOR]**
Held-out prompts may share up to 60% token overlap with training prompts — near-template paraphrases ("make the bot go faster" vs "make the bot go quicker") pass the bound. The claim "no held-out prompt duplicates a training prompt" is technically true and practically loose; template leakage across the 0.6 threshold is possible.

## C. Design/methodological problems

**C1. The task is degenerate: 2 effective classes, ~2 target durations, 26k params. [CRITICAL]**
Fig 7 shows within-category VLM curves "near-indistinguishable"; the paper concedes every prompt's curve "peaks at the same archive-supported duration." The learned mapping is category → one duration. The entire "language" content under test is SBERT nearest-centroid routing of prompts into 2 buckets. The multi-task "opposing objectives" framing (stop vs accelerate interference) inherited from the simulation papers is not exercised by this dataset — there are no opposing objectives to interfere, only 2 heads on a binary routing problem.

**C2. Retrieval is not control. [CRITICAL]**
Predicted durations snap to the nearest archived duration, and the archived outcome is credited to the prompt. The VLM never scores an unseen outcome; the system cannot produce any intervention not already in the archive; no predicted intervention is ever applied. The paper admits this in-text ("retrieves rather than generates") but the title and abstract ("Controlling Biology with Language") license the opposite inference. Every biological claim in the paper is conditional on an untested transfer assumption.

**C3. Target clipping leaks ground truth into the "VLM-only" reward. [MAJOR]**
The target d†(p) is "clipped into the nearest real, archive-verified interval where every point is correctly labeled for p's intended behavior." p's intended behavior is a ground-truth quantity (the authors wrote the prompts). If the clip fires often, targets are label-determined, not VLM-determined, and the "sole reward is the VLM" claim weakens proportionally. Clip frequency is never reported. The anomaly in the other direction — Train cell is 89.1%, not ~100%, despite targets being "correctly-labeled intervals" — also goes unexplained (kNN radius pulling in mislabeled neighbors? different cell basis?).

**C4. Label provenance is undocumented and load-bearing. [MAJOR]**
The 26/75 faster/slower classification is the ground truth for everything (window validation, judge validation, evaluation). The main text never states whether these are stimulus-intent labels (short pulse → excite, long pulse → inhibit) or measured velocity signs. The window-selection sentence reads as intent-labels validated to be velocity-visible, but the assignment rule is a prerequisite for interpreting every number in the paper and is not given.

**C5. Exclusion criteria are unspecified and possibly motion-correlated. [MAJOR]**
48 of 149 tracked batches (32%) excluded as "unreliable rather than force-classified" — criteria in the phantom supplementary only. If trackability correlates with motility (fast bots leave frame; stopped bots are trivially trackable), exclusion induces label-dependent selection bias. With the ≥276-pool funnel (A10), the bias could be larger than the headline effects.

**C6. The window configuration is label-coupled. [MINOR, mitigated]**
The 30/50-frame median config was selected by grid search to maximize separation of the same labels it then validates — mitigated properly by the 200-shuffle permutation test (which is why this is MINOR), but the mitigation's strength is compromised by the A4 p-value contradiction (the null distribution comparison depends on which p is real).

**C7. Single judge, no calibration. [MAJOR]**
One VLM (Claude) is the sole judge; no alternative VLM, no human-rater baseline on the language axis, no query-template/version/temperature disclosure (see R3). The internal validation vs labels is the right defense, but the "VLM judgment generalizes" claim is a sample of one.

## D. Framing & claim overreach

**D1. "Controlling Biology with Language" (title/abstract) vs a 2-class retrieval policy on archived videos. [CRITICAL]** — the object-level claim is untested by design (C2); the framing inverts the evidence's direction.

**D2. "Matching a network trained directly on ground-truth labels" (abstract) — that baseline network never appears in the paper's sections. [MAJOR]** — abstract-only result, unreproducible from the main text.

**D3. "VLM reward is not redundant" (abstract/RW) — not what A7's ablation shows. [CRITICAL]** — see A7.

**D4. "Multi-task, opposing objectives" framing — not exercised (C1). [MAJOR]** — inherited from simulation work; here the "opposition" is a 2-bucket routing.

## E. Reproducibility & artifact problems

**E1. The Supplementary Material is a phantom. [CRITICAL]** — Appendix is a pointer; no supplementary in the arXiv source tarball (verified: LaTeX + figures only). Prompt list, VLM query template, optimizer hyperparameters, SAM tracker details, exclusion criteria, generalization matrices, demo video: all deferred to a document that does not exist publicly.

**E2. No code for the real-cell pipeline. [CRITICAL]** — no repository link in paper or arXiv listing; Nam Le's public repos cover only the simulated predecessors (ALife_ZapGPT, ZapGPT), last touched July 2025.

**E3. The reward is a proprietary API with undisclosed version/template. [CRITICAL]** — the reward table cannot be reconstructed by anyone, ever, without the exact model + prompt template; even with code, model drift breaks reproduction. The judge-vs-labels validation mitigates scientific claims but not reproducibility.

**E4. The public simulation code is the wrong pipeline (simulated cells). [MAJOR]** — anyone attempting reproduction from public artifacts gets the ALife-2025 simulator, not the xenobot tracker/P2I of this paper.

**E5. AI-use disclosure is partial. [MINOR]** — Claude is disclosed as paraphrase assistant and is (in Methods) the judge; the circularity (same model family generates test prompts and scores rewards) is never flagged as a risk in the AI-use statement or discussion.

## F. Minor reporting gaps

**F1.** No data-availability statement anywhere (videos, trajectories, labels). **F2.** N_test, per-cell N, and all CIs absent (A2). **F3.** The "probabilistic fitness baseline" of Fig 4 — flat ~73–74% on ALL cells including GT2 — is undefined in main text; a prompt-agnostic baseline that narrows backprop's GT2 margin (80.0 vs ~73) is not a footnote, it's a comparator. **F4.** Clip-rule trigger frequency unreported (C3). **F5.** Sigmoid→duration mapping (how σ output converts to seconds) not stated.

## Net effect

- Headline statistical claim: NOT established at the paper's own displayed N (A1/A2/B6).
- Statistical defense of labels: two self-contradictory versions (A4), one boundary-dependent (B2).
- Claim-3 mechanism: untested alternative explanation stands (A7).
- Central biological claim: untested by design (C2).
- Reproduction: impossible with public artifacts (E1–E3).
- The paper's engineering (window-selection audit, permutation attempt, honest baselines, exclusion-instead-of-force-labeling, replicate discipline) is above field norm; its presentation discipline is not. F1–F6 + A1–A12 read as rushed preprint hygiene (a camera-ready revision for ICLR 2027 would plausibly fix most of A-class items), but A2/B6/C2 are structural: they survive any copyediting and require either new experiments (prospective test) or honest re-scoping (retrieval learning, not biological control).

WCI impact: A1/A2 confirm the empirical-support critique (64 → ~60); A4 + A5/A6 add coherence hits (66 → ~62); E-class keeps replicability at 42. Composite ≈ 51–52, still low-T3. Everything reproducible from `data/xenobot-p2i/paper-fulltext.txt` + the figures.