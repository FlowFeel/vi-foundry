#' Myth phylogenetic networks — NeighborNet, contradiction index, fast/slow mytheme analysis
#'
#' @name myth_networks
NULL

suppressPackageStartupMessages({
  library(ape)
  library(tidyr)
})

# ==============================================================================
# Simplified NeighborNet: circular ordering via NJ
# ==============================================================================

#' Generate circular ordering via NJ tree
circular_order <- function(dist_mat) {
  n <- nrow(dist_mat)
  # Convert data.frame to matrix if needed
  if (is.data.frame(dist_mat)) {
    mat <- as.matrix(dist_mat)
  } else {
    mat <- dist_mat
  }
  nj_tree <- ape::nj(mat)
  nj_ladder <- ape::ladderize(nj_tree)
  # Use tip labels as order (ape::tips not available)
  tip_names <- nj_ladder$tip.label
  orig_names <- colnames(dist_mat)
  tip_order <- vector()
  for (t in tip_names) {
    idx_list <- which(orig_names == t)
    if (length(idx_list) > 0) tip_order <- c(tip_order, idx_list)
  }
  list(order = tip_order, nj_tree = nj_tree, n_taxa = n)
}


# ==============================================================================
# Contradiction Index (Thuillard 2007)
# ==============================================================================

#' Compute contradiction index for a single binary character
character_contradiction <- function(states, order) {
  stopifnot(length(states) == length(order))

  n <- length(order)
  ordered_states <- states[order]
  valid <- !is.na(ordered_states)
  ordered <- ordered_states[valid]
  n_valid <- length(ordered)

  if (n_valid < 3) return(list(ci = NA))

  k <- sum(ordered == 1)
  if (k == 0 || k == n_valid) return(list(ci = 0))
  if (k > n_valid / 2) {
    ordered <- 1 - ordered
    k <- n_valid - k
  }

  # Minimum arc containing all 1s
  min_arc <- n_valid
  for (start in 1:n_valid) {
    ones_pos <- which(ordered == 1)
    adj_pos <- (ones_pos - start) %% n_valid
    if (length(adj_pos) > 0) {
      p_sorted <- sort(adj_pos)
      arc_lin <- p_sorted[length(p_sorted)] - p_sorted[1] + 1
      arc_cir <- n_valid - (p_sorted[length(p_sorted)] - p_sorted[1]) + 1
      min_arc <- min(min_arc, min(arc_lin, arc_cir))
    }
  }
  list(ci = ifelse(n_valid == k, 0, (min_arc - k) / (n_valid - k)))
}


#' Compute contradictions for all characters
all_contradictions <- function(char_matrix, order) {
  char_names <- colnames(char_matrix)
  results <- data.frame()
  for (c in char_names) {
    states <- as.integer(char_matrix[[c]])
    res <- character_contradiction(states, order)
    results <- rbind(results, data.frame(
      character = c, contradiction = res$ci,
      n_ones = sum(states == 1),
      n_valid = sum(!is.na(states))))
  }
  results
}


#' Classify characters as fast or slow-evolving
classify_mythemes <- function(contradictions, threshold = 0.3) {
  contradictions$class <- ifelse(is.na(contradictions$contradiction), "ambiguous",
    ifelse(contradictions$contradiction <= threshold, "slow", "fast"))
  contradictions
}


#' Contradiction summary
contradiction_summary <- function(contradictions) {
  valid <- contradictions[!is.na(contradictions$contradiction), ]
  list(
    n_characters = nrow(contradictions),
    n_valid = nrow(valid),
    mean_contradiction = mean(valid$contradiction),
    sd_contradiction = sd(valid$contradiction),
    median_contradiction = median(valid$contradiction),
    n_slow = sum(contradictions$class == "slow"),
    n_fast = sum(contradictions$class == "fast"),
    proportion_slow = sum(contradictions$class == "slow") / nrow(valid),
    threshold = 0.3)
}


#' Compute co-occurrence matrix between characters
cooccurrence_matrix <- function(char_matrix) {
  char_names <- colnames(char_matrix)
  n <- length(char_names)
  # Build column by column
  cols_list <- list()
  for (j in 1:n) {
    col <- vector()
    ci <- as.integer(char_matrix[[char_names[j]]])
    for (i in 1:n) {
      if (i == j) {
        col <- c(col, 0)
      } else {
        cj <- as.integer(char_matrix[[char_names[i]]])
        col <- c(col, sum(ci == 1 & cj == 1))
      }
    }
    cols_list <- c(cols_list, list(col))
  }
  df <- data.frame(c1 = cols_list[[1]])
  for (j in 2:n) df <- cbind(df, data.frame(r = cols_list[[j]]))
  colnames(df) <- char_names
  df
}


#' Detect character modules
detect_modules <- function(co, min_cooc = 5) {
  n <- ncol(co)
  char_names <- colnames(co)
  assigned <- rep(FALSE, n)
  modules <- list()
  for (i in 1:n) {
    if (assigned[i]) next
    module <- list(char_names[i])
    assigned[i] <- TRUE
    for (j in (i+1):n) {
      if (assigned[j]) next
      row_i <- as.integer(co[i, ])
      for (m in module) {
        k <- which(colnames(co) == m)
        if (!length(k) && row_i[k] >= min_cooc) {
          module <- c(module, char_names[j])
          assigned[j] <- TRUE
          break
        }
      }
    }
    if (length(module) > 1) modules <- c(modules, list(module))
  }
  modules
}


#' Filter to slow-evolving characters
filter_slow_mythemes <- function(matrix_data, contradictions) {
  slow_chars <- contradictions$character[contradictions$class == "slow"]
  if (length(slow_chars) == 0) return(matrix_data)
  mat <- matrix_data$matrix
  cols <- c(slow_chars[slow_chars %in% colnames(mat)])
  result <- list()
  result$matrix <- mat[, cols]
  result$character_names <- cols
  result$n_characters <- length(cols)
  result$n_versions <- matrix_data$n_versions
  result$version_names <- matrix_data$version_names
  result$char_matrix <- as.matrix(result$matrix)
  result
}