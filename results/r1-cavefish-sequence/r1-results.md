---
uri: vi-foundry/results/r1-cavefish-sequence/r1-results
author: Flow
date: 2026-08-24
status: complete
---

# R1: Cavefish Sequence Test — Results

## The Test

Does STRING protein interaction network degree (independent of trait-loss data) predict the order of trait loss in cavefish?

- **Independent variable:** STRING network degree for zebrafish orthologs (queried live from string-db.org API, species 7955 Danio rerio)
- **Dependent variable:** Loss-timing rank from developmental literature (1=earliest ~10hpf, 4=latest ~72hpf+)
- **Genes tested:** 22 genes across 4 categories (eye, pigment, circadian, metabolic)

## The Result

**Spearman ρ = −0.013, p = 0.956. Permutation test (one-sided): p = 0.521.**

**No relationship. STRING network degree does NOT predict loss order.**

### By category:

| Category | Mean STRING degree | Mean loss timing | Lost when? |
|----------|-------------------|-----------------|------------|
| Pigment | 110 | 1.0 | First |
| Eye | 73 | 2.6 | Mid |
| Circadian | 70 | 4.0 | Last |
| Metabolic | 139 | 4.0 | Last |

### What VI predicted:
Low-integration (low-degree) traits lost first. If VI is right, pigment (lost first) should have LOW degree, circadian (lost last) should have HIGH degree.

### What we found:
**The opposite.** Pigment genes have the HIGHEST mean degree (110) and are lost FIRST. Circadian genes have LOW degree (70) and are lost LAST. This is the reverse of the VI prediction.

## What This Means

The integration-depth ordering prediction is **not supported** when measured with STRING network degree as the independent integration-depth metric.

### Possible interpretations:

**A. STRING degree is the wrong metric.** STRING measures protein-protein interactions, not developmental dependency depth. A gene can have many interaction partners (high degree) but few downstream developmental dependencies (low depth). The right metric might be:
- Dependency depth (longest path from gene to terminal in the regulatory network)
- Developmental timing (early expression = deep integration) — but this is also not straightforward
- Pleiotropy (number of phenotypes affected by the gene) — closer to the concept but harder to measure

**B. The prediction is wrong for cavefish.** Trait loss in cavefish may follow a different principle — metabolic cost or environmental demand, not integration depth. Pigment is lost first because it's metabolically expensive (melanin synthesis) and useless in darkness. Eyes are lost next because they're developmentally expensive and useless. Circadian regulation persists because it's still useful (even cavefish need metabolic cycling). The ordering follows **functional demand**, not integration depth.

**C. The prediction needs refinement.** Integration depth might predict ordering at the gene level (which genes in a pathway are lost first) but not at the trait level (which traits are lost first). Pigment genes have high degree because they interact with many pathways, but melanin production as a trait might have low "trait-level integration depth" because losing the whole pathway at once is feasible.

### Critical caveat:

This is one metric (STRING degree) in one system (cavefish) at the trait level. The monograph's P3 result (integration-depth ordering in endosymbionts and Orobanchaceae) was measured differently (dependency score from metabolic networks, not STRING PPI). The P3 result may still hold with the original metric. But the failure to replicate with an independent metric in cavefish is concerning.

## What Would Strengthen This

1. **Try dependency depth instead of degree.** Compute longest path from each gene to a terminal node in the GRN. This is closer to "integration depth" as the monograph defines it.
2. **Try at the gene level, not trait level.** Within the eye pathway, do low-degree crystallin genes lose function before high-degree regulatory genes (PAX6)?
3. **Try in endosymbionts.** Does STRING degree predict gene loss order in Buchnera? This would test whether the metric works in systems where the monograph's original metric succeeded.

## Files

- `r1-raw-data.tsv` — 22 genes, category, loss-timing rank, STRING degree
- `r1-results.md` — this file
