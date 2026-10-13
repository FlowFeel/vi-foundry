#' Diachenko & Gronenborn 2026 — assemblage diversity model & empirical tests
#'
#' Implements the mathematical model from:
#'   Diachenko A, Gronenborn D (2026) Social dynamics signals in archaeological
#'   time-series. PLoS One 21(10): e0358135. doi:10.1371/journal.pone.0358135
#'
#' Equations follow the paper's numbering:
#'   Eq 2  — Shannon diversity: D = exp(−Σ p_i ln p_i)
#'   Eq 4  — proportion update with production bias k
#'   Eq 6  — stability-causing replication threshold r_stab
#'   Eq 7  — maximal proportion of the primary unit
#'
#' Empirical series: Fig 7 (LBK 5400–5000 BCE) and Fig 10 (WTC 4100–3600 BCE).
#' Data: data/diachenko-gronenborn-2026/ (S1 Table, one CSV per figure).
#'
#' @name assemblage_diversity
NULL

# =============================================================================
# Eq 2 — Shannon diversity
# =============================================================================

#' Shannon diversity (Eq 2)
#'
#' D = exp(−Σ p_i ln p_i). Natural log. Returns the number of "effective" types.
#'
#' @param p Numeric vector of proportions (≥0, need not sum to 1; zeros contribute 0).
#' @return Numeric diversity ≥ 1.
#' @export
dg_diversity <- function(p) {
  p <- p[p > 0]
  if (length(p) == 0) return(1.0)
  exp(-sum(p * log(p)))
}

# =============================================================================
# Eq 6 — stability threshold
# =============================================================================

#' Stability-causing replication threshold (Eq 6)
#'
#' r_stab = k·C / (C − p/k). The replication rate at which a primary unit's
#' proportion remains unchanged between t and t+1.
#'
#' @param p Proportion of the primary unit (0 < p < C).
#' @param k Production-bias parameter (0 < k ≤ 2).
#' @param C Maximal proportion of the primary unit (default 1).
#' @return Replication rate.
#' @export
dg_stability_threshold <- function(p, k, C = 1) {
  stopifnot(p > 0, k > 0, k <= 2, C > 0, p < C)
  k * C / (C - p / k)
}

# =============================================================================
# Eq 7 — maximal proportion of the primary unit
# =============================================================================

#' Maximal stable proportion of the primary unit (Eq 7)
#'
#' p_max = k·C − k²·C / r_stab. Framing threshold: above p_max, diversity must
#' decline then increase (rise-and-fall).
#'
#' @param k Production-bias parameter (0 < k ≤ 2).
#' @param C Maximal proportion of the primary unit (default 1).
#' @param r_stab Stability threshold (Eq 6); defaults to 4, the model maximum.
#' @return Maximal stable proportion.
#' @export
dg_max_proportion <- function(k, C = 1, r_stab = 4) {
  stopifnot(k > 0, k <= 2, C > 0, r_stab > 0)
  k * C - (k^2 * C) / r_stab
}

# =============================================================================
# Eq 4 — proportion update
# =============================================================================

#' Update assemblage proportions one time step (Eq 4)
#'
#' Per-unit unnormalized next proportion: (1/k)·p_i·r_i·C·(C − p_i/k).
#' Innovations (p_gamma) are added raw, then the whole set is renormalized to
#' sum 1. Matches the paper's Fig 4 worked example (A: 0.8→0.714, B/C: 0.1→0.143
#' with k=1.1, r_α=3.6, r_n=1.73).
#'
#' @param p Named numeric vector of current proportions.
#' @param r Named numeric vector of replication rates (same names as p).
#' @param k Production-bias parameter (0 < k ≤ 2).
#' @param C Maximal proportion of the primary unit (default 1).
#' @param innovations Named numeric vector of new-type proportions to introduce
#'   (default none).
#' @return Numeric vector of next-step proportions, sum 1.
#' @export
dg_update <- function(p, r, k, C = 1, innovations = NULL) {
  stopifnot(length(p) == length(r), !is.null(names(p)), !is.null(names(r)))
  stopifnot(all(names(p) %in% names(r)), k > 0, k <= 2, C > 0)
  raw <- (1 / k) * p * r * C * (C - p / k)
  if (!is.null(innovations)) {
    raw <- c(raw, innovations)
  }
  raw <- pmax(raw, 0)
  s <- sum(raw)
  if (s <= 0) stop("update produced non-positive total; model singularity", call. = FALSE)
  raw / s
}

# =============================================================================
# Scenario simulators (Figs 6, 8, 9)
# =============================================================================

