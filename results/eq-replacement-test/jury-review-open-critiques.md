# Review Panel: Remaining Open Critiques

**Context:** The E18 cross-clade gradient has been defended with λ=0, LOO, sensitivity (20–10,000), Homo-compression (p=0.009 at great-ape level), and four phylogenetic models. Three broader critiques remain open. The panel evaluates whether these block publication or can be deferred.

---

## Panel A: Herculano-Houzel

**On the E18 packet:** "That's what I asked for. The λ=0 + compression test is the cleanest argument I've seen for a behavioral richness—DD link. The single-model concern was always a secondary issue — if λ=0, the model doesn't matter, and you've now shown it explicitly. Good."

**On the remaining critiques:** "The non-replicable CSV is a documentation issue, not a validity issue. Write a one-paragraph data provenance section saying exactly where each clade's value comes from (which paper, which table), and it's replicable enough for a review. You're not asking anyone to redo the ethogram counts — you're citing them. That's standard comparative biology.

"The canid test would be nice but isn't blocking. You already have the broader carnivoran DD signal. The Anderson suggestion was for a 'natural experiment' test, which is a stronger claim than what the E18 gradient needs to stand on its own. It belongs in the 'future directions' section, not the results.

"Falsifiability: The gradient is now falsifiable. The tests exist. The simulation loop is a separate project."

---

## Panel B: Brown

**On the E18 packet:** "Solid. The model comparison table should be in the supplement, not the main text — the main text only needs λ=0. But it's good to have when a methods reviewer asks."

**On the remaining critiques:** "The 'non-replicable formats' critique is overblown. A CSV with 14 rows and a tree in Newick format is about as replicable as it gets. The concern is about the source data — the ethogram counts — not the analysis file. You can't pipeline-ize the literature review. That's what citations are for. Add a data-provenance table and move on.

"The canid PyRate is a genuine time investment. Don't start it until you know what DD operationalization you're using. The PyRate DD coefficient (Gl) is different from the BAMM/MCMCglmm estimates used in the other clades. You'd need to harmonize methods first, or run everything through PyRate. That's a 2-3 month project.

"Falsifiability: The E18 gradient is now falsifiable — someone can take your CSV, tree, and PGLS code and refute it. The simulation loop is a different kind of falsifiability. Don't conflate them."

---

## Panel C: Anderson

**On the E18 packet:** "This defends the E18 claim well. The compression test was the right move. I'm satisfied."

**On the remaining critiques:** "I still think the canid domesticated/wild comparison would be the cleanest test of the framework. But I agree with Brown — it needs method harmonization first. The existing PyRate run uses a different DD model (birth-death with exponential rate variation) than the BAMM/MCMCglmm estimates used in the cross-clade dataset. You can't just compare raw coefficients across methods.

"What you CAN do right now: take the existing Canis PyRate results (Gl ≈ −0.033, P>0 ≈ 0.21) and put them in the supplement as 'preliminary.' It's consistent with negative DD for ecological Canis, which aligns with the prediction. The domestication split is a paper of its own.

"Falsifiability: The E18 gradient is now falsifiable enough. The broader framework's simulation loop is what it is — 3-4 months of compute. That's the next paper, not this one."

---

## Consensus Verdict

| Item | Verdict | Action |
|------|---------|--------|
| **E18 gradient** | **Publication-ready** | Finalize draft with λ=0 + compression + model comparison |
| **Non-replicable CSV** | **Document, don't rebuild** | Add a data-provenance table to the supplement (which paper, which table for each clade) |
| **Canid DD test** | **Defer to future paper** | Cite existing preliminary result (Gl = −0.033); the domestication split is method-heterogeneous and needs harmonization first |
| **Simulation loop** | **Defer** | Next paper. The E18 gradient is falsifiable in practice now. |
| **PyRate MCMC weeks** | **Acknowledged; not blocking** | The existing runs are sufficient for the cross-clade comparison. New runs would be for the canid split test, which is deferred. |

**Bottom line from all three:** The E18 gradient is publication-ready. The remaining critiques are real but not blocking — they describe *future work*, not *current flaws*. Document the data provenance, cite the preliminary canid result, acknowledge the simulation loop as horizon research, and the section is ready for review.

---

*Prepared: 2026-10-04 22:05 UTC*