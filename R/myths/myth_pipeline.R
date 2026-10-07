#' Myth pipeline — main orchestration for phylomythology analyses
NULL

suppressPackageStartupMessages({
  library(tidyr)
  library(ape)
})

source("R/myths/myth_loaders.R")
source("R/myths/myth_networks.R")
source("R/myths/myth_statistics.R")
source("R/myths/myth_phylogeny.R")

# ==============================================================================
# Simulacrum: synthetic myth data with known ground truth
# ==============================================================================

#' Generate simulacrum myth dataset
simulacrum_myth_data <- function(n_versions = 50, n_slow_chars = 10, n_fast_chars = 20,
                                  noise_level = 0.1, seed = 42, n_regions = 4) {
  withr::with_seed(seed, {
    # ---- Distance matrix for tree ----
    dist_cols <- list()
    for (j in 1:n_versions) {
      col <- vector()
      for (i in 1:n_versions) {
        d <- ifelse(i == j, 0, abs(i - j) / n_versions + runif(1) * 0.1)
        col <- c(col, d)
      }
      dist_cols <- c(dist_cols, list(col))
    }
    rand_df <- data.frame(v1 = dist_cols[[1]])
    for (j in 2:n_versions) {
      rand_df <- cbind(rand_df, data.frame(r = dist_cols[[j]]))
    }
    colnames(rand_df) <- paste0("V", 1:n_versions)
    true_tree <- ape::nj(as.matrix(rand_df))

    # ---- Regions ----
    clade_sizes <- rep(floor(n_versions / n_regions), n_regions)
    remainder <- n_versions - sum(clade_sizes)
    if (remainder > 0) clade_sizes[n_regions] <- clade_sizes[n_regions] + remainder
    regions <- vector()
    for (r in 1:n_regions) regions <- c(regions, rep(r, clade_sizes[r]))
    regions <- regions[1:n_versions]

    # ---- Character matrix (column by column) ----
    n_chars <- n_slow_chars + n_fast_chars
    char_names <- vector()
    cols_list <- list()

    for (c in 1:n_chars) {
      col <- vector()
      if (c <= n_slow_chars) {
        char_names <- c(char_names, paste0("S", c, "_Region"))
        tr <- (c %% n_regions) + 1
        for (v in 1:n_versions) {
          col <- c(col, ifelse(runif(1) < noise_level, round(runif(1)),
                               ifelse(regions[v] == tr, 1, 0)))
        }
      } else {
        fc <- c - n_slow_chars
        char_names <- c(char_names, paste0("F", fc, "_Fast"))
        for (v in 1:n_versions) {
          col <- c(col, ifelse(runif(1) < 0.3, 1, 0))
        }
      }
      cols_list <- c(cols_list, list(col))
    }

    char_matrix <- data.frame(c1 = cols_list[[1]])
    for (c in 2:n_chars) {
      char_matrix <- cbind(char_matrix, data.frame(r = cols_list[[c]]))
    }
    colnames(char_matrix) <- char_names

    list(
      char_matrix = as.matrix(char_matrix),
      matrix = char_matrix,
      true_tree = true_tree,
      n_versions = n_versions,
      n_characters = n_chars,
      version_names = paste0("V", 1:n_versions),
      character_names = char_names,
      metadata = list(
        n_versions = n_versions, n_slow = n_slow_chars, n_fast = n_fast_chars,
        noise = noise_level, n_regions = n_regions, seed = seed,
        known_slow = paste0("S", 1:n_slow_chars, "_Region"),
        known_fast = paste0("F", 1:n_fast_chars, "_Fast")))
  })
}


# ==============================================================================
# Main pipeline runner
# ==============================================================================

run_myth_pipeline <- function(matrix_data, dataset_name = "myth", seed = 42) {
  withr::with_seed(seed, {
    results <- list()
    results$dataset <- dataset_name
    results$n_versions <- matrix_data$n_versions
    results$n_characters <- matrix_data$n_characters
    cat(1, "  Pipeline [", dataset_name, "]: ", results$n_versions, "v x ",
        results$n_characters, "c\n")

    dist_m <- myth_distance(matrix_data, "hamming")
    results$distance <- list(method = "hamming")

    ord <- circular_order(dist_m)
    results$circular_order <- list(n_ordered = ord$n_taxa)

    contradictions <- all_contradictions(matrix_data$matrix, ord$order)
    contradictions <- classify_mythemes(contradictions)
    results$contradictions <- contradictions
    results$contradiction_summary <- contradiction_summary(contradictions)

    pca <- myth_pca(matrix_data$char_matrix)
    results$pca <- list(n_components = pca$n_retained,
                        explained_var_pc1 = pca$explained_var[1],
                        cumulative_var_3 = sum(pca$explained_var[1:min(3, length(pca$explained_var))]))

    if (results$n_characters <= 50 && results$n_characters > 1) {
      co <- cooccurrence_matrix(matrix_data$matrix)
      results$cooccurrence <- list(n_co_chars = nrow(co))
    }

    if (results$n_characters >= 3 && results$n_versions >= 4) {
      results$signal <- ri_signal_test(matrix_data, ord$nj_tree, n_random = 50, seed = seed)
    }

    if (results$n_characters >= 3) {
      results$ri_comparison <- test_slow_vs_fast_ri(matrix_data, contradictions, ord$nj_tree)
    }

    ancestral <- reconstruct_ancestral(ord$nj_tree, matrix_data)
    results$ancestral <- ancestral
    results$n_root_characters <- nrow(ancestral)
    results$divergence <- myth_divergence_times(ord$nj_tree)
    results$status <- "complete"
    results
  })
}


# ==============================================================================
# Pipeline stage functions
# ==============================================================================

run_stage_myth_simulacra <- function() {
  cat(1, "=== Myth Pipeline: Simulacra ===\n")
  for (s in 1:3) {
    seed <- 42 + s
    sim <- simulacrum_myth_data(n_versions = 20 + s*10, n_slow_chars = 6, n_fast_chars = 12,
                                noise_level = 0.15, seed = seed)
    pipeline <- run_myth_pipeline(sim, paste0("sim_", s), seed = seed)
    cat(1, "  Sim", s, ": slow=", pipeline$contradiction_summary$n_slow,
        " fast=", pipeline$contradiction_summary$n_fast,
        " meanRI=", round(pipeline$signal$observed_mean_ri, 3), "\n")
  }
  list(status = "simulacra_complete")
}


run_stage_load_myths <- function() {
  cat(1, "=== Myth Pipeline: Loading data ===\n")
  datasets <- list()
  if (file.exists("data/myths/cosmic_hunt_matrix.csv")) {
    datasets$cosmic_hunt <- load_myth_matrix("data/myths/cosmic_hunt_matrix.csv")
    cat(1, "  Loaded Cosmic Hunt:", datasets$cosmic_hunt$n_versions, "x",
        datasets$cosmic_hunt$n_characters, "\n")
  } else {
    cat(1, "  (no Cosmic Hunt data yet)\n")
  }
  datasets
}


run_myth_analysis <- function() {
  cat(1, "====================================\n  PHYLOMYTHOLOGY PIPELINE\n====================================\n\n")
  run_stage_myth_simulacra()
  run_stage_load_myths()
  list(status = "complete")
}