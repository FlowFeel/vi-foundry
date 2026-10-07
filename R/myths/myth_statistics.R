#' Myth statistical analyses — PCA, factor analysis, retention index, signal tests
#'
#' @name myth_statistics
NULL

suppressPackageStartupMessages({
  library(stats)
  library(ape)
  library(tidyr)
})

# ==============================================================================
# PCA / Factor Analysis (Berezkin-style)
# ==============================================================================

#' PCA on myth character matrix
myth_pca <- function(char_matrix, n_components = 5) {
  # Remove zero-variance columns
  n <- ncol(char_matrix)
  keep <- vector()
  for (j in 1:n) {
    col <- char_matrix[, j]
    nas <- is.na(col)
    if (any(nas)) col[nas] <- mean(col[!nas])
    if (var(col) > 0) keep <- c(keep, j)
  }
  mat <- char_matrix[, keep]
  pca <- stats::prcomp(mat, center = TRUE, scale = TRUE)

  n_comp <- min(n_components, ncol(mat))
  ev <- pca$sd[1:n_comp]^2 / sum(pca$sd^2)

  proj <- as.data.frame(pca$x[, 1:n_comp])
  colnames(proj) <- paste0("PC", 1:n_comp)

  list(
    explained_var = ev,
    cumulative_var = cumsum(ev),
    projection = proj,
    n_retained = n_comp,
    n_total = ncol(mat))
}


# ==============================================================================
# Retention Index (RI) and Phylogenetic Signal
# ==============================================================================

#' Compute retention index via ape parsimony
character_retention_index <- function(tree, char_states) {
  n_tips <- length(tree$tip.label)
  n_states <- length(char_states)
  if (n_states != n_tips) return(list(ri = NA, n_steps = NA, observed = NA))

  k <- sum(char_states == 1)
  n_valid <- sum(!is.na(char_states) & char_states >= 0)

  if (k == 0 || k == n_valid) return(list(ri = 1, n_steps = 0, observed = 0))

  min_steps <- 1
  max_steps <- min(k, n_valid - k)

  # Try ape:::parsimony
  observed <- NA
  try({
    res <- ape::parsimony(tree, as.vector(char_states))
    observed <- res[[1]]
  })

  ri <- ifelse(is.na(observed), 1,
               max(0, min(1, (max_steps - observed) / (max_steps - min_steps))))
  list(ri = ri, n_steps = min_steps, observed = observed, k = k)
}


#' RI for all characters in a matrix
all_retention_indices <- function(matrix_data, tree) {
  mat <- matrix_data$matrix
  char_names <- matrix_data$character_names
  results <- data.frame()
  for (c in char_names) {
    states <- as.integer(mat[[c]])
    ri_res <- character_retention_index(tree, states)
    results <- rbind(results, data.frame(
      character = c,
      ri = ri_res$ri,
      n_valid = sum(!is.na(states)),
      n_ones = sum(states == 1)))
  }
  results
}


#' RI signal test: compare observed RI to random expectation
ri_signal_test <- function(matrix_data, tree, n_random = 50, seed = 42) {
  withr::with_seed(seed, {
    obs_ri <- all_retention_indices(matrix_data, tree)
    mean_obs <- mean(obs_ri$ri[!is.na(obs_ri$ri)])
    n_chars <- matrix_data$n_characters
    n_vers <- matrix_data$n_versions

    random_means <- vector()
    for (r in 1:n_random) {
      random_ri <- vector()
      for (c in 1:n_chars) {
        k <- floor(runif(1) * (n_vers - 1)) + 1
        random_states <- rep(0, n_vers)
        for (o in 1:k) {
          pos <- floor(runif(1) * n_vers) + 1
          random_states[pos] <- 1
        }
        ri_res <- character_retention_index(tree, random_states)
        random_ri <- c(random_ri, ifelse(is.na(ri_res$ri), 0, ri_res$ri))
      }
      random_means <- c(random_means, mean(random_ri))
    }

    list(
      observed_mean_ri = mean_obs,
      random_mean_ri = mean(random_means),
      random_sd_ri = sd(random_means),
      p_value = sum(random_means >= mean_obs) / n_random,
      n_random = n_random,
      significant = sum(random_means >= mean_obs) / n_random < 0.05)
  })
}


#' Compare slow vs fast mythemes RI
test_slow_vs_fast_ri <- function(matrix_data, contradictions, tree) {
  ri_all <- all_retention_indices(matrix_data, tree)
  ri_joined <- merge(ri_all, contradictions[, c("character", "class")], by = "character")
  slow <- ri_joined$ri[ri_joined$class == "slow"]
  fast <- ri_joined$ri[ri_joined$class == "fast"]
  slow <- slow[!is.na(slow)]
  fast <- fast[!is.na(fast)]
  list(
    slow_mean_ri = mean(slow), fast_mean_ri = mean(fast),
    slow_sd_ri = sd(slow), fast_sd_ri = sd(fast),
    n_slow = length(slow), n_fast = length(fast),
    difference = mean(slow) - mean(fast))
}