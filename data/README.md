# Data Provenance
#
# Every file documented with source, version, and description.

orobanchaceae_tree.nwk:
  source: "NCBI GenBank, assembled from accessions"
  version: "2026-07-19"
  description: "Newick phylogeny of Orobanchaceae species"

species_plastome_data.tsv:
  source: "NCBI GenBank plastome sizes"
  version: "2026-07-19"
  description: "Plastome size + parasitism score per species"
  columns: [species, plastome_size_kb, parasitism_score, family]

cross_family_plastome_data.tsv:
  source: "NCBI GenBank, 12+ parasitic plant families"
  version: "2026-07-19"
  description: "Cross-family plastome size + parasitism gradient"

endosymbiont_genome_data.tsv:
  source: "GenBank: Buchnera, Wigglesworthia, Carsonella, Blochmannia"
  version: "2026-07-19"
  description: "Endosymbiont genome sizes + host dependency scores"

bobay_ochman_table_s1.xlsx:
  source: "Bobay & Ochman (2017) Table S1"
  version: "2026-07-19"
  description: "140-species Ne vs niche breadth regression data"

dewar_pangenome_lifestyles.csv:
  source: "Dewar et al. (2024) supplementary"
  version: "2026-07-19"
  description: "Pan-genome lifestyle classifications"

dewar_pangenome_species.csv:
  source: "Dewar et al. (2024) supplementary"
  version: "2026-07-19"
  description: "Pan-genome species-level data"

orobanchaceae_retention_matrix.tsv:
  source: "archive/pre-foundry-scripts/run_formal_model.R (corrected flattening)"
  version: "2026-08-10"
  description: "8-species x 6-gene-category plastid-gene retention matrix (Remark R7)"
  columns: [species, parasitism_score, gene_category, dependency_score, retention]
  note: "Corrected gene-major flattening (as.vector(retention), not as.vector(t(retention))). The author's original script had a species-major flattening bug that scrambled dep <-> retention and produced the wrong GLM sign."

island_bird_morphology.csv:
  source: "archive/pre-foundry-scripts/run_formal_model.R + run_cross_kingdom_L3.R"
  version: "2026-08-10"
  description: "8 island-bird flight-loss traits with dependency scores and observed change ranks"
  columns: [structure, dependency_score, observed_rank]
  note: "Used by load_island_birds() and empirical_formal_model() cross-kingdom transfer."

dewar_panX_tree.nex:
  source: "Dewar et al. (2024) supplementary"
  version: "2026-07-19"
  description: "NEXUS phylogeny for pan-genome analysis"

convsigns/signBase_randomized.csv:
  source: "SignBase v2.0 — Dutkiewicz, Russo, Lee & Bentz (2020) Sci Data 7, 364"
  version: "2025-03-06"
  description: "Sign sequences from Swabian Aurignacian mobile artifacts (260 objects, 213 usable sequences). Columns: object_id, object_type, material, preservation, dimensions, dates, original and cleaned sign codings."
  doi: 10.5281/zenodo.18401937
  derived_from: "PaleoSigns repository — github.com/christianbentz/PaleoSigns"

convsigns/Sb2Artifact-2025-03-06.csv:
  source: "SignBase v2.0 — Dutkiewicz et al. (2020)"
  version: "2025-03-06"
  description: "Artifact-level metadata for SignBase objects: dimensions, preservation state, site, dating."
  columns: [object_id, site, material, object_type, length_mm, width_mm, depth_mm, preservation, dating]

convsigns/Sign-2025-03-06.csv:
  source: "SignBase v2.0 — Dutkiewicz et al. (2020)"
  version: "2025-03-06"
  description: "Sign type definitions for SignBase: UTF-8 encodings, Unicode classifications, visual references."
