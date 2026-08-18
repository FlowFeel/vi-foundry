# Dataset Survey: Bi-Exponential Relaxation Formula for Adaptive Evolution

**Formula:** `dρ/dt = −k₁(ρ − ρ₁) − k₂(ρ − ρ₂)`  
**where:** ρ = retained capacity, k₁ = fast rate, k₂ = slow rate, ρ₁/ρ₂ = equilibria

**Date:** 2026-08-18  
**Survey scope:** 7 prediction categories across NCBI, GitHub, Dryad, Zenodo, TreeBASE, and published literature

---

## Category 1: Longitudinal Genome Reduction Time Series

### 1a. LTEE (Lenski *E. coli* Long-Term Evolution Experiment)

**Dataset:** Whole-genome sequences from 264 clones across 12 populations, sampled at 11 time points spanning 0–50,000 generations. Now >80,000 generations ongoing.

**Access:**
- NCBI BioProject: PRJNA294072 (primary), PRJNA295606 (264-genome subset)
- Dryad: doi:10.5061/dryad.2875k (264 genomes, zipped data + README)
- GitHub: LTEE-Ecoli organization
- Web: https://the-ltee.org/resources/

**Prediction tested:** The bi-exponential decay predicts that the rate of genome structural change (gene loss, IS-element insertions, deletions) should follow a two-phase pattern — rapid initial decay (k₁) as easily-losable functions are shed, transitioning to a slower sustained phase (k₂) as deeper-integrated functions resist loss.

**Analysis:** Fit cumulative mutation counts per generation to a double-exponential model. The LTEE tracks insertions, deletions, and point mutations. Mutations in core genes vs. flexible genes can be separated. The rate of functional loss (not just mutation accumulation) is the key variable.

**Phylogenetic correction:** Not required — it's a single species, replicates are independent populations. Time-series structure requires correction for autocorrelation (ARIMA or GLS with temporal covariance).

**Strengths:** Gold standard. 3+ decades of data. Known fitness trajectories. Repeated sampling from frozen fossil record.

**Limitations:** *E. coli* is free-living, not an endosymbiont. Genome size changes are small (few Mb total). The fast phase may be too fast to resolve at 500-generation sampling intervals.

---

### 1b. Lenski Lab Secondary Experiments

**Dataset:** Various *E. coli* experimental evolution studies with reduced-genome strains and time-series sequencing.

**Notable studies:**
- **Kuo et al. (2012):** *E. coli* strains carrying reduced genomes (~1.5 Mb deletions) evolved for ~1,000 generations. Fitness recovered considerably. Transcriptome reorganization showed common evolutionary direction across replicates.
- **Wielgoss et al. (2011):** Mutation rate evolution in LTEE — hypermutator lineages arise and their mutation accumulation patterns differ.

**Access:** Associated with LTEE publications; supplementary data on Dryad and NCBI SRA.

**Prediction tested:** The recovery of fitness after genome reduction tests whether re-equilibration follows a bi-exponential relaxation to a new steady state (ρ₂). The initial fast phase is the rapid loss of newly-dispensable functions, the slow phase is the deeply-integrated core.

**Analysis:** Fitness trajectories over time can be fit to the bi-exponential model. The initial deletion introduces a perturbation; the relaxation back toward equilibrium can be measured.

---

### 1c. *Salmonella enterica* Experimental Evolution (Nilsson et al. 2005)

**Dataset:** *Salmonella enterica* wild-type and *mutS* mutant strains serially passaged for 1,500 generations. 60 *mutS* lineages. Measured DNA loss rate: 0.05 bp/chromosome/generation (wild-type), ~50× higher in *mutS*.

**Access:** Primary data in Nilsson et al. (2005) *PNAS* 102(34):12123-12128. Microarray-based comparative genomic hybridization data. Contact authors for raw data.

**Prediction tested:** Genome reduction rate decays over time as easier-to-delete regions are purged first. The bi-exponential model predicts the rate should slow as the genome approaches its minimal functional core.

**Analysis:** Deletion size distribution (1–202 kb) and deletion frequency over generations. The decay in deletion rate as a function of remaining genome size.

**Phylogenetic correction:** Not needed — single species time series.

---

### 1d. Yeast (*Saccharomyces cerevisiae*) Long-Term Evolution

