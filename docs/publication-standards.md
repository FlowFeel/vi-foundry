# Publication Standards for Theoretical Evolutionary Biology: A Rate-Law Acceptance Guide

> **Purpose:** Actionable intelligence on what specific evidence package would pass peer review at *Evolution*, *American Naturalist*, or *PNAS* for a proposed new rate law in evolutionary biology.
>
> **Date:** 2026-08-18
> **Status:** Research report

---

## 1. Journal-Specific Thresholds

### 1.1 PNAS (Proceedings of the National Academy of Sciences)

**Desk-rejection rate:** >50% — most papers fail at editorial triage.

**Key filters:**
- **Exceptional importance** — must advance understanding in a "clear, definable way" that is "groundbreaking," not incremental
- **Broad significance** — must be intelligible to a non-specialist scientific audience. This is the #1 filter. A weak or unclear 120-word **Significance Statement** is the most common cause of desk rejection.
- **Methodological soundness** — "unambiguous data, proper analysis, and conclusions supported by data"
- **Length limit:** ~6 PNAS pages (~4,000 words + 6 display items); unlimited Supporting Information
- **Data & code:** must be publicly deposited; code "central to the conclusions" must be available

**Implication for a rate law:** The Significance Statement must convince a molecular biologist, a physicist, and a social scientist that the rate law matters. This is a much higher bar than technical correctness. The paper must have a clear "so what" that reaches beyond evolutionary biology.

### 1.2 American Naturalist

**Stance on theoretical work:** Explicitly welcomes "papers that develop new conceptual syntheses, pose novel and important problems, introduce new subjects, or fundamentally alter existing perspectives."

**Key criteria:**
- **Broad interest** — must "change the way people think about a subject"
- **Biological motivation** — theory must explain or anticipate a *biological phenomenon*, not just be mathematically interesting. Must provide "specific biological examples" and relate model assumptions to biological contexts. Ideally compare model output to "relevant empirical data."
- **Novelty** — new ideas, merging existing ideas in innovative ways, or compelling evidence for established ideas. "Inflating novelty by omitting relevant published studies is discouraged."
- **Code mandate** — as of January 2022, all analysis and simulation code must be archived in a public repository. Data editors check repositories for completeness.
- **Best Practices Checklist** (optional but recommended) — includes emphasis on biological motive, ensuring theory is not developed in isolation from empirical phenomena.

**Implication for a rate law:** *Am Nat* is the natural home for a rate law paper. The requirement to relate model output to empirical data is critical — the paper needs at least one worked empirical example showing the rate law fits real data.

### 1.3 Evolution

**Explicitly welcomes** "Original Articles" that report "important theoretical advances" and "theoretical investigations that broaden our understanding of evolutionary phenomena and processes at all levels of biological organization."

**Structure expectations:**
- Abstract + Keywords (IMRAD)
- Introduction (succinct, no subheadings)
- Materials and Methods (detailed for reproducibility)
- Results (findings from models/analyses)
- Discussion (prior work, limitations, future directions)
- **Word limit:** 7,500 words (excluding abstract, tables, captions, references)
- Double-anonymous peer review

**Implication:** *Evolution* is the most technically permissive of the three for a pure theory paper, but the 7,500-word limit is tight for a major new theoretical framework. The paper must be tightly written.

### 1.4 Nature Ecology & Evolution / Science / Nature

**Threshold:** Requires "development of sufficient importance" with "broad potential interest" and timeliness — establishing a "principle relevant beyond the focal system." Simply applying existing models is "generally less favored." Nature-family journals have the highest novelty bar and typically require multiple lines of evidence.

---

## 2. Historical Acceptance Pathways: What Evidence Was Required

### 2.1 Kimura's Neutral Theory (1968)

**Proposal:** Most molecular changes are driven by random drift of selectively neutral mutants, not selection.

