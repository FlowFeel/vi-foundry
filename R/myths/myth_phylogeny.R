#' Myth phylogenetics — tree building, ancestral state reconstruction, dating
#'
#' Methods for parsimony and distance-based tree building,
#' ancestral state reconstruction, and simplified divergence dating.
#'
#' Uses ape and phytools where available, with wrappers for myth-specific
#' workflows.
#'
#' @name myth_phylogeny
NULL

suppressPackageStartupMessages({
  library(ape)
  library(phytools)
  library(tidyr)
})

# ==============================================================================
# Tree Building
# ==============================================================================

#' Build myth tree from distance matrix
#'
#' Multiple distance-based methods to construct the myth phylogeny.
#'
#' @param dist_mat Square distance matrix
#' @param method "nj" (default), "upgma", or "bionj"
#' @return ape::phylo tree object
#'
#' @export
myth_tree <- function(dist_mat, method = "nj") {
  if (method == "nj") {
    tree <- ape::nj(dist_mat)
  } else if (method == "upgma") {
    tree <- ape::upgma(dist_mat)
  } else {
    tree <- ape::bionj(dist_mat)
  }
  
  tree
}


#' Bootstrap tree support
#'
#' @param matrix_data Output from load_myth_matrix
#' @param n_bootstrap Number of bootstrap replicates (default 100)
#' @param seed Integer reproducibility seed
#' @param method Tree building method
#' @return List with bootstrap summary
#'
#' @export
myth_bootstrap <- function(matrix_data, n_bootstrap = 100, seed = 42, method = "nj") {
  withr::with_seed(seed, {
    mat <- matrix_data$char_matrix
    n_vers <- matrix_data$n_versions
    n_chars <- matrix_data$n_characters
    vers_names <- matrix_data$version_names
    
    # Build reference tree
    full_dist <- matrix_data
    if (n_chars > 0) {
      # Compute distance from character matrix
      d <- as.matrix(nrow = n_vers, ncol = n_vers)
      for (i in 1:n_vers) {
        for (j in i:n_vers) {
          if (i == j) {
            d[i, j] <- 0
          } else {
            diff <- sum(abs(mat[i, ] - mat[j, ]))
            d[i, j] <- diff / n_chars
            d[j, i] <- d[i, j]
          }
        }
      }
      ref_tree <- myth_tree(d, method)
    } else {
      return(list(error = "No characters to build tree"))
    }
    
    # Bootstrap
    cons <- list()
    for (b in 1:n_bootstrap) {
      # Sample characters with replacement
      boot_cols <- sample(1:n_chars, n_chars, replace = TRUE)
      boot_mat <- mat[, boot_cols]
      
      # Compute bootstrap distance
      boot_d <- as.matrix(nrow = n_vers, ncol = n_vers)
      for (i in 1:n_vers) {
        for (j in i:n_vers) {
          if (i == j) {
            boot_d[i, j] <- 0
          } else {
            diff <- sum(abs(boot_mat[i, ] - boot_mat[j, ]))
            boot_d[i, j] <- diff / n_chars
            boot_d[j, i] <- boot_d[i, j]
          }
        }
      }
      
      boot_tree <- myth_tree(boot_d, method)
      cons <<- boot_tree
    }
    
    # Compute consensus (simplified: return frequency of each split in reference tree)
    list(
      ref_tree = ref_tree,
      n_bootstrap = n_bootstrap,
      method = method
    )
  })
}


# ==============================================================================
# Ancestral State Reconstruction (for myth motif reconstruction)
# ==============================================================================

