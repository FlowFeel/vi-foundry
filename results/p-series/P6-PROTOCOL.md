# P6 Protocol — Convergent Cognition Gene Centrality, A Priori Contrast

**Date:** 2026-08-24
**Pre-registration:** Score file frozen at `data/a-priori-scores/p6_convergent_cognition_symbols.tsv` before outcome merge. No centrality data consulted during set construction.
**Status:** PROTOCOL

## Question

Does integration position (Component B) order cognitive convergence? Prediction: convergent cognitive genes are LESS integrated than conserved neural machinery in the same functional domain — "function converges, mechanism diverges" extended from echolocation (P4) to cognition.

## Design (direct extension of P4)

- **Convergent set:** Genes implicated in cognitive convergence across birds, mammals, and cetaceans — those showing accelerated evolution, lineage-specific expansion, or convergent functional recruitment in corvids + cetaceans + primates. Assembled from comparative cognition genomics literature: FOXP2 (vocal learning convergence), CNTNAP2 (neurexin, language-associated), MTOR and mTOR pathway genes (synaptic plasticity, cognitive enhancement), and the broader cognitive convergence gene set (SRGAP2, AUTS2, ARC, CAMK2A, CREB1, BDNF, FMR1, SHANK family, NLGN family, NRXN1, SYNGAP1, DISC1, EGR1, NPAS4, RPS6KB1, EIF4E, TSC1/2, RHEB, AKT/GSK3B/MAPK signaling, CDC42/RAC1/PAK/LIMK cofilin pathway, WASF/CYFIP/FMRP regulon). These are genes where convergent evolution in cognitive lineages has been documented — accelerated sequence evolution, copy-number expansion, or convergent expression patterns in independently-evolved cognitive lineages (Emery & Clayton 2004, *Phil Trans R Soc B*; Roth 2015, *Brain Behav Evol*; Jarvis et al. 2000, *Nature*; Zhang et al. 2014, *Nature Communications*; Pollard et al. 2006, *Nature*).

- **Conserved control:** Conserved neural machinery genes in the same functional domain — ion channel families (SCN, KCN, CACNA families), synaptic release machinery (SNARE complex: SNAP25, STX1A, VAMP2, SYT family, RAB3, RIM, UNC13, MUNC18/STXBP, NSF, NAPA/B), G-protein signaling (GNAO1, GNB/GNG families), neurotransmitter receptors (GABRA/B/G, GRIA, GRIK, GRIN, GRM families). These are the machinery any nervous system requires — the "conserved neural kernel" that should be centrally integrated by virtue of functional necessity.

- **Network backbone:** STRING v12.0 human protein interaction network (protein.links, confidence ≥ 400), identical to P4. Degree + eigenvector + closeness centrality computed on the full 19,488-node graph. STRING is human proteomics interaction data — independent of the cognitive convergence calls. Non-circular.

- **Null correction (critical):** Identical to P4. Whole-genome background is the WRONG null — dominated by low-constraint genes. The correct null is conserved machinery in the same functional domain. This is what makes the contrast meaningful.

- **Prediction:** Convergent cognitive genes sit at lower centrality than conserved neural machinery in the same domain — across all three centrality metrics (degree, eigenvector, closeness).

- **Pipeline:** Identical to P4 — Mann-Whitney U (one-tailed, convergent < conserved) on degree, eigenvector centrality, and closeness centrality.

## Pre-registration Statement

The convergent set was defined *from the comparative cognition literature* — not from centrality data. The conserved control was defined *from functional annotation* (structural neural machinery, neurotransmitter systems, synaptic release machinery) — not from centrality data. Both sets are frozen at `p6_convergent_cognition_symbols.tsv` before any STRING centrality computation. This is a pre-registered a priori contrast.

## Caveats (pre-registered)

1. **Human STRING, not ancestral-mammal network.** Same limitation as P4. STRING is the best-sampled human interaction network; the centrality backbone is independent of the convergence calls. This is a limitation to note, not a fatal one.
2. **Convergent set definition.** The cognitive convergence gene set is curated from the literature. It is defensible but human-assembled; results should be stress-tested with alternative convergent sets (e.g., from a systematic accelerated-evolution scan across corvid/cetacean/primate genomes).
3. **Mapped subset.** Expect some symbol aliasing differences between the curated set and STRING's protein alias map. The unmapped fraction should be documented and checked for systematic bias.
4. **Same domain contrast.** The critical design choice is the conserved control from the same functional domain (neural machinery), not the whole-genome background. This is the same lesson P4 taught — and the same correction applied here.

## Next

After analysis: compute Mann-Whitney U on all three centrality metrics. Document the contrast with the whole-genome background (which is expected to show the wrong-null artifact, as in P4). Write P6-RESULTS.md.