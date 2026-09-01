---
uri: vi-foundry/docs/recast-test-queue
owner: edphos
status: living
updated: 2026-08-24
---

# VI Foundry — Recast Test Queue

Tests queued from the recast test designs, filtered through jury review thresholds. Each test is designed to break circularity, use independent data, and speak directly to the recast claims.

Design principles inherited from ticket queue:
1. One generator per file. Seeded determinism. Proof objects.
2. Honest claims. If a claim fails, the paper changes.
3. Formula alignment: all tests serve dρ/dt = −k₁(ρ − ρ₁) − k₂(ρ − ρ₂).
4. **Break circularity:** measure the explanatory variable (integration depth) independently of the outcome (trait loss).
5. **Watch for valence-seeking signatures:** any result that reveals the thermodynamic character of the relaxation (floor behavior, cross-system parameter conservation, rate-constant regularities) should be flagged.

---

## R1: Integration-Depth Ordering with Independent GRN Data (Recast 1 — Sequence Test)

**Jury demand:** "If integration depth is measured from trait-loss data, predicting trait loss from integration depth is circular. Needs a priori measurement from independent developmental-genetic data."

**System:** *Astyanax mexicanus* (cavefish) — multiple independent cave colonizations, known surface ancestor, well-documented trait loss (eyes, pigmentation, circadian, metabolism).

**Question:** Do low-integration-depth traits (measured independently from GRN data) change first in cavefish evolution?

**Data sources:**
- **Trait loss data:** McGaugh et al. (2014) RNA-seq at 4 developmental stages across surface, Pachón, Tinaja cavefish. NCBI SRA. Gross et al. (2019) for *Asellus aquaticus* (cave isopod) as replication.
- **Integration depth (INDEPENDENT):**
  - STRING database protein-protein interaction network for *Astyanax* homologs (via zebrafish orthology). Metric: network degree (number of interaction partners).
  - **Dependency depth:** longest path from each gene to a terminal node in the GRN. Computed from RegulonDB-style regulatory data (for bacterial homologs) or AnimalTFDB (for animal transcription factors).
  - **Developmental timing:** expression onset from zebrafish developmental atlases (ZFIN). Early-expressed genes = deeper integration (more downstream dependents). Late-expressed = shallow.
- **Three independent metrics:** STRING degree, dependency depth, developmental timing. If all three agree on the ordering, the circularity critique is broken.

**Method:**
1. Classify cavefish lost traits (eye genes, pigment genes, circadian genes, metabolic genes) by each integration-depth metric independently.
2. Order trait loss by developmental timing of expression change (from RNA-seq: when does expression diverge between surface and cave?).
3. Test: does integration depth (measured from STRING/AnimalTFDB/ZFIN) predict loss order (measured from RNA-seq)?
4. Statistical test: Spearman's ρ between integration-depth rank and loss-timing rank. Permutation test for significance.
5. **Comparison models:** random ordering (null), gene expression level (alternative — highly expressed genes might be lost last regardless of integration depth), gene length (alternative — longer genes might be lost first due to larger mutation target).

**Prediction from VI:** Low integration-depth traits lost first. ρ > 0, p < 0.05 across all three metrics.

**Prediction from relaxed selection:** No ordering predicted. Any of the three metrics should show ρ ≈ 0.

**Opportunistic signals to watch:**
- If the floor (ρ_eq) is visible — some traits are never lost regardless of cave colonization time — note which traits and their integration depth. This is the niche-defined minimum.
- If the rate of trait loss decelerates over developmental time (fast early changes, slow late changes) — this is the bi-exponential tempo in developmental time, which would be a substrate-independence signal (VI operating at ontogenetic timescale).
- If the ordering is consistent across independent cave colonizations (Pachón vs. Tinaja vs. Molino) — this is the integration-depth ordering operating as a convergent attractor.

**Falsification:** If none of the three metrics predict loss order, integration-depth ordering is not supported when measured independently. The core claim is in trouble.

**Data readiness:** All data public. STRING, AnimalTFDB, ZFIN, NCBI SRA. Computational — no new experiments.

**Status:** READY TO QUEUE.

---

## R2: DD Sign Survey (Recast 4 — Substrate Type Diagnostic)

**Jury demand:** "If you observe positive DD in any clade, you should look for a generative substrate. If you observe negative DD, the substrate is finite." Need: operational definition of "generative substrate" independent of DD sign, and more than Homo as the positive case.