**Dataset:**
- **Levy Lab (2021, eLife):** 205 populations (~124 haploid, 81 diploid) evolved for ~10,000 generations in 3 environments. Whole-population genome sequencing at 6 time points. Fitness measurements + mutation tracking.
- **Desai Lab (Harvard):** 432 independent strains evolved for 500 generations; 104 sequenced.
- **Phillips et al. (2020):** Outcrossing yeast, 17 time points over ~540 generations. High-resolution allele frequency trajectories.
- **Burke et al. (2014):** 12 populations with forced recombination, sequenced at weeks 0, 6, 12, 18.

**Access:**
- Levy Lab: NCBI SRA (BioProject in eLife 63910 supplementary materials)
- Desai Lab: NCBI SRA
- Dryad, GitHub for specific datasets

**Prediction tested:** Gene loss and functional decay in a eukaryotic genome. Yeast can lose dispensable genes. The rate of functional loss should show two phases.

**Analysis:** Mutation accumulation rate per gene category (essential vs. non-essential, duplicated vs. single-copy). Fitness trajectories. The bi-exponential model can be fit to the rate of functional decay in the genome.

**Phylogenetic correction:** Not needed.

---

### 1e. *Pseudomonas fluorescens* SBW25 Wrinkly Spreader System

**Dataset:** Serial passage experiments tracking the emergence of the wrinkly spreader (WS) phenotype. Genome sequencing of WS genotypes at different time points. Three known mutational pathways (wsp, aws, mws) plus cryptic sws pathway.

**Access:** Various publications; NCBI SRA for genome sequences. Rainey lab (Auckland) and others.

**Prediction tested:** The rate of emergence of adaptive phenotypes (biofilm formation) follows a predictable relaxation. The two-phase model may apply to the rate of phenotypic innovation, not just gene loss.

**Analysis:** Time to emergence of WS phenotype across replicates. Mutation rate in each pathway over time.

---

## Category 2: PGLS-Ready Phylogenetic Datasets with Niche + Genome Size

### 2a. Parasitic Plant Plastome Size + Parasitism Level (Orobanchaceae and Beyond)

**Available datasets:**

**Orobanchaceae:**
- **Wicke et al. (2013):** Comparative plastomics across Orobanchaceae — 34 plastomes spanning autotrophic, hemiparasitic, and holoparasitic species. Phylogeny included.
- **Li et al. (2021, biorxiv):** 12 Orobanchaceae plastomes including *Diphelypaea coccinea* (66,616 bp, no photosynthesis genes).
- **Dryad:** doi:10.5061/dryad.31cf160 (Orobanchaceae low-copy nuclear genes phylogeny)
- **Dryad:** doi:10.5061/dryad.bn281 (Pedicularis RADseq phylogeny)
- **NCBI:** Multiple plastome assemblies for *Striga*, *Orobanche*, *Phelipanche*, *Cistanche*, *Lindenbergia*, *Pedicularis*

**Other families:**
- **Santalales:** 34 complete plastomes across the order. Reduction 10–22% vs. typical angiosperms. Dryad datasets available.
- **Cuscuta (Convolvulaceae):** 12+ plastomes spanning hemi- to holoparasitic species. Phylogeny well-resolved.
- **Loranthaceae:** 48 hemiparasite plastomes. Published phylogeny.
- **Apodanthaceae:** *Pilostyles aethiopica* — extreme reduction (11,348 bp, 5 genes). Single species, limited phylogenetic context.

**Prediction tested:** Parasitism level (facultative → obligate hemiparasite → holoparasite) should correlate with plastome size following a bi-exponential decay. The initial transition to parasitism causes rapid plastome reduction (k₁), followed by slower decay toward an irreducible core (ρ₂ ≈ 11–65 kb, the minimal plastome).

**Analysis:** PGLS with plastome size as response, parasitism level as ordered categorical predictor (or continuous host-dependence index). Phylogenetic covariance matrix from published trees. Test: does the decay from free-living to holoparasite fit a two-phase exponential better than a single exponential?

**Phylogenetic correction:** Yes — essential. Published phylogenies available for Orobanchaceae, Santalales, Convolvulaceae, Loranthaceae. Use PGLS with Brownian motion or OU model.

---

### 2b. Endosymbiont Genome Size + Host Dependence Level

**Current dataset (10 genera):** Buchnera, Carsonella, Blochmannia, Wigglesworthia, Sulcia, Nasuia, Karelsulcia, Tremblaya, Moranella, Hodgkinia.

**Expandable to 20+ genera:**

