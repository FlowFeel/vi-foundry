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

dewar_panX_tree.nex:
  source: "Dewar et al. (2024) supplementary"
  version: "2026-07-19"
  description: "NEXUS phylogeny for pan-genome analysis"
