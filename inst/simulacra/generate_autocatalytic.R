# generate_autocatalytic.R — Simulacrum 4: Autocatalytic Set
#
# Generates synthetic innovation time series with KNOWN autocatalytic closure.
# Logistic growth model: innovation rate increases with diversity (positive
# diversity-dependence), producing a superlinear growth trajectory that
# approaches carrying capacity.
#
# @section Theoretical Context:
#
# VI Prediction: after substrate shift, innovations generate further innovations
# faster than they are lost — positive diversity-dependence producing superlinear
# growth. Competitor: standard niche-filling predicts negatively
# diversity-dependent (logistic) growth from the start.
#
# This simulacrum generates data with KNOWN autocatalytic closure properties
# for testing parameter recovery of autocatalytic_closure() and
# diversity_dependence_sign().
#
# @section Parameters:
# - n_steps: Number of time steps (default 20)
# - innovation_rate: Base rate of innovation generation (default 0.3)
# - capacity: Carrying capacity / maximum innovation count (default 100)
# - closure_threshold: Minimum fraction of innovations that must be catalyzed
#   for closure (default 0.5)
# - n_innovations: Number of innovations for catalyst matrix (default 10)
# - seed: RNG seed for reproducibility (default 42L)
#
# @return List (A6): values (innovation_counts, achieves_closure,
#   closure_fraction, catalyst_matrix, innovations), metadata
#   (params, seed, converged)
#
# @dft A1, A2, A6
#
# @examples
# \dontrun{
# }
#
# @export
generate_autocatalytic_set <- function(n_steps = 20,
                                       innovation_rate = 0.3,
                                       capacity = 100,
                                       closure_threshold = 0.5,
                                       n_innovations = 10,
                                       seed = 42L) {
  withr::with_seed(seed, {
    # --- Generate innovation time series via logistic growth ---
    # count_t = count_{t-1} + rate * count_{t-1} * (1 - count_{t-1} / capacity)
    counts <- numeric(n_steps)
    counts[1] <- 1 # Start with one innovation

    for (t in 2:n_steps) {
      growth <- innovation_rate * counts[t - 1] * (1 - counts[t - 1] / capacity)
      counts[t] <- counts[t - 1] + growth
      # Ensure non-negative
      counts[t] <- max(0, counts[t])
    }

    # --- Generate catalyst matrix with known closure ---
    # Create n_innovations x n_innovations matrix where most innovations
    # catalyze at least one other (closure achieved)
    innovations <- sprintf("I%02d", seq_len(n_innovations))

    # Random matrix with ~60% catalysis probability
    catalyst_matrix <- matrix(
      stats::runif(n_innovations^2) < 0.6,
      nrow = n_innovations,
      ncol = n_innovations
    )

    # No self-catalysis
    diag(catalyst_matrix) <- FALSE

    # Ensure each innovation is catalyzed by at least one other
    # (enforce closure)
    for (j in seq_len(n_innovations)) {
      if (!any(catalyst_matrix[, j])) {
        rows <- setdiff(seq_len(n_innovations), j)
        catalyst_matrix[sample(rows, 1L), j] <- TRUE
      }
    }

    # Check closure
    n_catalyzed <- sum(apply(catalyst_matrix, 2L, any))
    achieves_closure <- n_catalyzed == n_innovations
    closure_fraction <- n_catalyzed / n_innovations

    result <- list(
      values = list(
        innovation_counts = counts,
        catalyst_matrix = catalyst_matrix,
        innovations = innovations,
        n_steps = n_steps,
        achieves_closure = achieves_closure,
        closure_fraction = closure_fraction,
        n_catalyzed = n_catalyzed,
        n_total = n_innovations
      ),
      metadata = list(
        seed = seed,
        n = n_steps,
        innovation_rate = innovation_rate,
        capacity = capacity,
        closure_threshold = closure_threshold,
        n_innovations = n_innovations,
        model = "logistic_growth",
        converged = TRUE
      )
    )

    validate_result(result)
    result
  })
}