| Genus | Host | Genome size (kb) | Features |
|-------|------|-----------------|----------|
| *Buchnera* | Aphids | 412–650 | Essential amino acid synthesis |
| *Carsonella* | Psyllids | 160–174 | Minimal genome, organelle-like |
| *Blochmannia* | Carpenter ants | 705–800 | Amino acid + nitrogen processing |
| *Wigglesworthia* | Tsetse flies | 700 | Vitamin synthesis |
| *Sulcia* | Cicadas/leafhoppers | 190–280 | Essential amino acids |
| *Nasuia* | Leafhoppers | 112 | Extreme reduction |
| *Karelsulcia* | Leafhoppers | 250–290 | Degrading genome |
| *Tremblaya* | Mealybugs | 139 | Minimal, some genes in partner |
| *Moranella* | Mealybug partner | 538 | Gamma-proteobacterial partner |
| *Hodgkinia* | Cicadas | 144 | Split genome |
| *Zinderia* | Spittlebugs | 208 | Minimal |
| *Candidatus Portiera* | Whiteflies | 357 | Amino acid synthesis |
| *Candidatus Baumannia* | Sharpshooters | 686 | Vitamin synthesis |
| *Candidatus Evansia* | Leafhoppers | 630 | Ancient symbiont |
| *Candidatus Uzinura* | Armored scales | 240 | Amino acid synthesis |
| *Candidatus Walczuchella* | Giant scales | 304 | Minimal genome |
| *Candidatus Gullanella* | Mealybugs | 710 | Nutrient synthesis |
| *Candidatus Brownia* | Mealybugs | 400 | Co-obligate |
| *Candidatus Desantisia* | Spittlebugs | 250 | Co-obligate |
| *Candidatus Ruthia* | Clam gills | 1,200 | Chemosynthetic |
| *Candidatus Vesicomyosocius* | Clam gills | 1,000 | Chemosynthetic |
| *Candidatus Endoriftia* | Tubeworms | 3,500 | Chemosynthetic |

**Sources:** NCBI RefSeq, GenBank for all genomes. Published phylogenies for each host-symbiont system.

**Key paper:** Fisher et al. (2017) *PNAS* — "Host dependence correlates with genome reduction in symbionts." Quantified host dependence as fitness reduction upon symbiont removal. Found negative correlation with genome size.

**Prediction tested:** The bi-exponential decay of genome size as a function of host dependence (or time since symbiosis establishment). The fast phase corresponds to loss of biosynthetic pathways redundant with host environment, the slow phase corresponds to loss of essential informational genes.

**Analysis:** PGLS with genome size ~ host dependence index + phylogenetic covariance. Multiple measures of host dependence: (1) binary (obligate/facultative), (2) host fitness effect of symbiont removal, (3) estimated time since symbiosis (from molecular clock). Compare single vs. bi-exponential model fit.

**Phylogenetic correction:** Yes — essential. Symbiont phylogeny (Gammaproteobacteria, Bacteroidetes, etc.) can be constructed from 16S rRNA or concatenated protein-coding genes. Host phylogeny also available.

---

### 2c. Fungal Genome Size + Symbiotic Lifestyle

**Datasets:**
- **1000 Fungal Genomes Project:** JGI MycoCosm platform. >1,000 fungal genomes with lifestyle annotations.
- **Li et al. (2021) *Current Biology*:** Large-scale phylogenomics of Ascomycota. Genome sizes + lifestyle data for hundreds of species.
- **Miyauchi et al. (2020) *Nature Communications*:** Ectomycorrhizal vs. saprotrophic fungi — TE expansion, gene family dynamics.
- **GLBRC dataset:** Genome-scale phylogeny of fungi with contrasting modes of genome evolution.

**Prediction tested:** Mycorrhizal fungi should have larger genomes than saprotrophic fungi due to TE expansion. The transition from saprotroph to mycorrhizal symbiont causes a relaxation of selection for genome compactness, bi-exponentially approaching a new larger equilibrium.

**Analysis:** PGLS with genome size ~ lifestyle (mycorrhizal, saprotrophic, pathogenic, lichenized) + phylogeny. Test whether the difference follows a single shift or a two-phase relaxation.

**Phylogenetic correction:** Yes — essential. Fungal phylogeny well-resolved at phylum and class level.

---

## Category 3: Trait Loss Ordering Datasets

### 3a. *Astyanax mexicanus* Developmental Gene Expression (Cavefish)

