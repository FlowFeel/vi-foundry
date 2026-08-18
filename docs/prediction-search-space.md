# What the Relaxation Formula Permits Us to Look For

## Prediction-Derived Search Space

The relaxation formula dρ/dt = −k₁(ρ − ρ₁) − k₂(ρ − ρ₂) makes specific, testable predictions. Each prediction opens a search space in existing published data. This document enumerates the predictions, derives what each permits us to look for, and identifies the datasets and analyses that can test them.

---

## P1: Bi-Exponential Kinetics in Longitudinal Data

**Prediction:** Any system undergoing niche commitment should show biphasic capacity loss — a fast phase (k₁) followed by a slow phase (k₂) — with the bi-exponential model beating mono-exponential and linear on AIC.

**What this permits us to look for:**
- Any experimental evolution time series with whole-genome sequencing at ≥5 time points
- Any endosymbiont genome with an estimated divergence time and a free-living relative (phylogenetic dating of genome reduction)
- Any island colonization event with before/after genome data
- Any domestication event with ancient DNA sampling at multiple time points

**Current evidence:** LTEE (ΔAIC = 190). This is one system.

**What we need:** A second longitudinal system. The minimum for "replicated" is two independent systems in different kingdoms. Three would be strong.

**Candidate datasets:**
1. *Pseudomonas fluorescens* SBW25 experimental evolution (Rainey lab, multiple time-series available)
2. *Saccharomyces cerevisiae* adaptive evolution experiments (multiple labs, whole-genome time-series)
3. *Pseudomonas protegens* experimental evolution (long-term, multiple time points)
4. Ancient DNA of domesticated species (dog, horse, cattle) with multiple dated samples
5. *Mycobacterium tuberculosis* latency time-series (gene loss over latency duration)
6. HIV within-host evolution time-series (gene loss in chronic infection)

---

## P2: k₁ ≫ k₂ (Rate Ratio)

**Prediction:** The fast rate constant should be much larger than the slow rate constant. In the LTEE, k₁/k₂ = 37.7. The ratio should be large (>10) in any system with a clear GRN hierarchy.

**What this permits us to look for:**
- Any system where we can measure two rate constants independently
- Endosymbiont genomes with known establishment times (the initial burst vs. long-term erosion)
- Island bird flight-loss with radiocarbon-dated colonization (fast morphological phase vs. slow genetic phase)

**Current evidence:** LTEE (ratio = 37.7), Sodalis partition (fast/slow gene classes).

**What we need:** A second system with independently measured k₁ and k₂. Endosymbionts with known establishment dates are the best candidates.

**Candidate datasets:**
1. *Sodalis* and its relatives (multiple independent endosymbioses, dated)
2. *Buchnera* with divergence time estimates (Moran lab datasets)
3. *Wigglesworthia* (tsetse fly endosymbiont — well-dated establishment)
4. *Candidatus* endosymbionts with host divergence times

---

## P3: Integration-Depth Ordering

**Prediction:** Traits lost in a specific order determined by developmental integration depth — not metabolic cost, not random, not population-size dependent. Batteries before plug-ins before kernels.

**What this permits us to look for:**
- Any system with multiple trait losses where integration depth can be scored independently
- Plastid genomes across parasitic plants (gene loss order vs. metabolic pathway position)
- Mitochondrial genomes across eukaryotes (gene loss order vs. respiratory complex position)
- Endosymbiont gene loss order vs. metabolic network dependency
- Cave organism trait loss order vs. developmental architecture

**Current evidence:** Orobanchaceae (ρ = 0.955), Cuscuta (ρ = 0.986), cross-kingdom (ρ = 0.755).

**What we need:** More independent lineages. The strongest test is a lineage we haven't examined yet, with a well-characterized developmental network.

**Candidate datasets:**
1. *Helicosporidium* (parasitic green alga — independent plastid loss, well-characterized)
2. *Epifagus* (Orobanchaceae holoparasite — complete plastome, different genus from our sample)
3. *Plasmodium* plastid (apicoplast — independent reduction in Apicomplexa)
4. *Toxoplasma* apicoplast (independent reduction, well-characterized metabolism)
5. *Euglena* plastid (independent acquisition and reduction)
6. *Cyanidioschyzon* (reduced red algal plastid)

---

## P4: Behavioral Commitment Precedes Morphological Change

**Prediction:** In every niche transition, behavioral change comes before morphological change. This is testable with independent dating.

**What this permits us to look for:**
- Any niche transition where behavioral and morphological changes are independently dated
- Archaeological vs. skeletal evidence for domestication (behavior before morphology)
- Fossil evidence of niche exploitation tools vs. skeletal adaptation
- Behavioral ecology studies of recent niche shifts (urban wildlife, invasive species)

**Current evidence:** ~50 documented transitions, 0 counterexamples (compiled in Supplementary Materials).

**What we need:** Systematic expansion of the catalogue. A published survey paper with explicit criteria would strengthen this from "we counted 50" to "systematic review of N cases."

