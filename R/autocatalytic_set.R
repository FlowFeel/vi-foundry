#' Autocatalytic set dynamics for post-substrate-shift regime
#'
#' After the substrate shift, VI predicts that innovations generate further
#' innovations faster than they are lost — positive diversity-dependence.
#' This is modeled via autocatalytic set theory (Kauffman style).
#'
#' @section Theoretical Context:
#'
#' VI Prediction: positive diversity-dependence in cultural substrate —
#' the Homo inversion (positively diversity-dependent speciation) is the
#' empirical signature. Competitor: standard niche-filling predicts
#' negatively diversity-dependent (logistic) growth.
#'
#' @dft A1, A2, A6
#'
#' @name autocatalytic_set
NULL

#' Check if an innovation set achieves autocatalytic closure
#'
#' An autocatalytic set is one where each innovation is catalyzed by at
#' least one other innovation in the set. Closure means the set is
#' self-sustaining.
#'
#' @param innovations Character vector. Names of innovations.
#' @param catalyst_matrix Logical matrix (n × n). catalyst_matrix[i,j] = TRUE
#'   if innovation i catalyzes innovation j.
#'
#' @return List (A6): values (achieves_closure, n_catalyzed, n_total), metadata.
#'
#' @dft A1, A6
#'
#' @export
autocatalytic_closure <- function(innovations, catalyst_matrix) {
  n <- length(innovations)

  if (!is.matrix(catalyst_matrix) || nrow(catalyst_matrix) != n ||
        ncol(catalyst_matrix) != n) {
    stop("catalyst_matrix must be n×n matching innovations length", call. = FALSE)
  }

  # Each innovation must be catalyzed by at least one other
  catalyzed_by <- apply(catalyst_matrix, 2, function(col) which(col))

  n_catalyzed <- sum(sapply(catalyzed_by, length) > 0)
  achieves_closure <- n_catalyzed == n

  result <- list(
    values = c(
      achieves_closure = achieves_closure,
      n_catalyzed = n_catalyzed,
      n_total = n,
      closure_fraction = n_catalyzed / n
    ),
    metadata = list(
      n = n,
      innovations = innovations,
      converged = TRUE
    )
  )

  validate_result(result)
  result
}

#' Compute diversity-dependence sign
#'
#' For a time series of innovation counts, determine whether diversity
#' is increasing (positive dependence) or decreasing (negative dependence).
#'
#' @param innovation_counts Numeric vector. Innovation counts over time.
#' @param seed Integer. Seed for reproducibility.
#'
#' @return List (A6): values (sign, slope, r_squared), metadata.
#'
#' @dft A1, A2, A6
#'
#' @export
diversity_dependence_sign <- function(innovation_counts, seed = 42L) {
  withr::with_seed(seed, {
    n <- length(innovation_counts)
    time <- seq_len(n)

    # Fit linear model: innovations ~ time
    # Positive slope = increasing diversity (positive dependence)
    # Negative slope = decreasing diversity (negative dependence)
    mod <- lm(innovation_counts ~ time)
    slope <- coef(mod)[2]
    r2 <- summary(mod)$r.squared

    # Test for superlinear (autocatalytic) dynamics
    # Log-log regression of innovations against time
    # Slope greater than 1 indicates superlinear dynamics
    log_mod <- lm(log(pmax(innovation_counts, 1)) ~ log(time))
    log_slope <- coef(log_mod)[2]

    result <- list(
      values = c(
        sign = ifelse(slope > 0, "positive", "negative"),
        slope = slope,
        r_squared = r2,
        log_log_slope = log_slope,
        is_superlinear = log_slope > 1.0
      ),
      metadata = list(
        seed = seed,
        n = n,
        time_range = range(time),
        converged = TRUE
      )
    )

    validate_result(result)
    result
  })
}