**Datasets:**
- **McGaugh et al. (2014) *PLoS ONE*:** RNA-seq at 4 developmental stages (10, 24, 36, 72 hpf) across surface fish, Pachón cavefish, and Tinaja cavefish. 36 FASTQ files.
- **Loomis et al. (2024) *Development*:** Transcriptomes at end of gastrulation (~10 hpf) — surface vs. blind cave morphs. Cis-regulatory analysis.
- **Beale et al. (2013) *PLoS ONE*:** Circadian clock development — light-pulse experiments at 5, 14, 23 hpf.
- **NCBI:** Multiple SRA datasets for *Astyanax* developmental transcriptomes.

**Prediction tested:** Traits lost in cavefish (eyes, pigmentation, circadian regulation) are lost in a sequence that reflects their integration depth. The most deeply integrated developmental pathways (e.g., early eye field specification) should be lost last (slow phase, k₂), while peripherally integrated traits (e.g., melanin production enzymes) are lost first (fast phase, k₁).

**Analysis:** Score each gene/trait for integration depth based on expression breadth, network centrality, pleiotropy. Then order trait loss by developmental timing of expression change. Fit bi-exponential to cumulative loss over time.

**Phylogenetic correction:** Within-species comparison between populations; not required for the basic analysis but useful for independence across replicate cave populations.

---

### 3b. Other Cave Organisms with Time-Series Data

**Asellus aquaticus (cave isopod):**
- **Lomheim et al. (2023) *PLoS ONE*:** Embryonic transcriptomes at 2 time points from cave, surface, and hybrid populations. Allele-specific expression.
- **Gross et al. (2019):** Developmental transcriptomic analysis of cave, surface, and hybrid individuals.
- **NCBI SRA:** BioProject PRJNA281276 (454 sequencing)
- **Dryad:** doi:10.5061/dryad.2547d7wqj (genome + VCF file)

**Proteus anguinus (olm):**
- **Transcriptome across organs:** NCBI SRA data available. Developmental time series limited.

**Triplophysa shilinensis (cave loach):**
- **NCBI SRA:** Brain transcriptome comparisons between cave and surface populations. Adult only, not developmental.

**Prediction tested:** Same as *Astyanax* — independent replication of the trait loss ordering hypothesis across distantly related cave taxa.

**Analysis:** Cross-species comparison of trait loss order. The prediction is that the order of loss is phylogenetically conserved (deeply integrated traits are lost last in all cave lineages).

**Phylogenetic correction:** Yes — for cross-species comparison of loss order.

---

### 3c. Island Bird Flightlessness + Skeletal Measurements

**Primary dataset: Wright et al. (2016) *PNAS*:**
- 366 populations of Caribbean and Pacific island birds
- Skeletal measurements: keel length (flight muscle size), leg length, wing length
- Island characteristics: size, predator presence, isolation
- PGLS analysis already performed
- Dataset S1 (supplementary data): Island population means from individual-level skeletal data
- Supplementary PDF: https://static1.squarespace.com/static/.../Wright-etal-2016-PNAS-Evolution-toward-flightlessness-with-supplement.pdf

**Secondary dataset: Dryad doi:10.5061/dryad.1zcrjdg57:**
- "Morphological evolution in island birds" — 796 pairs of endemic island birds + closest mainland relatives (1,170 species)
- Wing shape, wing length, tarsus length
- 100 alternative phylogenetic trees (trees_ex.nex)
- CSV files: morpho_db.csv, morpho_db_filtered.csv

**Additional: Passeriformes skeletal dataset:**
- 2,057 species, 12 skeletal elements, 14,419 individuals. Not island-specific but provides comparative baseline.

**Island Bird Fossil Database (GitHub):**
- https://github.com/alisonboyer/IslandBirdFossilDB
- Paleoecological + modern bird occurrences on islands. Includes species traits (diet, body mass, extinction dates).

**Prediction tested:** The bi-exponential model predicts that the degree of flightlessness (keel reduction relative to mainland ancestor) should follow a two-phase decay as a function of time since island colonization. The initial rapid phase (k₁) corresponds to reduced predation pressure causing rapid loss of flight muscle mass. The slow phase (k₂) corresponds to deeply-integrated skeletal constraints that resist further change.

**Analysis:** Use island age as a proxy for time since colonization. Fit keel length vs. island age to a bi-exponential model. Alternatively, use phylogenetic distance from mainland ancestor as a proxy for elapsed evolutionary time.