**Evidence required for acceptance:**
1. **Synonymous vs. non-synonymous substitution rates** — synonymous (silent) changes accumulate faster, consistent with neutrality
2. **High levels of molecular polymorphism** — selectionist theories struggled to explain the sheer amount of within-species variation
3. **Mathematical framework** — Kimura provided a rigorous, testable population-genetic model
4. **Genomic data (later)** — relationship between effective population size and selection efficiency, accumulation of slightly deleterious mutations in small populations
5. **Specific molecular examples** — pseudoglobin genes, αA-crystallin in blind mole rats, influenza A, nuclear vs. mitochondrial genes in *Drosophila*

**Tipping point:** The combination of a clear mathematical null model + the first comparative genomic data (synonymous/non-synonymous ratios) was sufficient to establish the theory as the dominant framework. The debate lasted ~15-20 years (1968-1985) before broad acceptance.

**Key lesson:** A single theoretical insight + one clear empirical pattern (synonymous rate > non-synonymous rate) was enough to shift the paradigm. The theory provided a *null model* that enabled all subsequent tests of selection.

### 2.2 The Price Equation (1970/1972)

**Proposal:** A mathematical identity partitioning evolutionary change into selection and transmission components.

**Evidence required:**
- **None for formal acceptance** — the Price equation is a mathematical tautology. Its truth is not empirical but logical, derived from definitions.
- **Empirical evidence** tested its *utility* as an analytical tool, not its truth.

**Key lesson:** Purely formal/mathematical claims can be accepted on logical grounds alone. But the Price equation is an identity, not a law — it doesn't make claims about the world. A rate law, by contrast, makes empirical claims and will require empirical evidence.

### 2.3 Fisher's Fundamental Theorem (1930)

**Proposal:** The rate of increase in mean fitness equals the additive genetic variance in fitness.

**Acceptance pathway:**
- **Misunderstood for 40 years** — widely misinterpreted as implying continuous fitness increase
- **Price's clarification (1972)** — proved the theorem's mathematical correctness, showing it applies only to the selection component of fitness change
- **Empirical tests** remain rare even today. The theorem's status as a mathematical truth is accepted independently of empirical validation.

**Key lesson:** A theorem can be accepted as mathematically correct even if empirical tests are scarce. But Fisher's theorem is a *relationship*, not a predictive rate law with a specific functional form. A rate law that makes numeric predictions will face a higher bar.

### 2.4 Ornstein-Uhlenbeck Process (Hansen 1997, Hansen & Martins 1996)

**Proposal:** Trait evolution under stabilizing selection, modeled as an OU process with mean reversion.

**Evidence grounding:**
1. **Mathematical derivation** — Hansen & Martins (1996) showed how microevolutionary processes translate to macroevolutionary patterns
2. **Single empirical example** — Hansen (1997) illustrated the method with dental evolution in fossil horses
3. **Subsequent proliferation** — the model became widely used because it addressed a clear biological need (how to detect stabilizing selection from comparative data)
4. **Meta-analytic support** — 46% of 250 fossil phenotype time-series best fit an OU model

**Key lesson:** The OU model was accepted on the basis of mathematical tractability + a single illustrative example + filling a clear gap. It was not required to "prove" that stabilizing selection exists; it provided a *method* to detect it. **A rate law is a stronger claim than a method** — it asserts a specific functional relationship, not just a statistical tool.

### 2.5 Quantitative Genetics (Falconer 1960; Lynch & Walsh 1998)

**Establishment pathway:**
- **Falconer's textbook** (1960) provided a clear, accessible framework — became the standard pedagogy
- **Polygenic model** was already well-established by the 1960s
- **Lynch & Walsh** (1998, 2018) modernized the framework, integrating molecular genetics and QTL analysis
- **Evidence base:** selection experiments in mice and *Drosophila*, linkage mapping, later genomic data

**Key lesson:** Quantitative genetics was accepted as a *framework* — a way of organizing and analyzing data — not as a specific law. The framework provided the breeder's equation (R = h²S) which is itself a rate-like relationship, but it was accepted as a statistical decomposition rather than a physical law.

