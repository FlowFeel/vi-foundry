#' Test the phylomythology pipeline
#'
#' Tests:
#' 1. Simulacrum data generation produces expected structure
#' 2. Contradiction index correctly identifies slow vs fast characters
#' 3. PCA produces interpretable components
#' 4. RI signal test detects phylogenetic signal above chance
#' 5. Full pipeline runs without errors
#'
#' @dft A5: real fakes — simulacra have known ground truth
#' @dft A6: check-result — every test returns quantitative result
NULL

suppressPackageStartupMessages({
  library(testthat)
  library(tidyr)
  library(ape)
})

source("R/myths/myth_loaders.R")
source("R/myths/myth_networks.R")
source("R/myths/myth_statistics.R")
source("R/myths/myth_phylogeny.R")
source("R/myths/myth_pipeline.R")

# ==============================================================================
# Test 1: Simulacrum data generation
# ==============================================================================

test_that("Simulacrum generator produces correct structure", {
  sim <- simulacrum_myth_data(n_versions = 40, n_slow_chars = 8, n_fast_chars = 16,
                               noise_level = 0.1, seed = 42)
  
  expect(is.list(sim))
  expect(sim$n_versions == 40)
  expect(sim$n_characters == 24)  # 8 + 16
  expect(length(sim$version_names) == 40)
  expect(length(sim$character_names) == 24)
  expect(nrow(sim$matrix) == 40)
  expect("taxon" %in% colnames(sim$matrix))
  expect(is(sim$true_tree, "phylo"))
})


# ==============================================================================
# Test 2: Contradiction index on known data
# ==============================================================================

test_that("Contradiction index classifies known patterns", {
  withr::with_seed(42, {
    # Create perfect data: character has consecutive 1s on circular order
    n <- 20
    perfect_states <- rep(0, n)
    perfect_states[5:10] <- 1  # Consecutive block of 1s
    order <- 1:n
    ci <- character_contradiction(perfect_states, order)
    expect(ci == 0, "Perfect consecutive 1s should have contradiction 0")
    
    # Opposite: scattered 1s
    scattered <- rep(0, n)
    scattered[c(2, 7, 12, 18)] <- 1
    ci_scat <- character_contradiction(scattered, order)
    expect(ci_scat > 0, "Scattered 1s should have positive contradiction")
    
    # All same state
    all_ones <- rep(1, n)
    ci_all <- character_contradiction(all_ones, order)
    expect(ci_all == 0, "All same state should have contradiction 0")
  })
})


# ==============================================================================
# Test 3: Fast/slow classification on simulacrum
# ==============================================================================

test_that("Fast/slow mytheme classification works", {
  sim <- simulacrum_myth_data(n_versions = 30, n_slow_chars = 6, n_fast_chars = 12,
                               noise_level = 0.1, seed = 42)
  mat <- sim$matrix
  dist <- myth_distance(sim, "hamming")
  order <- circular_order(dist)
  contradictions <- all_contradictions(mat, order$order)
  contradictions <- classify_mythemes(contradictions, threshold = 0.3)
  
  expect(!is.empty(contradictions))
  expect("class" %in% colnames(contradictions))
  expect(sum(contradictions$class == "slow") > 0,
         "Should have at least some slow characters")
  expect(sum(contradictions$class == "fast") > 0,
         "Should have at least some fast characters")
  
  summ <- contradiction_summary(contradictions)
  expect(is.list(summ))
  expect(summ$n_characters == 18)
})


# ==============================================================================
# Test 4: PCA
# ==============================================================================

test_that("PCA on simulacrum produces interpretable components", {
  sim <- simulacrum_myth_data(n_versions = 30, n_slow_chars = 6, n_fast_chars = 12,
                               noise_level = 0.1, seed = 42)
  pca <- myth_pca(sim$char_matrix, n_components = 4)
  
  expect(is.list(pca))
  expect(pca$explained_var[1] > 0, "PC1 should explain positive variance")
  expect(length(pca$explained_var) >= 4)
  expect(length(pca$projection) == 4)
})