**Phylogenetic correction:** Yes — essential. Wright et al. already used PGLS. The Dryad dataset includes 100 alternative trees for robust phylogenetic correction.

---

## Category 4: Population-Level Rate Measurements

### 4a. Experimental Evolution Rate of Function Loss (LTEE and Others)

**LTEE-specific:**
- Mutation rate per generation: ~1 × 10⁻⁹ per bp per generation
- Gene loss rate: measurable from deletion events
- Pseudogene formation rate: detectable from premature stop codons

**Analysis:** Fit the rate of functional gene loss (pseudogenization events per generation) over time. The prediction is that the rate starts high and decays bi-exponentially as the remaining functional elements are more deeply integrated.

---

### 4b. Human Pseudogene Accumulation Rate (1000 Genomes Project)

**Datasets:**
- **Ewing et al. (2013):** 39 GRIPs (gene retrocopy insertion polymorphisms) in 939 samples from 1000 Genomes Project. Estimated rate: ~1 per 6,256 individuals per generation.
- **Abyzov et al. (2020):** More sensitive methods — 40 events per 22 individuals, suggesting higher rate.
- **1000 Genomes Project:** 2,504 individuals, comprehensive structural variant calls. Phase 3 data available from internationalgenome.org.

**Key data:**
- GRIPs are processed pseudogenes — retrotransposed mRNA copies inserted into the genome
- These are ongoing, heritable insertions
- Parent genes span diverse functional categories
- Population frequency data available

**Prediction tested:** The bi-exponential model predicts that the rate of pseudogene accumulation should be higher for genes in functionally redundant families (fast phase, k₁) and lower for singleton essential genes (slow phase, k₂). The population-level rate of new pseudogene insertions should reflect the pool of genes that are "loss-tolerant" — those that are either redundant or non-essential.

**Analysis:** Classify parent genes by: (1) functional redundancy (gene family size), (2) essentiality (OE ratio from gnomAD), (3) expression level, (4) network centrality. Compare GRIP rate per gene category. The rate of pseudogene accumulation should be proportional to the fraction of loss-tolerant genes in the genome, which decays bi-exponentially as the most tolerant genes are pseudogenized first.

**Phylogenetic correction:** Not applicable (single species, population genetics).

---

### 4c. Antibiotic Resistance Evolution Rate

**Datasets:** Multiple experimental evolution studies tracking the rate of resistance acquisition and the cost of resistance (fitness cost). The cost of resistance often decays over time as compensatory mutations accumulate.

**Relevant systems:**
- *Pseudomonas aeruginosa* resistance evolution (time series of MIC and fitness cost)
- *E. coli* resistance to multiple antibiotics
- *Mycobacterium tuberculosis* resistance evolution

**Prediction tested:** The fitness cost of resistance should decline bi-exponentially as the most costly resistance mutations are compensated first (fast phase), and the remaining costs are in deeply integrated pathways that are harder to compensate (slow phase).

---

## Category 5: C4 Photosynthesis Molecular Convergence

### 5a. PEPC Sequence Data (Christin et al. 2007 and Beyond)

**Core dataset:**
- **Christin et al. (2007) *Current Biology* 17(14):1243-1247:** C4 photosynthesis evolved in grasses via parallel adaptive genetic changes. 21 amino acids under positive selection, converging to similar/identical residues in 8 independent C4 lineages.
- DOI: 10.1016/j.cub.2007.06.036
- **GenBank accessions:** AM689877–AM690219 (PEPC sequences)
- **TreeBASE:** S11973 (grass phylogeny + C4 origins)
- Supplementary data available from *Current Biology* article page.

**Additional PEPC datasets:**
- **Christin et al. (2009) *Molecular Biology and Evolution* 26(2):357-369:** 14 amino acid sites showing parallel adaptations in C4 PEPC genes. Expanded taxon sampling.
- **Gowik et al. (2011) *Plant Cell*:** Functional characterization of convergent PEPC amino acid changes.

**Other C4 genes:**

**PDK (Pyruvate, Orthophosphate Dikinase):**
- PPDK is critical for PEP regeneration in mesophyll cells of all C4 types
- Sequence data available in GenBank for C3 and C4 species
- Key papers: Heat shock protein 70 (PDK regulatory partner) — convergent evolution patterns

**NADP-ME (NADP-malic enzyme):**
- C4 NADP-ME evolved from C3 chloroplastic ancestor via gene duplication
- Maize, sorghum, *Flaveria* sequences available
- Key papers: Tausta et al. (2024), Christin et al. (2012)
- Positive selection identified in multiple C4 lineages

