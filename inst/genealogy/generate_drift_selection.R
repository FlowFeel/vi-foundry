#' Drift-Selection Boundary Simulation — Stage 5
#'
#' Wright-Fisher model: trait with selective advantage delta
#' in population of size N. Measures retention probability
#' and rho_sat = P(retain|delta>0) - P(retain|delta=0).
#'
#' @param seed Integer. Default 42.
#' @param N Integer. Population size. Default 100.
#' @param n_reps Integer. Replicates per delta. Default 1000.
#' @param n_delta Integer. Number of delta values. Default 20.
#' @param delta_range Numeric. Default c(0, 0.1).
#'
#' @return List with data frame: delta, retention_prob, N, stage

generate_drift_selection <- function(seed = 42L, N = 100L, n_reps = 1000L,
                                     n_delta = 20L,
                                     delta_range = c(0, 0.1)) {
  withr::with_seed(seed, {
    deltas <- seq(delta_range[1], delta_range[2], length.out = n_delta)
    retention_probs <- numeric(n_delta)

    for (d_idx in 1:n_delta) {
      delta <- deltas[d_idx]
      retained <- 0

      for (rep in 1:n_reps) {
        p <- 0.5
        for (gen in 1:100) {
          if (delta > 0) {
            p_sel <- p * (1 + delta) / (p * (1 + delta) + (1 - p))
          } else {
            p_sel <- p
          }
          p <- rbinom(1, 2 * N, p_sel) / (2 * N)
          if (p == 0 || p == 1) break
        }
        if (p == 1) retained <- retained + 1
      }
      retention_probs[d_idx] <- retained / n_reps
    }

    rho_sat <- retention_probs[n_delta] - retention_probs[1]

    data <- data.frame(
      delta = deltas, retention_prob = retention_probs,
      N = N, stage = "drift_selection"
    )

    list(
      values = list(n_reps = n_reps, N = N, rho_sat = rho_sat),
      metadata = list(
        seed = seed, data = data,
        params = list(N = N, n_reps = n_reps, n_delta = n_delta,
                      delta_range = delta_range),
        generator = "generate_drift_selection", converged = TRUE
      )
    )
  })
}
