# Phylomythology Pipeline — Foundry Status
# Updated: 2026-10-06

## Working (validated on simulacra)
- [✓] Simulacrum data generation (n_versions × n_chars, known ground truth)
- [✓] Hamming distance matrix
- [✓] Circular ordering (scipy linkage → leaf order)
- [✓] Contradiction index (Thuillard 2007)
- [✓] Fast/slow mytheme classification (contradiction ≤ 0.3 → slow)
- [✓] PCA (sklearn)
- [✓] Co-occurrence matrix
- [✓] Contradiction-based signal test (vs. random permutations)
- [✓] Slow vs fast CI comparison

## R Infrastructure (vi-foundry/)
- [✓] R/myths/myth_loaders.R — CSV/NEXUS loaders + distance
- [✓] R/myths/myth_networks.R — NJ, contradictions, classification
- [✓] R/myths/myth_statistics.R — PCA, signal tests
- [✓] R/myths/myth_phylogeny.R — tree building, ancestral states
- [✓] R/myths/myth_pipeline.R — pipeline orchestrator, simulacra
- [✓] tests/myths/test_myth_pipeline.R — test definitions
- [✓] pipeline.yml — myth stages integrated
- [⚠] ape:::parsimony not available → RI test deferred to Python

## Python Pipeline (scripts/myth/)
- [✓] myth_pipeline.py — full analysis engine
- [✓] run_pipeline.py — batch runner
- [✓] Simulacra pass: slow/fast discrimination, signal detection

## Data Needed (not yet transcribed from PDFs)
- [ ] data/myths/cosmic_hunt_matrix.csv (175 versions × ~42 motifs)
- [ ] data/myths/exogamy_matrix.csv (cultures × F7/F9/F45)
- [ ] data/myths/serpent_motifs_matrix.csv (versions × serpent motifs)
- [ ] data/myths/berezkin_presence_absence.csv (339 regions × 2437 motifs)

## Last Simulacrum Results
| Dataset | v×c | Slow | Fast | Mean CI | Signal p |
|---------|:---:|:----:|:----:|:-------:|:--------:|
| sim_1   | 30×18 | 3 | 15 | 0.433 | 0.0000 |
| sim_2   | 40×18 | 3 | 15 | 0.527 | 0.0000 |
| sim_3   | 50×18 | 0 | 18 | 0.565 | 0.0000 |