#' Run an assemblage-diversity cycle simulation
#'
#' Iterates Eq 4 over `n_steps` with a production trajectory `k_t` (length
#' n_steps or 1 recycled), optional pro-novelty bias schedule, and optional
#' innovation packages at specified steps. Returns a data.frame with time,
#' per-type proportions, entropy, and Shannon diversity.
#'
#' @param p0 Named numeric initial proportions.
#' @param r_base Named numeric replication rates for the primary unit; secondary
#'   rates are computed proportionally per Eq 5 convention (see paper).
#' @param k_t Production trajectory (vector length n_steps).
#' @param C Maximal proportion of the primary unit.
#' @param novel_bias Named list of per-step replication-rate boosts applied to
#'   named types (e.g., list("B" = function(t) ...)).
#' @param innovations List of named vectors; names are the step (1-based) at
#'   which the package is introduced.
#' @return data.frame with columns time, type..., entropy, diversity.
#' @export
dg_simulate_cycle <- function(p0, r_base, k_t, C = 1,
                              novel_bias = NULL, innovations = NULL) {
  n_steps <- length(k_t)
  types <- names(p0)
  r <- r_base
  p <- p0
  out <- vector("list", n_steps)
  for (t in seq_len(n_steps)) {
    # Record state at time t BEFORE updating (so row 1 == p0, matching S1
    # Fig 6 where t1 is the initial assemblage).
    ent <- -sum(p * log(p))
    out[[t]] <- c(time = t, p, entropy = ent, diversity = exp(ent))
    k <- k_t[[t]]
    # Apply per-step novelty bias to replication rates
    if (!is.null(novel_bias) && t %in% names(novel_bias)) {
      boost <- novel_bias[[as.character(t)]]
      r[names(boost)] <- r[names(boost)] * boost
    }
    innov <- NULL
    if (!is.null(innovations) && as.character(t) %in% names(innovations)) {
      innov <- innovations[[as.character(t)]]
    }
    p_new <- dg_update(p, r, k, C, innovations = innov)
    # Re-introduce any new types from innovations into the type registry
    new_types <- setdiff(names(p_new), types)
    types <- c(types, new_types)
    p <- p_new
  }
  as.data.frame(do.call(rbind, out))
}

# =============================================================================
# Empirical tests — LBK (Fig 7) and WTC (Fig 10)
# =============================================================================

#' Load a Diachenko & Gronenborn S1 empirical sheet
#'
#' @param which "fig7" (LBK) or "fig10" (WTC).
#' @return data.frame from the CSV, or NULL if the bundled data is absent.
#' @export
dg_load_empirical <- function(which = c("fig7", "fig10")) {
  which <- match.arg(which)
  path <- file.path("data", "diachenko-gronenborn-2026", paste0(which, ".csv"))
  if (!file.exists(path)) return(NULL)
  utils::read.csv(path, check.names = FALSE, stringsAsFactors = FALSE)
}

# {{LBK lead-lag test}}
#'
#' Computes Spearman correlation between diversity and population at lags
#' 0..max_lag (diversity leading), with permutation significance. The paper's
#' Fig 7 shows band-type diversity peaking ~5150 BCE vs population peak ~5065 —
#' a lead of roughly one time step.
#'
#' @param lag_max Maximum lead lag to test (default 3 time steps).
#' @param n_perm Number of permutations for the null (default 9999).
#' @param seed RNG seed (A2).
#' @return List (A6): values (best_lag, rho_at_best_lag, perm_p), metadata.
#' @export
dg_lbk_lead_lag <- function(lag_max = 3, n_perm = 9999, seed = 42L) {
  dat <- dg_load_empirical("fig7")
  if (is.null(dat)) stop("LBK data not bundled", call. = FALSE)
  diversity <- as.numeric(dat[[4]]) # Diversity (band types)
  population <- as.numeric(dat[[2]])
  n <- length(diversity)
  withr::with_seed(seed, {
    best <- NULL
    for (lag in 0:min(lag_max, n - 2)) {
      if (lag == 0) {
        x <- diversity; y <- population
      } else {
        x <- diversity[1:(n - lag)]
        y <- population[(1 + lag):n]
      }
      rho <- suppressWarnings(cor(x, y, method = "spearman"))
      if (is.null(best) || abs(rho) > abs(best$rho)) {
        best <- list(lag = lag, rho = rho)
      }
    }
    # Permutation null at the best lag: shuffle diversity, recompute rho
    lag <- best$lag
    if (lag == 0) {
      x <- diversity; y <- population
    } else {
      x <- diversity[1:(n - lag)]
      y <- population[(1 + lag):n]
    }
    obs <- suppressWarnings(cor(x, y, method = "spearman"))
    perm <- vapply(seq_len(n_perm), function(i) {
      suppressWarnings(cor(sample(x), y, method = "spearman"))
    }, numeric(1))
    p <- (sum(abs(perm) >= abs(obs)) + 1) / (n_perm + 1)
    list(
      values = c(
        best_lag = best$lag, rho_at_best_lag = best$rho,
        rho = obs, perm_p = p, n = length(x)
      ),
      metadata = list(seed = seed, n_perm = n_perm, method = "spearman_permutation")
    )
  })
}

#' WTC standardization test: does decoration-class richness fall as population rises?
#'
#' The paper's Fig 10 shows decoration-class richness declining 6→1 while the
#' population proxy rises across 3900–3600 BCE (production bias →
#' standardization). Tests negative Spearman correlation with permutation
#' significance.
#'
#' @param n_perm Number of permutations (default 9999).
#' @param seed RNG seed (A2).
#' @return List (A6): values (rho, perm_p, n), metadata.
#' @export
dg_wtc_standardization <- function(n_perm = 9999, seed = 42L) {
  dat <- dg_load_empirical("fig10")
  if (is.null(dat)) stop("WTC data not bundled", call. = FALSE)
  population <- as.numeric(dat[[2]])
  richness <- as.numeric(dat[[4]])
  ok <- !is.na(population) & !is.na(richness)
  population <- population[ok]
  richness <- richness[ok]
  withr::with_seed(seed, {
    obs <- suppressWarnings(cor(richness, population, method = "spearman"))
    perm <- vapply(seq_len(n_perm), function(i) {
      suppressWarnings(cor(sample(richness), population, method = "spearman"))
    }, numeric(1))
    p <- (sum(abs(perm) >= abs(obs)) + 1) / (n_perm + 1)
    list(
      values = c(rho = obs, perm_p = p, n = length(richness)),
      metadata = list(seed = seed, n_perm = n_perm, method = "spearman_permutation")
    )
  })
}