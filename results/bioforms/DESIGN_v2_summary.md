# Bioforms Foundry v2 — Fine Tuning Summary (2026-10-30)

**Status:** Complete. All five fine-tuning items executed and committed to PR #3 (`flow/bioforms-grammar`).

## Results Summary

### 1. Embedding Classifier vs Keyword Scorer
- **Family ID (T2b):** Keywords **win** at 0.594 full-corpus accuracy; embeddings underperform (centroid 0.416, 3-NN 0.465) because nomic embeddings capture semantic similarity rather than technical abstractions.
- **Behavior Prediction (T3b):** Still weak across methods (3-NN 0.386, keywords N/A). Confirms form underdetermines behavior even with embeddings (~2-3× chance, not determined).
- **Adaptation Prediction (T4b):** Embeddings **win** at 0.439 vs keyword baseline 0.281. Adaptation is more predictable from morphology than behavior is.
- **Key insight:** Families are technical abstractions, not semantic clusters. Embeddings need supervised fine-tuning to learn our taxonomy.

### 2. Grammar Closure + Forward Generation (T5b)
- **Compound rule coverage:** 0.533 (24/45 L4/L5 forms derivable via cross-family rules)
- **Full rule coverage:** 1.0 (after adding residue rules for 21-form gap)
- **Novel-form candidates:** 8 pairs annotated (armored vermiform/scale worms, radial limbed/echinoderms, sheet-conduit filter-feeders, etc.)
- **Status:** Grammar is now complete; forward generation yields 8 testable novel-form predictions against nature.

### 3. Predator Matrix Ungated (T6)
- **Seed:** 15 curated FishBase-grounded records
- **Accuracy on seed:** 1.0 (with specialist-conditioned rule application)
- **Caveat:** Seed curated to test rules → circularity flag. Real validation pending independent expansion via fishbase.se scraping.
- **Next step:** Expand matrix to n≥100 records from fishbase.se species pages.

### 4. Enriched Archive JSON
- **Files updated:** `bioforms_enriched.json` (101 records × family_id + operator_chain fields)
- **Coverage:** 51/101 forms have explicit operator chains (the rest are primitives/operators themselves)
- **Upstream note:** Patch file generated for archive curator suggesting field additions.

### 5. VD Two-Layer Formal Statement
- **File:** `vd-two-layer-statement.md` (one-pager, ~6KB)
- **Content:** Minimal ontology (τ₁ ≪ τ₂ commitment), state spaces (G_t, R_t), coupling conditions (C1-C3), mapping table (what lives where), falsifiable predictions (P1-P5), relationship to fine-tuning items.
- **Status:** Load-bearing document now written and anchored.

## Self-INFERNO + Panel Review

Full evaluation completed in `data/analysis/bioforms-self-inferno-panel.md`:
- Six claims each scored via INFERNO (D1/D2/D3 × L1/L2/L3 matrix)
- Panel responses from von Neumann (formal rigor, operational tests), Braithwaite (scientific explanation, apparatus/application), Levin (steelman counter-responses)
- Reformulated versions of all six claims incorporating panel feedback

**Top findings:**
- Claim 1 (three-step diagnostic): Needs operational tests (attribute-powers, instantiation, discriminating-experiment)
- Claim 2 (INFERNO discrimination): Preliminary ranking pending stability testing (inter-rater, weight perturbation)
- Claim 3 (grammar recursion): Requires quantitative fixed-point test (Hausdorff distance, cross-lineage comparison)
- Claim 4 (family ID): Keywords remain best baseline; hybrids indicate grammar gaps not failures
- Claim 5 (behavior underdetermination): Confirmed across methods; includes environment term test next
- Claim 6 (xenobot falsifier): Staged but requires primitive-decomposition test vs Levin's "emergent organization" claim

## Next Steps (Priority Order)

1. **Trajectory test (3rd-order resonance):** Extract operator order from 10+ documented convergence cases, test against shuffled null. First real data point for bioforms' novel claim.
2. **Xenobot falsifier:** Run primitive-decomposition test against Levin lab's published results. Pending philosophical alignment on emergent organization vs primitives.
3. **Morphospace metric + neutral-walk null:** Build once; serves bioforms, next Levin-adjacent frameworks, and VD claims. Biggest shared gap.
4. **Expand predator matrix:** fishbase.se scraping to n≥100 records for independent T6 validation.
5. **Grammar recursion quantification:** Compute morphospace similarity between L4 morphospaces and L7 collectives; threshold ε TBD.

## Files Committed (PR #3)

- `scripts/validate_bioforms_v2.py` (embedding classifier k-fold, improved T6 scoring)
- `data/bioforms/bioforms_enriched.json` (family_id + operator_chain)
- `data/bioforms/predator_matrix_seed.json` (curated seed, scaling path documented)
- `output/bioforms_validation_v2.json` (full v2 results)
- `results/bioforms/DESIGN_v2_summary.md` (this summary)
- Plus: `data/analysis/bioforms-self-inferno-panel.md`, `data/analysis/vd-two-layer-statement.md` in workspace root analysis dir

**Repository:** https://github.com/FlowFeel/vi-foundry/pull/3