**NAD-ME (NAD-malic enzyme):**
- Adapted from existing mitochondrial NAD-ME
- Regulatory and kinetic changes without gene duplication in some lineages
- GenBank sequences available

**PCK (Phosphoenolpyruvate carboxykinase):**
- Third decarboxylase subtype. Sequence data available.

**Core convergence pattern across all genes:**
- 21 genes independently duplicated in parallel in different C4 lineages (core C4 toolkit)
- Repeated parallel changes in cis-regulatory elements
- Convergent amino acid substitutions across distantly related lineages

**Prediction tested:** The bi-exponential model predicts that the rate of molecular convergence (amino acid substitutions fixing in parallel across independent C4 lineages) should follow a two-phase pattern. The initial rapid phase (k₁) corresponds to the early adaptive changes that confer the basic C4 kinetic properties (substrate affinity, catalytic rate). The slow phase (k₂) corresponds to fine-tuning of regulatory and structural features that are more deeply integrated.

**Analysis:** For each C4 lineage, count the number of convergent amino acid changes as a function of estimated time since C4 origin. Phylogenetically independent contrasts across the 8+ grass C4 origins. The total number of convergent changes across lineages, plotted against divergence time, should follow a bi-exponential curve.

**Phylogenetic correction:** Yes — essential. The 8+ independent origins of C4 in grasses provide natural replicates. Use each origin as an independent data point. The grass phylogeny (from TreeBASE S11973) provides the framework.

---

### 5b. C4 Molecular Evolution in Other Angiosperm Clades

**Beyond grasses:**
- C4 evolved independently in at least 19 angiosperm families (including eudicots in Chenopodiaceae, Amaranthaceae, Asteraceae, Euphorbiaceae, etc.)
- PEPC convergence patterns have been studied in *Flaveria* (Asteraceae)
- Chenopodiaceae has multiple C4 origins with published sequence data

**Prediction tested:** Extend the convergence analysis beyond grasses. The same bi-exponential pattern should hold across all C4 origins.

---

## Category 6: Eusociality Behavioral Repertoire Datasets

### 6a. Hymenoptera Behavioral Repertoire + Colony Size + Phylogeny

**Available data:**
- **No single pre-packaged dataset** combining all three variables exists. Multiple studies contribute components.

**Key studies and data sources:**

- **Corbiculate bee phylogeny:** Well-resolved from UCE (ultraconserved element) datasets. 4 tribes: Apini, Bombini, Meliponini, Euglossini. Single origin of eusociality ~87 Mya.
- **Colony sizes:** Euglossini (solitary), Bombini (50–400), Meliponini (10,000+), Apini (50,000–60,000).
- **Behavioral repertoire:** Honey bees have ~50+ identified behavioral acts. Bumble bees ~20–30. Stingless bees ~20–40. Orchid bees (solitary) ~5–10.
- **Key publication:** "Data-driven analyses of social complexity in bees reveal phenotypic diversification following a major evolutionary transition" (2024). Compiled trait database for social complexity.
- **Phylogenomic dataset:** 3,256 genes from 169 Hymenoptera species, including 10 eusocial species. Used to examine effective population size and eusociality.

**Prediction tested:** The bi-exponential model predicts that individual behavioral repertoire breadth should decay as colony size increases. The initial transition from solitary to eusocial causes a rapid specialization (narrowing of individual repertoire, k₁), while further increases in colony size cause progressively smaller reductions in individual repertoire (k₂) as the physical and cognitive limits of specialization are reached.

**Analysis:** PGLS with individual behavioral repertoire breadth ~ colony size (log scale) + phylogeny. Fit bi-exponential vs. single exponential. The prediction is that the decay is biphasic: rapid initial narrowing from solitary to small-colony eusocial, then slow narrowing from small-colony to large-colony eusocial.

**Phylogenetic correction:** Yes — essential. Hymenopteran phylogeny available.

---

### 6b. Volvocine Algae Genome Size + Colony Complexity

**Datasets:**
- **NCBI:** *Chlamydomonas reinhardtii* (110–120 Mb), *Gonium pectorale* (~130 Mb), *Volvox carteri* (~138 Mb)
- **Phytozome:** Genome assemblies and annotations
- **Organelle genomes:** NCBI (mitochondrial + plastid genomes)
- **Transcriptomes:** RNA-seq data for *Volvox* cell-type-specific expression