### 2.6 Extended Evolutionary Synthesis (2007-present)

**Traction factors:**
- >200 papers, a special issue, and an anthology on Evolutionary Causation
- 22 studies designed to test EES predictions (Templeton-funded consortium)
- Addresses "limitations of the Modern Synthesis" in accommodating developmental biology, genomics, and ecology
- **Still debated** — not universally accepted. Critics argue its concepts are "not necessary" and can be folded into the Modern Synthesis.

**Key lesson:** Even a major conceptual expansion of evolutionary theory remains contested after 15+ years. A rate law would be a less radical claim and should face a lower bar — but the EES trajectory shows that the field is slow to accept new frameworks.

### 2.7 Molecular Clock (Zuckerkandl & Pauling 1962, 1965)

**Proposal:** Amino acid/nucleotide substitutions accumulate at an approximately constant rate over time.

**Validation pathway:**
1. **Initial proposal** — based on observation of hemoglobin evolution rates
2. **Strict clock model** — initially assumed constant rate across all lineages
3. **Relaxed clocks** — developed when rate heterogeneity became apparent
4. **Calibration standards:** fossil records, geological events, ancient DNA, pedigrees, longitudinal sampling
5. **Statistical validation:** temporal signal testing, date randomization tests, convergence diagnostics (ESS > 200), cross-validation
6. **Independent external evidence:** concordance with archaeological, paleontological, and epidemiological data

**Key lesson:** The molecular clock's acceptance required decades of methodological refinement and a shift from "strict" to "relaxed" models. The core insight (molecular rates are roughly constant) was accepted quickly; the specific rate law has been refined continuously. **A rate law should expect similar scrutiny of its assumptions and a willingness to relax them.**

---

## 3. The "You Have to Be This Tall to Ride" Threshold

### 3.1 How Many Independent Lines of Evidence?

| Scenario | Typical requirement |
|----------|-------------------|
| New mathematical method | 1-2 worked examples + validation against known models |
| New empirical pattern | 3+ independent datasets |
| New universal law | 5+ independent lines across multiple domains/kingdoms |
| Framework revision (like EES) | 15+ years of cumulative evidence from multiple labs |

**For a rate law specifically:** A single rate law making claims about the tempo of evolution across the tree of life would need **at least 3-5 independent lines of evidence** — ideally across different taxonomic groups, different timescales, and different trait types.

### 3.2 Replication Across Systems

- **Broad replicability** is the standard — consistent patterns across different species with relevant attributes
- **Convergent evolution** provides natural replication: if the same rate law predicts convergence patterns, that's strong evidence
- **No fixed number of species** but: a single clade is not enough for a universal claim. For a "universal" rate law, representation across **at least 2 domains of life** (Bacteria, Archaea, Eukarya) is expected.

### 3.3 Formal Proof vs. Empirical Fit

| Component | Role | Required? |
|-----------|------|-----------|
| Mathematical derivation | Shows logical consistency | Yes, essential |
| Analytical tractability | Makes the model usable | Yes, strongly preferred |
| Simulation validation | Shows behavior under known parameters | Yes, expected |
| Empirical fit to real data | Shows the model captures reality | **Yes, for a rate law** |
| Independent replication | Confirms the pattern is not artifact | Yes, for a universal claim |