**System:** Phillimore & Price (2008) compiled DD estimates for 45 clades. Plus extension to sexual selection clades (cichlids, birds of paradise, túngara frogs).

**Question:** Is DD sign a reliable diagnostic of substrate type (generative vs. ecological) across clades?

**Data sources:**
- **DD estimates:** Phillimore & Price (2008) — 45 clades with Bayesian DD posterior estimates. Published supplementary data.
- **Substrate classification (INDEPENDENT):**
  - Cultural transmission: does the clade have social learning, vocal learning, tool use, or cumulative culture? Source: Animal Behaviour literature, AvianBrain.org, PrimateBrain.org.
  - Sexual selection generativity: does the clade have combinatorial mating signals (multi-component displays, learned songs)? Source: Ryan & Cummings (2013), Iwaniuk & Arnold (2004).
  - β measurement (where possible): for clades with sufficient data, compute β from signal/behavior diversity data. Source: Macaulay Library (bird songs), Cichlid Genome Consortium.
- **Three classification sources:** cultural transmission databases, sexual signal complexity literature, direct β measurement where feasible.

**Method:**
1. For each of 45 Phillimore & Price clades, classify substrate as generative (cultural transmission or combinatorial sexual selection) or ecological (finite niche space).
2. Cross-tabulate: generative substrate × DD sign (positive/negative/zero).
3. Test: Fisher's exact test. Prediction: all positive DD clades have generative substrates; all negative DD clades have ecological substrates.
4. **Extension:** Add sexual selection clades not in Phillimore & Price (cichlids, birds of paradise, túngara frogs, Satin bowerbirds). Do these show positive DD? If yes, do they have combinatorial signal spaces (β > 1)?
5. **β measurement for selected clades:** For 3-5 clades with sufficient data, compute β from behavioral/signal diversity data. Does β > 1 predict positive DD?

**Prediction from VI:** Perfect (or near-perfect) correspondence between substrate type and DD sign. β > 1 ⟺ positive DD.

**Prediction from standard DD theory:** No systematic relationship. Positive DD is rare and unexplained.