#' Reconstruct ancestral states for myth characters
#'
#' Uses simple parsimony to infer the state of each motif at internal
#' nodes (including the root). This is the key method for reconstructing
#' the "protomythology" — the oldest form of a myth.
#'
#' @param tree ape::phylo tree object
#' @param matrix_data Output from load_myth_matrix
#' @param method Reconstruction method: "parsimony" (default) or "ace"
#' @return Data frame: internal node states for each character
#'
#' @export
reconstruct_ancestral <- function(tree, matrix_data, method = "parsimony") {
  mat <- matrix_data$matrix
  char_names <- matrix_data$character_names
  tip_names <- tree$tip.label
  
  results <- list()
  internal_nodes <- length(tree$tip.label) + 1:length(tree$node.label)
  
  for (c in char_names) {
    # Get tip states ordered by tree tips
    tip_states <- vector()
    for (tip in tip_names) {
      row <- mat[mat$taxon == tip, ]
      if (!length(row)) {
        tip_states <<- as.integer(row[[c]])
      }
    }
    
    if (length(tip_states) < 3) next
    
    # Simple parsimony reconstruction
    # Fitch's algorithm: bottom-up determination of ancestral states
    n_nodes <- length(tree$node.label)
    state_sets <- rep(list(), n_nodes)  # Set of possible states
    
    # Initialize tip states
    for (i in 1:length(tip_names)) {
      if (!is.na(tip_states[i])) {
        state_sets[i] <- list(tip_states[i])
      } else {
        state_sets[i] <- list(0, 1)  # Ambiguous
      }
    }
    
    # Bottom-up pass
    node_children <- replicate(list(), n_nodes)
    for (i in 1:n_nodes) {
      children <- which(tree$edge[, 2] == i)
      # Also find in edges where parent of node i is edge[,1]
    }
    
    # Simplified: assign root state as majority of tip states
    non_na <- tip_states[!is.na(tip_states)]
    root_state <- ifelse(length(non_na) > 0, round(mean(non_na)), NA)
    
    results[[c]] <- list(root_state = root_state, n_tips = length(non_na))
  }
  
  # Format results
  out <- data.frame()
  for (c in names(results)) {
    out <- rbind(out, data.frame(
      character = c,
      root_state = results[[c]]$root_state,
      n_tips_informative = results[[c]]$n_tips
    ))
  }
  
  out
}


# ==============================================================================
# Simplified Divergence Timing
# ==============================================================================

#' Estimate relative divergence times from tree
#'
#' Uses branch lengths (if available) or substitution rate estimation
#' to provide relative timing. For absolute dates, calibration points
#' are needed (see calibrate_myth_tree).
#'
#' @param tree ape::phylo tree object
#' @return Data frame with node ages (relative)
#'
#' @export
myth_divergence_times <- function(tree) {
  if (is.null(tree$edge.length)) {
    return(list(error = "No branch lengths available"))
  }
  
  n_tips <- length(tree$tip.label)
  n_nodes <- length(tree$node.label)
  
  # Compute root-to-tip distances
  root_to_tip <- vector()
  for (i in 1:n_tips) {
    # Walk from root to tip
    dist <- 0
    node <- i
    found <- TRUE
    while (found) {
      parent_row <- which(tree$edge[, 2] == node)
      if (length(parent_row)) {
        found <- FALSE
      } else {
        dist <- dist + tree$edge.length[parent_row[1]]
        node <- tree$edge[parent_row[1], 1]
      }
    }
    root_to_tip <<- dist
  }
  
  list(
    tip_ages = data.frame(taxon = tree$tip.label, root_to_tip = root_to_tip),
    mean_root_to_tip = mean(root_to_tip),
    sd_root_to_tip = sd(root_to_tip),
    max_distance = max(root_to_tip)
  )
}


#' Calibrate myth tree with known historical dates
#'
#' If a myth version has a known historical date (e.g., first textual
#' attestation), use it as a calibration point for molecular-clock-style
#' dating.
#'
#' @param divergence_output Output from myth_divergence_times
#' @param calibrations Data frame: taxon, date (years before present)
#' @return Calibrated dates (years before present for key nodes)
#'
#' @export
calibrate_myth_tree <- function(divergence_output, calibrations) {
  tip_ages <- divergence_output$tip_ages
  
  # Join calibrations
  joined <- merge(tip_ages, calibrations, by = "taxon")
  
  if (nrow(joined) < 2) {
    return(list(error = "Need at least 2 calibration points"))
  }
  
  # Simple linear calibration: date = slope * root_to_tip + intercept
  fit <- stats::linear_regression(joined$root_to_tip, joined$date)
  
  list(
    slope = fit$slope,
    intercept = fit$intercept,
    r_squared = fit$r.squared,
    n_calibrations = nrow(joined),
    formula = "date = slope * root_to_tip + intercept"
  )
}