suppressPackageStartupMessages({
  library(ape)
  library(tidyr)
  library(stats)
  library(utils)
})
source("R/myths/myth_loaders.R")
source("R/myths/myth_networks.R")
source("R/myths/myth_statistics.R")
source("R/myths/myth_phylogeny.R")
source("R/myths/myth_pipeline.R")
set.seed(42)

sim <- simulacrum_myth_data(n_versions = 30, n_slow_chars = 6, n_fast_chars = 18, noise_level = 0.25, seed = 42)
cat(1, "Simulacrum: ", sim$n_versions, "x", sim$n_characters, "\n\n")

dist_m <- myth_distance(sim, "hamming")
ord <- circular_order(dist_m)
cat(1, "1) Distance matrix     :", nrow(dist_m), "x", ncol(dist_m), "\n")
cat(1, "2) NJ tree             :", length(ord$nj_tree$tip.label), "tips\n")
cat(1, "3) Circular order      :", length(ord$order), "indices\n")

cons <- all_contradictions(sim$matrix, ord$order)
cons <- classify_mythemes(cons)
cat(1, "4) Contradiction idx    :", nrow(cons), "chars:",
    sum(cons$class=="slow"), "slow,", sum(cons$class=="fast"), "fast\n")

pca <- myth_pca(sim$char_matrix)
cat(1, "5) PCA                 : PC1", round(pca$explained_var[1]*100, 1), "%\n")

cat(1, "\nWorking modules: loaders, networks, pipeline, statistics\n")
cat(1, "Not working: ape:::parsimony, ape:::dist.root.to.tip, data.frame building\n")
cat(1, "FOUNDRY INFRASTRUCTURE READY - need Python for RI/signal tests\n")