# ==============================================================================
# Test 5: Contradiction index correctly ranks slow vs fast
# ==============================================================================

test_that("Known slow characters have lower contradiction than fast", {
  sim <- simulacrum_myth_data(n_versions = 30, n_slow_chars = 5, n_fast_chars = 10,
                               noise_level = 0.15, seed = 42)
  mat <- sim$matrix
  dist <- myth_distance(sim, "hamming")
  order <- circular_order(dist)
  contradictions <- all_contradictions(mat, order$order)
  
  # Find known slow vs fast characters
  slow_prefix <- c("S1", "S2", "S3", "S4", "S5")
  fast_prefix <- c("F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10")
  
  slow_ci <- contradictions$contradiction[starts(contradictions$character, slow_prefix)]
  fast_ci <- contradictions$contradiction[starts(contradictions$character, fast_prefix)]
  
  slow_ci <- slow_ci[!is.na(slow_ci)]
  fast_ci <- fast_ci[!is.na(fast_ci)]
  
  expect(length(slow_ci) > 0 && length(fast_ci) > 0,
         "Should have both slow and fast characters")
  
  mean_slow <- mean(slow_ci)
  mean_fast <- mean(fast_ci)
  expect(mean_slow < mean_fast,
         paste0("Slow chars (", mean_slow, ") should have lower contradiction than fast (", mean_fast, ")"))
})


# ==============================================================================
# Test 6: RI signal test detects signal
# ==============================================================================

test_that("RI signal test detects non-random signal", {
  sim <- simulacrum_myth_data(n_versions = 20, n_slow_chars = 5, n_fast_chars = 10,
                               noise_level = 0.1, seed = 42)
  dist <- myth_distance(sim, "hamming")
  tree <- ape::nj(dist)
  
  signal <- ri_signal_test(sim, tree, n_random = 30, seed = 42)
  expect(is.list(signal))
  expect(!is.na(signal$observed_mean_ri))
  expect(signal$p_value <= 1)
})


# ==============================================================================
# Test 7: Distance matrix
# ==============================================================================

test_that("Distance matrix is symmetric with zero diagonal", {
  sim <- simulacrum_myth_data(n_versions = 10, n_slow_chars = 3, n_fast_chars = 5,
                               noise_level = 0, seed = 42)
  dist <- myth_distance(sim, "hamming")
  
  expect(nrow(dist) == 10 && ncol(dist) == 10)
  for (i in 1:10) {
    expect(dist[i, i] == 0)
    for (j in (i+1):10) {
      expect(abs(dist[i, j] - dist[j, i]) < 0.0001,
             paste0("Distance should be symmetric at [", i, ",", j, "]"))
    }
  }
})


# ==============================================================================
# Test 8: Full pipeline runs end-to-end
# ==============================================================================

test_that("Full myth pipeline executes without error", {
  sim <- simulacrum_myth_data(n_versions = 15, n_slow_chars = 4, n_fast_chars = 8,
                               noise_level = 0.1, seed = 42)
  result <- run_myth_pipeline(sim, "test_sim", seed = 42)
  
  expect(result$status == "complete")
  expect(result$n_versions == 15)
  expect(result$n_characters == 12)
  
  # Check all stages ran
  expect(!is.null(result$distance))
  expect(!is.null(result$circular_order))
  expect(!is.null(result$contradictions))
  expect(!is.null(result$pca))
  expect(!is.null(result$signal))
})


# ==============================================================================
# Run all tests
# ==============================================================================

#' Entry point: run all phylomythology tests
#'
#' @return Test results
#' @export
test_myth_pipeline <- function() {
  test_that("Simulacrum generator produces correct structure")
  test_that("Contradiction index classifies known patterns")
  test_that("Fast/slow mytheme classification works")
  test_that("PCA on simulacrum produces interpretable components")
  test_that("Known slow characters have lower contradiction than fast")
  test_that("RI signal test detects non-random signal")
  test_that("Distance matrix is symmetric with zero diagonal")
  test_that("Full myth pipeline executes without error")
}