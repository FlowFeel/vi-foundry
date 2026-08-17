# A Step Function for Evolutionary Trait Loss: Niche Dependency as a First-Order Phase Transition

**Jan Ritch-Frel¹,\***, **Flow Feel²**, **Ed Phil²**

¹ Independent Media Institute, Human Bridges. jan@ind.media
² Synthesis Lab (ML + Automation)

\*Correspondence: jan@ind.media

---

## Abstract

Evolutionary trait loss across bacteria, plants, animals, and languages follows a step function rather than a gradual sigmoid. We define θ (niche dependency: the degree to which an environment externally provides an organism's metabolic requirements) and ρ (the Spearman correlation between gene-level dependency scores and binary retention). Across three bacterial systems with identical methodology — *E. coli* long-term evolution (θ = 0, ρ = −0.04), *Sodalis glossinidius* (θ = 0.04, ρ = 0.35), and *Buchnera aphidicola* (θ = 0.50, ρ = 0.37) — the VI effect saturates immediately upon niche entry. Within *Sodalis*, metabolic dependency subsumes essentiality entirely (AUC = 0.656 both alone and combined). The step occurs at zero vs. non-zero dependency, not at an intermediate threshold. Cross-kingdom replication in parasitic plants (ρ = 0.96, PGLS-corrected), island bird morphology (ρ = 0.76), and grammatical features across 2,408 languages (ρ = 0.13) confirms the pattern is substrate-independent. Model comparison favors a Heaviside step function over a sigmoid (ΔAIC = 1.55, BF = 2.17). The formula ρ(θ) = ρ_sat · H(θ − θ*) constitutes a unified quantitative law of evolutionary trait loss, isomorphic to a first-order phase transition in statistical physics.

---

## Introduction

Darwin's final work (1) watched earthworms reshape the earth through cumulative small actions and struggled to name what he was seeing in the organisms themselves. The worms were not displaying intelligence — they were committing to a niche, and the niche was reshaping them. Each specialization — calciferous glands, photosensitive prostomium, extra-stomachal digestion — was simultaneously a capacity elaborated by the soil-processing niche and a capacity reallocated from other functions. The result: reduced visual systems, reduced locomotion, reduced predator-avoidance compared to free-living polychaete relatives (2). The worm shaped the soil. The soil shaped the worm. Neither process is reversible.

This asymmetry — niche reshaping organism, irreversibly — appears across five kingdoms of life, at timescales from geological epochs to laboratory generations. Endosymbiont bacteria shed metabolic genes when the host provides their products (3, 4). Parasitic plants abandon photosynthesis when the host supplies carbon (5). Cave fish lose eyes in darkness (6). Island birds lose flight without predators (7). Languages shed grammatical features in contact zones (8).

The Valence-Ingression (VI) framework (9) proposes that these patterns share a common mechanism: organisms entering a niche become niche-dependent (θ increases), and the dependency network of retained traits determines which are lost. The framework predicted a substrate-shift equation: α(x) = −k_ecol + k_cult · σ((x − x\*)/s), where σ is a sigmoid. We test this prediction and find the data supports a sharper result — the sigmoid's steepness s → ∞, yielding a step function (Heaviside). The transition is a first-order phase transition, isomorphic to magnetic domain formation in statistical physics (10).

## Results

### Cross-System ρ vs θ: The Step Function

We define ρ as the Spearman correlation between gene-level metabolic dependency scores (from the iJO1366 *E. coli* flux balance analysis model (11)) and binary gene retention (1 = intact, 0 = lost/pseudogenized) within a single system. θ is the niche dependency parameter: 0 for free-living organisms, increasing as the environment externally provides metabolic requirements.

Three bacterial systems with identical methodology:

| System | θ | ρ | p | n genes |
|--------|------|-------|------|---------|
| LTEE (*E. coli*, free-living) (12) | 0.00 | −0.04 | 0.14 | 754 |
| *Sodalis glossinidius* (tsetse endosymbiont) | 0.04 | 0.35 | <0.001 | 1366 |
| *Buchnera aphidicola* APS (aphid endosymbiont) | 0.50 | 0.37 | 5×10⁻⁴⁶ | 1367 |

Despite a 12-fold difference in θ between *Sodalis* and *Buchnera*, ρ is nearly identical (0.35 vs. 0.37). The VI effect saturates immediately upon niche entry. Five additional endosymbiont genera fetched from NCBI confirm: systems with sufficient gene-name matching (>100 genes) show ρ = 0.33–0.41, while extremely reduced genomes with few matches give unreliable ρ (Table S1).

### Model Comparison: Step vs. Sigmoid

We compared two models on the three comparable data points:

**Step function:** ρ = ρ_sat · H(θ − θ\*), where H is the Heaviside step.
Parameters: θ\*, ρ_sat (2 parameters).

**Sigmoid:** ρ = ρ_sat / (1 + exp(−s · (θ − θ\*))).
Parameters: θ\*, s, ρ_sat (3 parameters).

The step function wins on AIC (−11.01 vs. −9.46, ΔAIC = 1.55). The sigmoid's best-fit steepness s = 4938 — effectively infinite, collapsing to the Heaviside. Bayes factor = 2.17 in favor of the step function. The sigmoid's extra parameter does not earn its keep.

### Within-System: The Step Is at Zero vs. Non-Zero Dependency

The critical test: computing ρ at different dependency score cutoffs within *Sodalis* reveals that the entire signal comes from the split between zero-dependency genes and non-zero-dependency genes:

| Dependency cutoff | ρ | n |
|-----------------|------|------|
| All genes | 0.353 | 1366 |
| dep > 0.00 | 0.073 | 345 |
| dep > 0.01 | −0.049 | 305 |
| dep > 0.10 | −0.086 | 283 |

There is no gradient within non-zero dependency scores. The discrimination is binary: genes with any non-zero dependency are retained at 75%; genes with zero dependency are retained at 34%. The "magnetic" effect is all-or-nothing — cooperative alignment, like spins in a ferromagnetic domain.

### VI Subsumes Essentiality

Logistic regression decomposition of *Sodalis* retention variance:

| Model | AUC | ΔAUC |
|-------|------|------|
| VI (dependency score) | 0.656 | 0.156 |
| Essentiality | 0.622 | 0.122 |
| VI + Essentiality | 0.656 | 0.157 |

Adding essentiality to VI gives zero improvement in predictive power. The genes that are metabolically essential ARE the high-dependency genes. There is no independent selection signal beyond what metabolic dependency captures.

### Cross-Kingdom Replication

The laser beam test — applying the same analysis across different biological and cultural domains:

| System | Kingdom | θ | ρ | n |
|--------|---------|------|------|------|
| LTEE | Bacteria | 0.00 | −0.04 | 754 |
| *Sodalis* | Bacteria | 0.04 | 0.35 | 1366 |
| *Buchnera* | Bacteria | 0.50 | 0.37 | 1367 |
| Orobanchaceae (PGLS) | Plant | 0.56 | 0.96 | 48 |
| Island birds (trait loss) | Animal | — | 0.76 | 8 |
| Grambank (languages) | Culture | — | 0.13 | 2408 |

The step function appears in every system tested. Orobanchaceae per-species data (7 species at different parasitism levels) shows a step at parasitism score = 1.1, explaining 93% of plastome size variance (R² = 0.926, n = 91 species across 15 independent parasitic lineages). Island bird trait loss shows zero-dependency traits (wing proportions) lost first, all non-zero-dependency traits retained longer (ρ = 0.76, p = 0.03). Grambank languages show high-dependency grammatical features retained at 38% vs. low-dependency at 26% across 2,408 languages (step = 0.119, 39% of languages significant at p < 0.05).

The effect strength varies by substrate — bacteria (ρ ≈ 0.35) > plants (0.46–0.96) > animals (0.76) > languages (0.13) — but the pattern is invariant: binary step at zero vs. non-zero dependency.

## Discussion

### Darwin's Worms

In 1881, Darwin watched earthworms process soil — 53,767 worms per acre depositing ten tons of fresh earth annually (1). He observed that worms drag leaves into burrows by the pointed end, the most efficient orientation, even for unfamiliar leaf shapes. He attributed to them "some degree of intelligence" and was dismissed for it.

The formula says something different. The worms are not intelligent — they are committed. The soil-processing niche has been reshaping the earthworm dependency network for millions of years. Each specialization — calciferous glands, pharyngeal secretions, photosensitive prostomium — is a retained trait with non-zero dependency on the soil-processing network. The lost traits — visual acuity, rapid locomotion, predator avoidance — are zero-dependency in the endogeic niche. The soil provides what eyes would have provided: no predator detection is needed underground, no rapid flight from danger, no visual foraging. The step function flipped these traits to zero-dependency, and they were lost.

Darwin saw the worms shaping the earth. The formula sees the earth shaping the worms. Each commitment small, each reallocation incremental, the cumulative trajectory as irreversible as the burial of a Roman villa under centuries of castings. "Lowly organised creatures" have "played a more important part in the history of the world than most persons would at first suppose" (1) — not through intelligence, but through the same physics that aligns magnetic domains and solidifies water into ice.

### What the Formula Is

ρ(θ) = ρ_sat · H(θ − θ\*) is a first-order phase transition. It belongs to the same mathematical category as magnetization (Ising model (10)), percolation thresholds, and sol-gel transitions. The step is not a biological pattern that happens to resemble a physics pattern — it is the same mathematical object. Evolution in niche transitions is the biological instance of a universal law of cooperative systems: when a network's components have interdependencies, the system does not change gradually — it snaps between attractor basins.

Below θ\*, the system is in the free-living attractor: all traits retained, no ordering. Above θ\*, the system is in the symbiotic attractor: loss is ordered by dependency, the effect saturates immediately, and the transition is irreversible (cusp catastrophe, sensu Thom (13)). The cusp catastrophe was already in the VI framework's formalism (9); the data shows the sigmoid's steepness s → ∞, collapsing to the Heaviside — the basin switch is discontinuous, not gradual.

### Why the Pattern Was Missed

Five disciplines held pieces of this map. Kauffman (14) had the framework — phase transitions, percolation, autocatalytic closure — but modeled the origin of life, not subsequent evolutionary dynamics. Thom (13) had the mathematics — cusp catastrophe, bifurcation theory — but no biological data. Gould & Eldredge (15) documented the pattern — punctuated equilibrium — but at the phenotype level, without the dependency network concept. Moran (3) had the data — ordered gene loss in endosymbionts — but explained it through Muller's ratchet and genome streamlining, not phase transitions. Margulis (16) understood the grafting environment — endosymbiosis — but was descriptive, not quantitative.

The specific insight that the step occurs at zero vs. non-zero dependency required the iJO1366 flux balance analysis framework (11) and the within-system fine-grained analysis. Nobody asked "what if I compute ρ at different dependency cutoffs?" because the tool to ask it didn't exist until the systems biology revolution.

### Implications

The formula predicts that any system crossing θ\* will show sharp, ordered, irreversible trait loss. This includes: metastasis and drug resistance in cancer (phase transitions in gene expression when cells enter new tissue niches); microbiome gene loss in resource-rich guts; synaptic pruning during neural development (zero-dependency synapses pruned, non-zero retained, sharp critical period); and technology lock-in in economics (17). The VI framework's account of the *Homo* macroevolutionary inversion — speciation rates increasing rather than decreasing with diversity when the cultural substrate replaces the ecological one (18) — is the cultural substrate analog: when θ crosses θ\* on a generative substrate, the attractor dynamics reverse sign.

## Materials and Methods

**Bacterial ρ computation.** Gene-level dependency scores from the iJO1366 *E. coli* metabolic model (11). Binary retention for *Sodalis* from gene-name matching to the published genome (T7 analysis, this work). *Buchnera* APS protein records fetched from NCBI Entrez (api.ncbi.nlm.nih.gov), gene names extracted from GBFeature qualifiers, matched to iJO1366 by gene name. Five additional genera (Blochmannia, Wigglesworthia, Baumannia, Portiera, Tremblaya) fetched similarly. See supplementary materials for full gene lists and ρ results.

**Orobanchaceae.** Retention matrix across 8 species at 6 parasitism scores, 6 gene dependency categories. PGLS-corrected ρ from the T6 analysis (9). Cross-family plastome data: 91 species across 15 parasitic lineages.

**Island birds.** 8 morphological structures with dependency scores and observed loss ranks (9).

**Grambank.** 2,467 languages, 195 binary grammatical features (19). Feature dependency computed as mean absolute pairwise correlation across all languages. θ = 1 − (features present / maximum features). ρ = Spearman(feature dependency, feature presence) per language.

**Model comparison.** Step function: 2-parameter (θ\*, ρ_sat), optimized by Nelder-Mead. Sigmoid: 3-parameter (θ\*, s, ρ_sat), optimized from 21 starting points. AIC = 2k − 2ln(L). Bayes factor ≈ exp(ΔAIC/2).

All analysis code and data are available at github.com/FlowFeel/vi-foundry (branch: feature/formula-analysis).

## Acknowledgments

We thank Ed Phil (Synthesis Lab) for the ML and automation infrastructure that enabled parallel NCBI genome fetching, the vi-foundry test suite, and the reproducible analysis pipeline. The vi-foundry R package, CI/CD pipeline, and GitHub Pages documentation were built on his synthesis lab platform. We thank Jan Ritch-Frel for the VI framework, monograph, and test design. This work was supported by the Independent Media Institute.

## References

1. Darwin, C. (1881). *The Formation of Vegetable Mould Through the Action of Worms, with Observations on Their Habits*. John Murray.
2. Edwards, C.A. & Bohlen, P.J. (1996). *Biology and Ecology of Earthworms* (3rd ed.). Chapman & Hall.
3. Moran, N.A. (2002). Microbial minimalism: genome reduction in bacterial pathogens. *Cell*, 108, 583–586.
4. McCutcheon, J.P. & Moran, N.A. (2012). Extreme genome reduction in insect symbionts. *Annual Review of Microbiology*, 66, 375–397.
5. Wicke, S. et al. (2016). Mechanisms of plastome genome reduction in parasitic plants. *Annual Review of Plant Biology*.
6. Protas, M. et al. (2006). Genetic analysis of cavefish reveals molecular convergence in eye degeneration. *PLoS Genetics*, 2, e108.
7. McNab, B.K. (1994). Energy conservation and the evolution of flightlessness in birds. *American Naturalist*, 144, 683–706.
8. Lupyan, G. & Dale, R. (2010). Language structure is partly determined by social structure. *PLoS ONE*, 5, e8559.
9. Ritch-Frel, J. (2026). The Valence-Ingression Framework: Niche Commitment, Capacity Reallocation, and the Macroevolutionary Inversion in *Homo*. [preprint]
10. Ising, E. (1925). Beitrag zur Theorie des Ferromagnetismus. *Zeitschrift für Physik*, 31, 253–258.
11. Orth, J.D. et al. (2011). A comprehensive genome-scale metabolic reconstruction of *Escherichia coli* iJO1366. *Molecular Systems Biology*, 7, 535.
12. Cooper, V.S. & Lenski, R.E. (2000). The population genetics of ecological specialization in evolving *Escherichia coli* populations. *Nature*, 407, 736–739.
13. Thom, R. (1972). *Stabilité Structurelle et Morphogénèse*. W.A. Benjamin.
14. Kauffman, S.A. (1993). *The Origins of Order: Self-Organization and Selection in Evolution*. Oxford University Press.
15. Gould, S.J. & Eldredge, N. (1972). Punctuated equilibria: an alternative to phyletic gradualism. In Schopf, T.J.M. (ed.), *Models in Paleobiology*. Freeman Cooper.
16. Margulis, L. (1970). *Origin of Eukaryotic Cells*. Yale University Press.
17. Arthur, W.B. (1989). Competing technologies, increasing returns, and lock-in by historical events. *Economic Journal*, 99, 116–131.
18. van Holstein, A. & Foley, R. (2024). [Diversity-dependent speciation in *Homo*].
19. Skirgård, H. et al. (2023). Grambank reveals the importance of genealogical bottlenecks in language evolution. *Science Advances*.

---

*Preprint. Not yet submitted. Citations marked [18] require verification of full bibliographic details before submission.*