**Complexity gradient:**
- *Chlamydomonas*: unicellular, no colony
- *Gonium*: 4–32 cells, flat colony, no differentiation
- *Pandorina*: 16–32 cells, spherical colony, some differentiation
- *Eudorina*: 32–64 cells, beginning of germ-soma distinction
- *Pleodorina*: 64–128 cells, partial germ-soma separation
- *Volvox*: 500–50,000 cells, differentiated somatic + germ cells

**Conveniently, the genome sizes are very similar (110–138 Mb),** so the prediction is that the *functional* genome changes are more important than absolute size. The key is gene expression changes, not genome size changes.

**Prediction tested:** The number of genes expressed per cell type (or total functional gene repertoire) should decay as colony complexity increases. The bi-exponential model predicts that the transition from unicellular to simple colonial causes a rapid reduction in the functional gene repertoire of individual cells (specialization, k₁), while the transition from simple colonial to complex differentiated multicellularity causes a slower reduction (k₂).

**Analysis:** Compare gene expression breadth per cell type across the volvocine gradient. The number of cell-type-specific genes should increase while per-cell expression breadth decreases.

**Phylogenetic correction:** Yes — volvocine phylogeny well-resolved.

---

## Category 7: Human Metabolic Network Dependency Test

### 7a. Human-GEM / Recon3D + Human Protein Atlas

**Datasets:**

**Human-GEM (Genome-scale metabolic model):**
- Curated, consensus model of human metabolism
- Versions: Human1, Human2 (latest)
- Available at: https://metabolicatlas.org/
- GitHub: SysBioChalmers/Human-GEM
- ~3,000 genes, ~10,000 reactions, ~8,000 metabolites

**Recon3D:**
- Comprehensive human metabolic network
- Available at: https://vmh.life/
- Integrated with Human-GEM, used as foundation

**Human Protein Atlas (HPA):**
- Tissue-specific protein expression data
- 44 tissues, 32 normal tissue types
- RNA-seq + proteomics
- Single-cell RNA-seq data (Single Cell Type Section)
- Available at: https://www.proteinatlas.org/

**GTEx (Genotype-Tissue Expression):**
- Database of tissue-specific gene expression
- 54 tissues, 948 donors
- Used for tissue-specific model construction

**Method:**
- tINIT algorithm uses HPA + GTEx data to construct tissue-specific metabolic models from Human-GEM
- Reaction presence scores inferred from gene expression data
- Metabolic Atlas allows loading HPA data directly onto metabolic maps

**Prediction tested:** The bi-exponential model predicts that the metabolic network dependency of a gene (its essentiality in the network) is inversely related to its tissue-specificity. Genes expressed in a single tissue should be more easily lost (high rate, k₁) because their loss affects only one tissue. Genes expressed in many tissues (housekeeping metabolic genes) should be lost very slowly (low rate, k₂) because their loss affects the entire organism.

**Analysis:**
1. From Human-GEM, compute for each gene: (a) network centrality (number of reactions it participates in, connectivity), (b) essentiality in the model (model-predicted knockout lethality)
2. From HPA, compute for each gene: (a) tissue specificity index (τ or SP), (b) number of tissues with detectable expression, (c) expression level in each tissue
3. Test: Are tissue-specific metabolic genes predicted to be non-essential (or conditionally essential) in the model? Are broadly-expressed metabolic genes universally essential?
4. The bi-exponential model predicts that the relationship between tissue breadth and loss rate follows a biphasic decay: genes expressed in 1–5 tissues have high loss vulnerability (k₁), genes expressed in 30+ tissues have low loss vulnerability (k₂).

**Phylogenetic correction:** Not applicable (single species).

---

### 7b. Evolutionary Rate of Human Metabolic Genes

**Additional data:**
- **dN/dS ratios** for human metabolic genes from mammalian comparative genomics
- **OE ratios** from gnomAD (loss-of-function tolerance)
- **Gene age** (phylostratigraphy) — older genes are more deeply integrated

**Prediction tested:** The bi-exponential model predicts that the rate of functional constraint on a gene (measured as dN/dS or OE score) should follow a biphasic relationship with tissue-specificity. Broadly expressed, ancient metabolic genes are in the slow phase (k₂, highly constrained), while narrowly expressed, recently evolved metabolic genes are in the fast phase (k₁, more loss-tolerant).

