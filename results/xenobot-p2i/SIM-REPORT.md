---
title: "Xenobot P2I Simulation-Lineage Run — ALife_ZapGPT (Nam Le, ALife 2025)"
date: 2026-10-07
evaluator: Flow
foundry: vi-foundry
status: complete
artifacts:
  - xenobot-sim/ALife_ZapGPT/ (public repo, cloned depth 1)
  - scripts/xenobot-p2i/run_mechanics.py (foundry runner, no VLM dependency)
  - results/xenobot-p2i/mechanics_metrics.json
  - results/xenobot-p2i/mechanics_positions.png
---

# Simulation-Lineage Mechanics Check — ALife_ZapGPT

Goal (Jan's task 2): sanity-check the paradigm mechanics that the real-xenobot paper (arXiv:2610.02247) inherits, by re-running the public simulation lineage.

## Environment
- Repo: https://github.com/namlehai90/ALife_ZapGPT (mirrors Le et al., ALife 2025 "Giving simulated cells a voice").
- Shared workspace venv (torch 2.10 CPU, sentence-transformers 5.4.1) + session-only pygame install (no pyproject change).
- The repo's own test scripts require a local Ollama server (localhost:11434, vision model "mistral-small3.1" + "mistral") that does not exist on this host; the training harness (GA/(1+1)-ES training loop) is **not in the public repo** — only inference + pretrained weights (`best_weights.pt`).
- So the runnable core = prompt embedding (all-MiniLM-L6-v2, 384-d) → CNN_P2I → 2×2×2 vector field → CellEnvironment (50 cells, 500 steps) → collective metrics. The foundry runner replaces the VLM scorer with quantitative metrics and control conditions, seed-identical init across prompts (seeds 0–2).

## Results (`mechanics_metrics.json`)

Final mean pairwise distance (lower = more clustered), dispersion RMS from centroid:

| condition | pair-dist | dispersion | mean speed |
|---|---|---|---|
| control::zero_field | 245.0 | 175.8 | 0.00 |
| control::random_field | 90.8 | 68.0 | 1.08 |
| assemble the cells (s0/s1/s2) | 50.5 / 49.8 / 49.9 | 36.8 / 35.8 / 35.5 | 1.31 / 1.30 / 1.27 |
| form two groups (s0/s1/s2) | 55.5 / 67.3 / 47.2 | 38.2 / 46.5 / 33.6 | 1.40 / 1.39 / 1.39 |
| stop moving (s0/s1/s2) | 51.9 / 57.1 / 55.3 | 36.5 / 40.4 / 38.8 | 1.30 / 1.29 / 1.31 |
| spread out (s0/s1/s2) | 52.1 / 61.8 / 52.4 | 37.2 / 44.5 / 37.1 | 1.18 / 1.17 / 1.15 |
| cluster tightly together (s0/s1/s2) | 60.7 / 69.3 / 61.4 | 43.0 / 49.1 / 43.1 | 1.24 / 1.23 / 1.24 |

## Reading

1. **The mechanical core works.** Every prompt-conditioned field produces dramatically tighter collectives than zero-field (245) or random-field (90.8) controls — the network's output is not noise; it steers. Reproducible across seeds for "assemble the cells" (49.8–50.5, very tight seed spread).
2. **Prompt-to-semantics resolution is weak in the shipped weights.** "cluster tightly together" is the *least* clustered prompt-conditioned outcome (60.7–69.3) — on par with or looser than "spread out" (52.1–61.8). "spread out" does not spread relative to cluster prompts. "stop moving" keeps moving at the same speeds as every other prompt (1.29–1.31 vs 1.15–1.40 overall). "form two groups" has the largest seed variance (47.2–67.3) and is **inexpressible** by the shipped 2×2 bilinear field (one smooth flow patch cannot create two basins).
3. **Seed variance often exceeds between-prompt differences** (e.g., "form two groups" spans a wider range than the gap between "assemble" and "cluster"), so prompt identity is not a robust control variable at this configuration.
4. Caveats: this is the ALife-2025 simulated predecessor's shipped weights, not the real-xenobot paper's model (not public); the VLM scorer that shaped training is absent from my loop, so this isolates the *policy+environment* layer only. Also the shipped config's GRID=2×2 is coarser than the CNN's native 10×10 — possibly a demo-setting artifact.

## Bottom line
The paradigm's mechanics (embedding → field → collective behavior) are real and reproducible. The public artifact's **language specificity** is marginal: outcomes are dominated by a generic cluster bias, with semantic inversion ("cluster tightly" looser than "assemble"), no stop behavior, and seed variance ≥ prompt variance for some prompts. Consistent with the audit reading of the real-cell paper: the load-bearing element is the per-category field/target, not fine-grained prompt conditioning.