**Candidate datasets:**
1. Domestication syndrome literature (dog, horse, cattle, sheep, goat — behavioral vs. morphological timing)
2. Urban wildlife adaptation studies (behavioral shifts preceding morphological changes)
3. Invasive species phenotype shifts (behavioral before morphological across 100+ documented invasions)
4. Human cultural niche construction (tool use before skeletal adaptation in Homo)

---

## P5: Niche-Demand Mismatch Beats Nₑ as Predictor

**Prediction:** The magnitude of niche-demand mismatch (how different the new niche is from the ancestral one) should be a better predictor of genome reduction rate than effective population size.

**What this permits us to look for:**
- Any dataset with genome size, niche breadth, and Nₑ estimates across species
- Bacterial genomes with known niche breadth and Nₑ (Bobay-Ochman dataset, expand it)
- Fungal genomes with symbiotic lifestyle and Nₑ estimates
- Insect genomes with colony size (as Nₑ proxy) and behavioral specialization

**Current evidence:** Bobay-Ochman (partial r = −0.519 niche vs. 0.329 Nₑ, 140 species).

**What we need:** Replication in a different kingdom. Fungi or insects.

**Candidate datasets:**
1. JGI MycoCosm fungal genome database (1000+ fungal genomes, lifestyle annotated)
2. Fungal lifestyle database (symbiotic vs. saprotrophic vs. pathogenic)
3. Insect genome database with colony size data
4. Ensembl Bacteria with metadata (expanded Bobay-Ochman)

---

## P6: Substrate Independence

**Prediction:** The same bi-exponential kinetics govern capacity reallocation regardless of substrate — DNA, developmental architecture, cultural knowledge, neural structure, social organization.

**What this permits us to look for:**
- Any system where capacity loss can be measured on a non-DNA substrate
- Language attrition time-series (grammatical complexity loss over time)
- Neural pruning time-series (synapse loss during development or aging)
- Cultural knowledge loss in isolated populations
- Behavioral repertoire loss in domesticated vs. wild animals

**Current evidence:** Cross-domain review (§6, 7 domains, qualitative).

**What we need:** Quantitative time-series in at least one non-DNA substrate where we can fit k₁ and k₂.

**Candidate datasets:**
1. Language attrition longitudinal studies (ISBUL corpus, Language Archive, Glottolog)
2. Human brain development MRI time-series (synapse density loss during adolescence — fast phase, then slow phase)
3. Animal domestication behavioral repertoire studies (fox farm experiment time-series)
4. Cultural transmission experiments (laboratory microsocieties with controlled niche shifts)

---

## P7: Sign Reversal on Generative Substrate

**Prediction:** When the niche substrate shifts from ecological (finite) to cultural (generative), the attractor dynamics reverse sign — producing positive diversity-dependent speciation instead of negative.

**What this permits us to look for:**
- Any lineage where a generative niche shift occurred, with speciation rate data
- *Homo* is our primary case. Are there others? Some birds (corvids, parrots) have cumulative culture. Do they show positive DD?
- Social insects with cumulative culture (some ants have tool use — do they show positive DD?)

**Current evidence:** van Holstein & Foley 2024 (Homo positive DD, non-Homo hominins negative).

**What we need:** A second lineage with a generative substrate shift.

**Candidate datasets:**
1. Jetz & Pyron bird phylogeny (speciation rates across all birds — do corvids/parrots show positive DD?)
2. Mammalian phylogeny with speciation rates (do any non-Homo lineages show positive DD?)
3. Fish phylogeny (do any tool-using fish lineages show positive DD?)

---

## P8: Irreversibility Past Integration-Depth Threshold

**Prediction:** Once a trait has been lost past a certain integration-depth threshold, it cannot be recovered. The relaxation is functionally irreversible.

**What this permits us to look for:**
- Any system where trait loss has been reversed (or attempted to reverse) — these are the falsification candidates
- Reintroduction programs (capacity loss measured against reintroduction success)
- Gene therapy for lost functions (can lost pathways be restored?)
- Experimental reversal of domestication (do domesticated animals revert to wild type?)

**Current evidence:** Dollo's Law violations (stick insects, frogs) are apparent — the programs persisted by integration depth, not truly re-evolved.

**What we need:** A systematic survey of reversal attempts with integration-depth scoring.

**Candidate datasets:**
1. IUCN reintroduction database (success/failure rates vs. time in captivity)
2. Experimental evolution reversal studies (replicate populations returned to ancestral niche)
3. *Arabidopsis* mutant restoration studies (can lost metabolic pathways be restored?)

---

## What the Formula Does NOT Permit Us to Look For

The formula is silent on:
- **Neutral molecular evolution** (Kimura's domain — no niche commitment involved)
- **Frequency-dependent selection** (cycling genotypes, no progressive capacity reallocation)
- **Single-gene adaptation** (discrete genetic changes to discrete challenges)
- **Ecological dynamics without commitment** (predator-prey oscillations, succession)
- **Morphological stasis without niche shift** (stabilizing selection, no mismatch)

These are demarcation boundaries, not limitations. The formula makes claims about a specific class of phenomena: progressive, ordered, decelerating capacity loss under deepening niche commitment.
