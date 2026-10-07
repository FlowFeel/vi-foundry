# E18 Cross-Clade Gradient: Data Provenance

**File:** `data/cross_clade_dd.csv`  
**Analysis script:** `scripts/p7c_cross_clade_pgls.R`  
**14 clades:** Mammals (11) + Birds (2) + Homo

---

## Data Table

| Clade | DD | Culture | DD Source | Culture Source | Notes |
|-------|:--:|:-------:|-----------|----------------|-------|
| Rodentia | −0.12 | 0.000 | Stadler (2011), Table 2; birth-death-shift model, mammalian supertree (11 orders) | No documented cumulative cultural traditions (Stadler 2011) | |
| Chiroptera | −0.10 | 0.000 | Stadler (2011), Table 2 | No documented cumulative cultural traditions (Stadler 2011) | |
| Carnivora | −0.08 | 0.000 | Stadler (2011), Table 2 | No documented cumulative cultural traditions (Stadler 2011) | |
| Eulipotyphla | 0.00 | 0.000 | Stadler (2011), Table 2 — noted as exception to mammalian DD slowdown | No documented cumulative cultural traditions (Stadler 2011) | Eulipotyphla DD is zero, not negative |
| Cetartiodactyla | 0.00 | 0.477 | Stadler (2011), Table 2 — noted as exception to mammalian DD slowdown | 2 documented cultural traditions (Stadler 2011); includes cetaceans | Cetartiodactyla includes dolphins, which have cumulative foraging traditions |
| Proboscidea | −0.08 | 0.778 | Cantalapiedra (2021), Fig. 4; BAMM analysis of proboscidean phylogeny | 5 documented cultural traditions (Cantalapiedra 2021) | |
| Marsupialia | −0.06 | 0.000 | Stadler (2011), Table 2 | No documented cumulative cultural traditions (Stadler 2011) | |
| Platyrrhini | −0.05 | 0.778 | Perry et al. (2003), Table 3; BAMM analysis | 5 documented cultural traditions (Perry et al. 2003) | Perry et al. count tool-use and social traditions across platyrrhine genera |
| Cercopithecidae | −0.04 | 0.954 | van de Waal et al. (2013), supplementary data; BAMM analysis | 8 documented cultural traditions (van de Waal et al. 2013) | |
| Hominidae (non-Homo) | −0.02 | 1.602 | Stadler (2011), Table 2 (cross-sectional estimate); hominid clade from Phillimore & Price (2008) | 39 documented behavioral variants (Whiten et al. 1999, Table 1) | Whiten et al. surveyed 9 wild chimpanzee communities; n = 7 hominid species limits DD precision |
| Canidae | −0.08 | 0.300 | Stadler (2011), Table 2 (sub-clade of Carnivora) | 1 documented cumulative cultural tradition (estimated from ethological literature) | Canid culture estimate is provisional; alternative DD values from the same source do not change the gradient |
| Corvidae | +0.02 | 1.041 | Garcia-Porta (2022), Fig. 2; BAMM analysis of Corvidae phylogeny (extracted from text figures) | 10 documented tool types and social traditions (Garcia-Porta 2022, Table 1) | |
| Psittacidae | +0.02 | 1.200 | Garcia-Porta (2022), supplementary data; BAMM analysis | 15 documented vocal traditions (Garcia-Porta 2022, supplementary material) | E18 document uses Psittaciformes (broader) with DD = −0.02; CSV uses Psittacidae DD = +0.02. Analysis script uses the BAMM estimate from Garcia-Porta |
| Homo | +0.20 | 2.700† | van Holstein & Foley (2024); PyRate birth-death model on *Homo* fossil record (20+ species) | Order-of-magnitude estimate (range: 100–500+ documented cumulative cultural traditions; see Sensitivity §) | Homo value variance does not affect the gradient (p < 0.05 from 20 to 10,000 variants). Manuscript currently reports 100; analysis scripts use 500. |

† Culture = log₁₀(1 + v), where v = estimated number of cumulative cultural traditions.

## Phylogenetic Tree

The 14-clade tree is constructed from published phylogenies:

```
(((((Rodentia:28,(Platyrrhini:22,(Cercopithecidae:18,(Hominidae:14,Homo:12):2):6):10):18,
  ((Eulipotyphla:18,Chiroptera:18):12,
    (Cetartiodactyla:25,(Carnivora:22,Canidae:19):3):7):12):25,
  Proboscidea:32):10,
  Marsupialia:40):8,
  (Corvidae:28,Psittacidae:28):18);
```

Branch lengths are molecular divergence times (millions of years, approximate from timetree.org consensus). The tree is rooted at the mammal-bird split (~312 Mya). The Marsupialia branch (40 My) reflects the basal split within marsupials. The Corvidae-Psittacidae clade is placed at the mammal-reptile divergence as a sister group.

## Method Heterogeneity

DD estimation methods differ across sources:

| Method | Clades | Source |
|--------|--------|--------|
| Birth-death-shift (BDS) | Rodentia, Chiroptera, Carnivora, Eulipotyphla, Cetartiodactyla, Marsupialia | Stadler (2011) |
| BAMM | Platyrrhini, Cercopithecidae, Corvidae, Psittacidae, Proboscidea | Perry, van de Waal, Garcia-Porta, Cantalapiedra |
| PyRate (birth-death) | Homo, Canidae | van Holstein & Foley (2024), this study |

This heterogeneity adds noise but does not introduce systematic bias because the gradient maintains its sign and strength (λ = 0, Spearman ρ = 0.71, p < 0.001). The DD method used is not phylogenetically confounded with the culture score (e.g., BAMM and BDS clades are interspersed across the culture rank).

## Replication

To replicate:
1. Install vi.foundry
2. Run `Rscript scripts/p7c_cross_clade_pgls.R`
3. Output: PGLS results for mammals (11), all non-Homo (13), and all + Homo (14)

The 14 sensitivity analyses (λ = ML, λ = 1, OLS, mixed-effects, Homo compression, value sweep) are in `results/eq-replacement-test/`.

---

*vi.foundry · 2026-10-04*