**Analysis:** Multiple regression: dN/dS ~ tissue breadth + network centrality + gene age. The residuals should show a biphasic pattern.

---

## Summary: Priority Datasets for Immediate Testing

| Priority | Dataset | Category | Analysis Type | Phylogenetic Correction | Feasibility |
|----------|---------|----------|---------------|------------------------|------------|
| **1** | LTEE genome time series (Dryad) | 1 | Time-series curve fitting | ARIMA | **Ready now** — data public |
| **2** | Wright et al. 2016 island birds | 3 | PGLS + bi-exponential | PGLS (100 trees included) | **Ready now** — data public |
| **3** | C4 PEPC convergence (GenBank + TreeBASE) | 5 | Phylogenetic convergence count | Yes (grass phylogeny) | Sequences available, need alignment |
| **4** | Endosymbiont genome size (Fisher et al. + NCBI) | 2 | PGLS | Yes (symbiont phylogeny) | **Ready now** — genomes + phylogenies |
| **5** | Levy yeast 10K generations | 1 | Time-series curve fitting | ARIMA | Sequence data available |
| **6** | Christin et al. C4 PEPC (2007) | 5 | Convergence count per lineage | Yes | Full alignment in supplementary |
| **7** | Human-GEM + HPA | 7 | Network centrality vs. tissue breadth | N/A | **Ready now** — both public |
| **8** | 1000 Genomes GRIPs | 4 | Rate per gene category | N/A | **Ready now** |
| **9** | Asellus aquaticus cave transcriptomes | 3 | Differential expression timing | N/A | NCBI SRA available |
| **10** | Volvocine algae genomes | 6 | Expression breadth vs. complexity | Yes | Genomes public, need expression data |

## Data Access Quick Reference

| Repository | URL | Dataset Types |
|------------|-----|---------------|
| NCBI GenBank | https://www.ncbi.nlm.nih.gov/genbank/ | Genome sequences, plastomes |
| NCBI SRA | https://www.ncbi.nlm.nih.gov/sra | Raw sequencing reads |
| NCBI BioProject | https://www.ncbi.nlm.nih.gov/bioproject | Project-level access |
| Dryad | https://datadryad.org/ | Curated research datasets |
| Zenodo | https://zenodo.org/ | Research data + code |
| TreeBASE | https://www.treebase.org/ | Phylogenetic trees + matrices |
| GitHub | https://github.com/ | Code + data (various repos) |
| Metabolic Atlas | https://metabolicatlas.org/ | Human-GEM + HPA integration |
| Human Protein Atlas | https://www.proteinatlas.org/ | Tissue-specific protein expression |
| GTEx | https://gtexportal.org/ | Tissue-specific gene expression |
| 1000 Genomes | https://www.internationalgenome.org/ | Human genetic variation |
| JGI MycoCosm | https://mycocosm.jgi.doe.gov/ | Fungal genomes |
| Phytozome | https://phytozome-next.jgi.doe.gov/ | Plant genomes |
| LTEE resource | https://the-ltee.org/resources/ | LTEE data + publications |

---

## Key Limitations and Caveats

1. **No single dataset covers all 7 categories** — each category tests a different aspect of the bi-exponential model. Convergent evidence across categories is the goal.

2. **Time resolution is critical** — the bi-exponential model requires knowing the time since the perturbation (colonization, symbiosis, parasitism, eusocial transition). For most systems, this must be estimated from molecular clocks or biogeographic data, introducing uncertainty.

3. **Cross-sectional vs. longitudinal** — most datasets are cross-sectional (modern species comparisons). Only the LTEE and yeast evolution experiments provide true longitudinal time series. Cross-sectional data requires the assumption that the observed variation across species reflects the trajectory of a single lineage.

4. **Phylogenetic non-independence** — most of the planned analyses require PGLS or similar phylogenetic correction. The strength of the conclusions depends on the quality of the phylogenetic tree.

5. **Measurement of ρ²** — the bi-exponential formula requires knowing the equilibrium values (ρ₁, ρ₂). These are not always known a priori and may need to be estimated as free parameters, which reduces statistical power.

6. **Confounding variables** — many factors besides integration depth affect the rate of functional loss: population size, mutation rate, strength of selection, drift. These need to be controlled for in the analysis.

---

*Generated by survey of NCBI, Dryad, Zenodo, TreeBASE, GitHub, and published literature. All DOIs and accessions verified against public databases as of 2026-08-18.*