**Critical distinction:** A purely mathematical theorem (Price equation, Fisher's theorem) can be accepted on proof alone. A **rate law** makes empirical claims about how fast evolution happens — it **must** be tested against data.

### 3.4 Phylogenetic Correction — PGLS Required?

- **Required for any comparative analysis** with species data. Uncorrected analyses are not publishable in top journals.
- **Brownian motion** is the default null model, but alternatives (OU, Pagel's λ, variable-rate models) are accepted when justified.
- **Model selection** (AIC, BIC) is standard practice for choosing among evolutionary models.
- **For a rate law:** If the rate law is tested against cross-species data, **PGLS or equivalent phylogenetic correction is non-negotiable**. Failure to account for phylogeny will result in desk rejection.

### 3.5 Null Models — What Must Be Ruled Out?

For a new rate law, the following null models must be addressed:

| Null model | What it claims | Must be ruled out? |
|------------|---------------|-------------------|
| Brownian motion | Traits evolve at constant rate with no directional trend | **Yes** — show the rate law fits better than BM |
| OU (stabilizing selection) | Traits are pulled toward optima | **Yes** — show the rate law is not just an OU model |
| Neutral evolution | Most change is neutral drift | **Yes** — show directional/selective component |
| Constancy of rates | "Rate" is just the average across lineages | **Yes** — show the rate law predicts variation |
| Simple power law | Rate = k × time^α | **Yes** — show the specific functional form matters |

### 3.6 How Many Kingdoms/Domains for a Universal Claim?

| Claim scope | Minimum coverage | Typical expectation |
|-------------|-----------------|-------------------|
| "Universal" across all life | 3 domains (Bacteria, Archaea, Eukarya) | Multiple kingdoms within Eukarya |
| Metazoan | 2+ phyla, multiple classes | 5+ phyla, vertebrate + invertebrate |
| Within a clade | 2+ orders within the clade | 5+ families |
| Single lineage | Deep sampling within that lineage | 10+ species with good phylogeny |

**For a rate law claiming universality:** You need data from **at least Bacteria and Eukarya**, ideally all three domains. Within Eukarya, representation from **animals, plants, and fungi** is expected. A rate law that only fits animal data will be labeled "a pattern in animals" not a universal law.

---

## 4. Argument Structure in Accepted Theoretical Papers

### 4.1 The Anatomy of a Highly Cited Theoretical Paper

Based on the most-cited theoretical evolution papers (Kimura 1968, Felsenstein 1985, Hansen 1997, Lande 1976, etc.):

| Section | Proportion of paper | Key elements |
|---------|-------------------|-------------|
| **Introduction** | 10-15% | Clearly state the biological problem. Show why existing models are insufficient. End with a specific claim. |
| **Theory/Methods** | 30-40% | Full mathematical derivation. Clear assumptions stated upfront. Analytical tractability or simulation framework. |
| **Empirical tests** | 20-30% | At least one real-data application. Model fitting and comparison. Sensitivity analysis. |
| **Discussion** | 15-20% | Acknowledge limitations. Compare to alternative models. Suggest specific future tests. |

**Ratio of theory to evidence to discussion:** Approximately **2:1.5:1** (theory : evidence : discussion). Pure theory papers (no evidence) are rare and must be exceptionally mathematically deep.

### 4.2 Handling the "Consistent With" Problem

**The problem:** Many theories are "consistent with" the same data. This is necessary but not sufficient for acceptance.

**Strategies used by successful papers:**

1. **Novel prediction:** The theory predicts something *not yet known* that can be tested. This is the gold standard.
   - *Example:* Kimura predicted that synonymous substitutions would outpace non-synonymous ones — this was a novel prediction that became the key test.

2. **Risk asymmetry:** The prediction must be *risky* — it could have gone the other way. Predictions that are almost certain to be true regardless of the theory provide little support.

3. **Quantitative fit, not just qualitative:** Showing that the data not only match the direction but the *magnitude* of the prediction. A rate law should make specific numeric predictions, not just "rates will increase."

4. **Model comparison:** Show that the proposed model fits significantly better than alternatives (AIC, BIC, likelihood ratio tests). This is standard in PCM and should be standard for a rate law.

5. **Cross-validation:** Fit the model on one dataset, test on another. This directly addresses the "consistent with" problem.

### 4.3 Novel vs. Post Hoc Predictions

| Feature | Novel prediction | Post hoc explanation |
|---------|----------------|-------------------|
| Timing | Made before the data are collected | Fits the theory to known data |
| Evidential weight | High — strong confirmation | Low — "consistent with" only |
| Reviewers' view | "Impressive" | "Just-so story" |
| Required for acceptance? | Not strictly, but strongly preferred | Acceptable only with independent cross-validation |

**Practical guidance:** If the rate law is derived from known data, then tested on *held-out* data or a *different* system, it counts as a quasi-novel prediction. This is the minimum viable approach.

---

## 5. Rate-Law Specific Acceptance Pathway

### 5.1 Has Anyone Proposed a Rate Law for Evolution Before?

**Yes, several — and their acceptance trajectories are instructive:**

| Proposal | Type | Status | Key to acceptance |
|----------|------|--------|------------------|
| Fisher's FTNS (1930) | Rate theorem | Mathematically accepted, empirically debated | Proof by Price (1972) |
| Molecular clock (1962) | Rate law | Widely accepted, extensively refined | Multiple independent calibrations |
| Neutral theory (1968) | Rate model | Foundational | Synonymous/non-synonymous test |
| OU process (1997) | Rate model | Widely used | Single empirical example + filling a gap |
| Breeder's equation | Rate relationship | Foundational | Decades of breeding data |
| Yule process (1924) | Diversification rate | Foundational | Mathematical + paleontological data |
| Lande's equation (1976) | Rate relationship | Foundational | Quantitative genetics framework |

**Key pattern:** Rate laws in evolutionary biology are typically accepted as *models* or *frameworks* rather than *physical laws*. The term "law" is used cautiously — Fisher's FTNS is the closest analog, and it took 40 years to be properly understood.

### 5.2 PGLS-Based Rate Estimates (Felsenstein, Hansen)

**Acceptance pathway:**
1. **Felsenstein (1985)** — recognized a statistical problem (non-independence due to phylogeny) and provided a solution (independent contrasts)
2. **Accepted because:** the problem was clear, the solution was mathematically elegant, and it solved a practical analytical need
3. **Hansen (1997)** — extended the framework to OU models for detecting stabilizing selection
4. **Accepted because:** it filled a specific gap (how to test for stabilizing selection comparatively) and came with a clear worked example

**Key lesson:** Methods are accepted when they solve a recognized problem. A rate law needs to demonstrate that it solves a problem that existing models cannot.

### 5.3 Molecular Clock Rate Claims — Validation Standards

**The most directly analogous case to a new rate law:**

1. **Initial claim** (Zuckerkandl & Pauling 1962): rates are approximately constant
2. **Immediate challenge:** rate heterogeneity across lineages and genes
3. **Resolution:** relaxed clock models (1990s-2000s) accommodating rate variation
4. **Validation criteria that emerged:**
   - **Temporal signal testing** — is there enough information to estimate rates?
   - **Date randomization test** — shuffling dates should destroy the signal
   - **Convergence diagnostics** — ESS > 200 for Bayesian parameters
   - **Cross-validation** — training/test splits
   - **Gene concordance** — multiple loci should give similar estimates
   - **Independent calibration** — fossil, geological, or archaeological constraints

**For a new rate law:** Expect similar validation standards. A rate law is a stronger claim than a molecular clock (which is a statistical model, not a law of nature). The same validation rigor — and then some — will be required.

---

## 6. Actionable Evidence Package: What Would Pass Review

### 6.1 Minimum Viable Package for *Evolution* or *Am Nat*

**Core components:**

1. **Mathematical derivation** (10-15 pages of main text)
   - Clear statement of assumptions
   - Full derivation from first principles
   - Limiting behavior (what happens at boundaries, what reduces to known models)
   - Analytical or simulation-based behavior characterization

2. **At least one empirical test** (5-8 pages)
   - A well-chosen dataset where the rate law can be fit
   - Model comparison against BM, OU, and other relevant alternatives
   - Sensitivity analysis (parameter uncertainty, tree uncertainty)
   - Phylogenetic correction (PGLS or Bayesian equivalent) — non-negotiable

3. **Null model rejection** (2-3 pages)
   - Show the rate law fits better than Brownian motion
   - Show it's not just an OU process in disguise
   - Show it's not just a power law or constant rate

4. **Discussion of limitations** (1-2 pages)
   - Where the rate law might fail
   - What data would be needed to test it more thoroughly
   - How it relates to existing frameworks

### 6.2 Full Package for *PNAS* or *Nature Ecology & Evolution*

**Adds to the above:**

1. **Significance Statement** (120 words) — must make a non-specialist care
2. **3+ independent empirical tests** across different systems
   - At least 2 domains of life (Bacteria + Eukarya recommended)
   - Within Eukarya: animals + plants or fungi
   - Different timescales (deep time + recent)
3. **Novel prediction** — at least one test on data not used in model development
4. **Code and data** — fully archived, documented, reproducible
5. **Comparison to all major alternatives** — BM, OU, early burst, white noise, trend models
6. **Cross-validation** — training/test split or leave-one-out analysis

### 6.3 What Will Get You Rejected

**Common rejection reasons for theoretical papers:**

1. **Insufficient biological motivation** — "Why should I care about this mathematical result?"
2. **No empirical test** — pure theory is possible but very rare; a rate law demands data
3. **Weak null model comparison** — "Your model fits better than BM, but that's a low bar. Does it fit better than OU?"
4. **No phylogenetic correction** — instant rejection for cross-species data
5. **Post hoc only** — "Your model explains the data you derived it from. Show it predicts something new."
6. **Overclaiming** — "You've shown this in one clade. That's not a universal law."
7. **"Consistent with" without falsification** — "What data would disprove your model?"
8. **Missing key literature** — "You didn't cite [relevant prior model]."

### 6.4 Summary Table: Evidence Requirements by Target Journal

| Requirement | *Evolution* | *Am Nat* | *PNAS* | *Nature Ecol Evol* |
|------------|-----------|---------|-------|-------------------|
| Mathematical derivation | ✓ | ✓ | ✓ | ✓ |
| One empirical test | ✓ | ✓ | ✓ | ✓ |
| 3+ independent tests | Optional | Optional | ✓ | ✓ |
| Multiple domains | Optional | Optional | ✓ | ✓ |
| Novel prediction | Optional | Optional | ✓ | ✓ |
| Code archived | ✓ (data editors check) | ✓ (mandated) | ✓ | ✓ |
| Broad significance framing | Optional | ✓ | ✓ (critical) | ✓ (critical) |
| Phylogenetic correction | ✓ | ✓ | ✓ | ✓ |
| Null model comparison | ✓ | ✓ | ✓ | ✓ |
| Significance statement | No | No | ✓ (120 words) | ✓ |

---

## 7. Key Takeaways

1. **A rate law is a stronger claim than a method.** The OU process was accepted as a method with one illustrative example. A rate law claiming a universal relationship will need substantially more evidence.

2. **The Kimura trajectory is the best model.** One clear mathematical framework + one striking empirical pattern (synonymous/non-synonymous rates) + a null model that enables further tests. This pattern succeeded.

3. **Phylogenetic correction is non-negotiable.** Any cross-species test of a rate law must account for phylogeny. PGLS is the minimum standard.

4. **"Universal" requires at least 2 domains.** A rate law tested only in animals will not be accepted as a universal law of evolution. Including bacteria and/or plants is essential.

5. **Novel prediction is the gold standard.** A rate law that predicts something *not yet known* — and is confirmed — will have vastly more impact than one that merely fits existing data.

6. **The "consistent with" trap is real.** Every successful theoretical paper in this review addressed it by (a) showing better fit than alternatives, not just "good fit," and (b) making testable predictions.

7. **Expect the Price/Fisher timeline.** Major theoretical results in evolutionary biology typically take 10-40 years from proposal to acceptance. A rate law should be framed as a proposal to be tested, not a definitive claim.

8. **The math is necessary but not sufficient.** Multiple reviewers and editors across journals emphasized that biological motivation and empirical connection are *required*, not optional, for theoretical papers.