**Opportunistic signals to watch:**
- If sexual selection clades with combinatorial signals (β > 1) show positive DD — this extends the β > 1 → positive DD prediction beyond Homo and culture to a new domain (sexual selection). This would be a major extension.
- If there's a graded relationship (β value correlates with DD coefficient magnitude, not just sign) — this would mean β is not just a binary diagnostic but a quantitative predictor of diversification rate. This would connect niche generativity to macroevolutionary dynamics directly.
- If any clade shows β > 1 but negative DD — this would falsify the prediction. Note the exception and investigate whether the substrate is generative but the niche is saturating (β > 1 with finite niche space — possible if the generative substrate hasn't found an expanding niche yet).

**Falsification:** If a clade with a generative substrate (β > 1) shows negative DD, or a clade with an ecological substrate shows positive DD, the diagnostic claim fails.

**Data readiness:** Phillimore & Price data public. Substrate classification requires literature review. β measurement for selected clades feasible with Macaulay Library + cichlid data.

**Status:** READY TO QUEUE.

---

## R3: Dollo Threshold — Retention Check (Recast 3 — Downgraded to TACK ON, but falsifiable)

**Jury demand:** "Check whether all Dollo violations are retained-then-reactivated traits, not de novo re-evolutions." Also: "Find truly lost traits and measure their integration depth for threshold calibration."

**System:** Three documented Dollo "violations" + calibration set of truly lost traits.

**Question:** Are all Dollo "violations" cases where the developmental program was retained during the loss phase?

**Data sources:**
- **Stick insect wings:** Goldberg & Igić (2008) — already found likely retention. Verify with current genomic data (vision/ wing development gene sequences in wingless stick insects vs. winged relatives).
- **Frog teeth:** Wiens (2011) — re-examine. Are dental lamina genes (SHH, PITX2, MSX1, RUNX2) retained as functional ORFs in toothless frogs? Source: NCBI genomes for *Gastrotheca*, *Hemiphractus*, toothless ranids.
- **Coelacanth lungs:** Check whether lung surfactant protein genes (SFTPA, SFTPB, SFTPC) are retained in *Latimeria*. Source: NCBI *Latimeria chalumnae* genome.
- **Calibration set (truly lost traits):** Olfactory receptor (OR) pseudogenes in primates. How many OR genes are pseudogenized in humans, chimps, gorillas? Source: HORDE database, NCBI. What is their integration depth (STRING degree, dependency depth)? If truly lost traits have low integration depth, this calibrates the lower end of the threshold.

**Method:**
1. For each Dollo "violation" case, check: are the developmental genes for the "lost" trait still present as functional ORFs (not pseudogenized)?
2. If yes → the trait was retained developmentally, not re-evolved. VI's prediction holds.
3. If no → true de novo re-evolution. VI's threshold claim needs revision.
4. For the calibration set: measure integration depth (STRING degree) of truly lost OR genes. Compare to integration depth of retained developmental genes in the Dollo "violation" cases. Is there a clear separation?

**Prediction from VI:** All three Dollo "violations" show retained developmental programs. Truly lost traits (OR pseudogenes) have lower integration depth than retained traits.

**Opportunistic signals to watch:**
- If the integration-depth distribution of retained vs. truly lost traits shows a clean bimodal distribution — the threshold is at the gap between the two modes. This would give us the quantitative threshold the jury demanded.
- If some "truly lost" OR genes are actually retained (functional in some tissues) — this narrows the set of truly lost traits and supports VI's claim that most "losses" are actually silencing.
- If any Dollo case shows partial pseudogenization (some genes in the pathway lost, others retained) — this would show the threshold operates at the pathway level, not the trait level. Integration depth is a network property.

**Falsification:** If a Dollo "violation" is a true de novo re-evolution (developmental genes fully lost, then rebuilt from scratch), VI's threshold claim fails for that case.

**Data readiness:** NCBI genomes public for all target species. STRING database public. HORDE database public. Computational — no new experiments.

**Status:** READY TO QUEUE.

---

## R4: Brain Expansion Temporal Precedence (Recast 7 — Culture Drives Brains)

**Jury demand:** "If brains lead tools, VI is wrong on this recast." Review existing lag test results first. If positive, extend.

**Question:** Does cultural complexity precede brain expansion in the hominin record, with a lag consistent with k₁/k₂ dynamics?

**Data sources:**
- **Brain size:** Cranial capacity estimates from fossil crania. Source: DeSilva et al. (2021) hominin endocranial volume database. ~200 fossil crania, 3 Myr.
- **Cultural complexity:** Tool diversity (mode count), artifact complexity (Stout & Chaminade 2007 complexity index). Source: Published archaeological compendia, Shea (2017) lithic typology.
- **Existing lag test:** `data/brain-expansion-lag-test.md` in the monograph data. Review what it shows.

**Method:**
1. Time-bin the hominin record (200 kyr bins from 3 Myr to present).
2. For each bin: mean cranial capacity, tool diversity count, artifact complexity index.
3. Cross-correlation: does cultural complexity lead brain size, or does brain size lead cultural complexity?
4. Granger causality: does cultural complexity at time t predict brain size at time t+lag better than brain size alone?
5. If cultural complexity leads: estimate the lag. Is it consistent with k₁ (fast phase, ~100 kyr?) and k₂ (slow phase, ~1 Myr?) timescales?
6. **Comparison model:** Social brain hypothesis — does group size (proxied by settlement size, which is rare in the fossil record) predict brain size better than cultural complexity?

**Prediction from VI:** Cultural complexity Granger-causes brain size with a positive lag. The lag structure is biphasic (fast initial response, slow refinement).

**Prediction from social brain:** Brain size predicts social complexity. Cultural complexity is a consequence, not a cause.

**Opportunistic signals to watch:**
- If the lag is measurable and biphasic — this would be the first bi-exponential fit to an inbound (capacity gain) trajectory. **This is the deepest gap the jury identified.** If it works, it transforms the monograph from "loss theory" to "change theory."
- If cultural complexity plateaus before brain size does — this would mean the attractor (ρ_eq) is set by the cultural substrate, and brain size is relaxing toward it. When the substrate stops moving, brain size continues to relax (k₂ phase) toward the now-stationary attractor. This is a moving-attractor bi-exponential, which is the most general form of the rate law.
- If there are periods where brain size increases without cultural complexity increase — this could mean the attractor is set by something other than tools (social structure, language). Investigate what cultural variables lead brain size during those periods.

**Falsification:** If brain size consistently leads cultural complexity (Granger causality runs brain → tools, not tools → brain), VI's causal inversion is wrong. The social brain hypothesis wins.

**Data readiness:** Fossil data public. Tool data from published literature. Time-binning requires careful handling of temporal uncertainty. Existing lag test results to review.

**Status:** READY TO QUEUE. Review existing `brain-expansion-lag-test.md` first.

---

## R5: Endosymbiont Tempo — Bi-Exponential vs. Single-Exp-with-Floor (Recast 1 — Tempo Test)

**Jury demand:** "The plateau is not unique to VI. Compare against single-exponential-with-floor, not just linear."

**Question:** Does genome reduction in endosymbionts follow bi-exponential decay (two rate constants) better than single-exponential decay to a floor (one rate constant)?

**Data sources:**
- **Endosymbiont genomes:** 22+ genera with time-calibrated divergence estimates. NCBI RefSeq. Fisher et al. (2017) for host-dependence data.
- **Time calibration:** Molecular clock estimates for symbiosis establishment. Published per-clade.
- **Existing foundry data:** `results/p1-p8-testing/endosymbiont-results.md` and pipeline stage `t3_endosymbiont_biphasic`.

**Method:**
1. For each endosymbiont lineage: genome size vs. time since symbiosis establishment.
2. Fit four models: (a) linear, (b) single-exponential to floor (3 params: k, ρ_eq, intercept), (c) bi-exponential to floor (5 params: k₁, k₂, ρ_eq, ρ₁, ρ₂), (d) power-law.
3. Compare via AIC/BIC. The jury's demand: bi-exponential must beat single-exp-with-floor, not just linear.
4. Cross-lineage: fit k₁ and k₂ across multiple lineages. Are the rate constants conserved? If yes, this is the cross-kingdom parameter transfer extended to endosymbionts.
5. **Pre-registration:** Define ρ as genome coding content (coding bases, not total genome size — exclude TEs and non-coding). Define floor as the minimum observed genome size across endosymbionts. These definitions are set before fitting.

**Prediction from VI:** Bi-exponential beats single-exponential-with-floor (ΔAIC > 10). k₁ >> k₂. The floor is ρ_eq (niche-defined minimum, not mutation-selection balance).

**Prediction from mutation-selection balance:** Single-exponential-with-floor fits as well or better. The floor is mutation-selection balance.

**Opportunistic signals to watch:**
- If k₁/k₂ ratios are similar across endosymbiont lineages — the rate constants are conserved, suggesting a common underlying mechanism. This is the substrate-independence signal.
- If the floor varies by host type (plant hosts vs. animal hosts) — the niche defines the floor (ρ_eq), not thermodynamics. Different hosts demand different minimal gene sets.
- If some lineages show no floor (continued reduction toward zero) — this would mean ρ_eq is very low for that lineage, or the lineage hasn't reached equilibrium yet. Either way, it tells us about the attractor.
- **Valence-seeking signal:** If the approach to the floor decelerates in a way that matches the chemical potential relaxation form (J = −L∇μ), this is the thermodynamic character. The rate of change should be proportional to the distance from equilibrium — if dρ/dt scales linearly with (ρ − ρ_eq), that's first-order relaxation, the same form as chemical kinetics.

**Falsification:** If single-exponential-with-floor fits as well as bi-exponential (ΔAIC < 10), the biphasic claim is not supported for endosymbionts. The plateau is real but not biphasic.

**Data readiness:** All data public. Existing foundry pipeline stage `t3_endosymbiont_biphasic` already implemented. Extend to compare against single-exp-with-floor model.

**Status:** READY TO QUEUE. Extend existing pipeline stage.

---

## R6: C4 Inbound Bi-Exponential (The Deepest Gap)

**Jury demand (both panels):** "The inbound direction is the deepest gap. If we can fit dρ/dt for a convergence system, that transforms the monograph from 'loss theory' to 'change theory.'"

**Question:** Does C4 photosynthesis acquisition follow bi-exponential kinetics across independent origins?

**Data sources:**
- **C4 origins:** Christin et al. (2011, 2012) — dated C4 origins across 8+ independent grass lineages. TreeBASE S11973.
- **C4 "completeness" (ρ):** Number of C4-specific modifications per lineage — convergent amino acid changes (from Christin et al. 2007), C4 gene duplications, Kranz anatomy features. Source: Christin et al. (2007) supplementary, GrassBase.
- **Time since origin:** Molecular clock estimates per lineage. Christin et al. (2011).

**Method:**
1. For each C4 lineage: measure "C4 completeness" (count of convergent modifications) vs. time since C4 origin.
2. Fit bi-exponential: ρ(t) = ρ_eq − A₁e^(−k₁t) − A₂e^(−k₂t). This is the inbound form — capacity gain toward an equilibrium.
3. Compare to: linear, single-exponential, power-law, logistic.
4. Cross-lineage: are k₁ and k₂ conserved across independent C4 origins? If yes, the dynamics are substrate-independent for the inbound direction too.
5. **Pre-registration:** Define "C4 completeness" as the count of C4-specific convergent amino acid changes in PEPC + PDK + NADP-ME. Define ρ_eq as the total number of known C4 convergent sites (the "complete" C4 syndrome).

**Prediction from VI:** Bi-exponential inbound fit. k₁ (fast acquisition of core C4 changes) >> k₂ (slow fine-tuning). Rate constants conserved across lineages.

**Opportunistic signals to watch:**
- **This is THE test for valence-seeking.** If the inbound bi-exponential fits, it means the rate law works in both directions — loss and gain. The relaxation dynamics are symmetric. This would mean valence-seeking operates on capacity gain the same way it operates on capacity loss — the organism relaxes toward the niche-defined equilibrium regardless of direction.
- If the rate constants for inbound (C4 gain) are different from outbound (endosymbiont loss) — the dynamics are direction-asymmetric. This would mean loss and gain are governed by different rate constants, which is physically interesting (like chemical reactions where forward and reverse rates differ).
- If k₁/k₂ ratios are conserved between inbound and outbound — this would be the strongest possible evidence that the rate law is a fundamental property of the organism-niche system, not an artifact of one direction. This would be the signature of valence-seeking as a universal dynamics.
- If some C4 lineages are "incomplete" (haven't reached the full C4 syndrome) and their incompleteness is predicted by their age (younger lineages less complete) — this is the relaxation trajectory in progress. Living examples of the inbound trajectory at different stages.

**Falsification:** If C4 completeness is linear with time (constant acquisition rate), or shows no relationship with time, the bi-exponential inbound claim fails. The monograph remains a "loss theory."

**Data readiness:** C4 convergence data from Christin et al. (2007, 2011). Molecular clock dates public. Grass phylogeny from TreeBASE. Needs compilation of C4 completeness scores per lineage — this is a literature synthesis task.

**Status:** READY TO QUEUE. This is the highest-value test in the queue — it addresses the deepest gap both panels identified.

---

## Execution Priority

| Priority | Test | What it establishes | Data ready? | Effort |
|----------|------|---------------------|-------------|--------|
| **1** | R1 (cavefish sequence) | Integration-depth ordering with independent data — **breaks circularity** | Yes | Medium (GRN data compilation + RNA-seq analysis) |
| **2** | R2 (DD sign survey) | β > 1 ⟺ positive DD — **strongest novel prediction** | Yes | Medium (literature classification + stats) |
| **3** | R6 (C4 inbound) | Bi-exponential for capacity gain — **transforms loss theory to change theory** | Yes | Medium (C4 completeness compilation + fitting) |
| **4** | R5 (endosymbiont tempo) | Bi-exponential beats single-exp-with-floor — **tempo claim robust** | Yes (extend existing) | Small (add comparison model to existing pipeline) |
| **5** | R4 (brain expansion) | Culture drives brains — **causal inversion** | Yes (review existing first) | Medium (time-series analysis) |
| **6** | R3 (Dollo threshold) | All violations are retained traits — **falsifiable** | Yes | Small (genomic checks) |

R1 and R2 are the two tests the jury said would "establish or break the program." R6 is the test that would transform the program's scope. Run all three in parallel if possible.

---

## Connection to Valence-Seeking

The jury (both panels) said: "the novel predictions are the ordering and the floor, not the bi-exponential form itself." These tests are designed to probe both:

- **The ordering** (R1, R3): Does integration depth, measured independently, predict the sequence of trait change?
- **The floor** (R5, R6): Is there a niche-defined minimum (ρ_eq) that the system relaxes toward? Does the approach to the floor follow the rate law?
- **The rate constants** (R5, R6): Are k₁ and k₂ conserved across systems? Are they conserved between inbound and outbound directions?

If the rate constants are conserved across kingdoms AND across directions (inbound/outbound), that is the signature of valence-seeking as a universal dynamics — the same process operating on different substrates, in different directions, at different scales. That's the thermodynamic character. Watch for it.
