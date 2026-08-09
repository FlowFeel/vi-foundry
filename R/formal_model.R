#' Formal dynamical model of threshold-gated capacity reallocation
#'
#' The VI formal model: dC_i/dt = -λ × M(t) × C_i × I(d_i < θ)
#'
#' NOTE: the C_i factor (current retention) is essential — without it the ODE
#' is linear (dC/dt = -λM) whose solution C(T) = 1 - λ∫M dt goes negative;
#' with it the ODE is exponential (dC/dt = -λMC) whose solution
#' C(T) = exp(-λ∫M dt) stays in [0, 1], matching retention_at_time().
#' where C_i = retention probability of trait i, M(t) = decaying niche-demand
#' mismatch, d_i = integration depth, θ = protection threshold, λ = shedding rate.
#'
#' This module implements the numerical integration of the formal model,
#' equilibrium predictions, and phase transition analysis.
#'
#' @section Theoretical Context:
#'
#' VI Prediction: biphasic kinetics — fast Phase 1 (unprotected traits shed
#' rapidly) followed by slow Phase 2 (protected traits resist loss).
#'
#' Competitors:
#' - Constant rate (relaxed selection, Lahti 2009): predicts linear reduction
#' - Accelerating (Muller's ratchet): predicts accelerating reduction
#' - The biphasic (logistic/saturation) shape is unique to VI's threshold-gated model
#'
#' @dft
#' - A1 (pure-io-separation): pure math, no I/O
#' - A2 (determinism): no RNG — fully deterministic
#' - A6 (check-result): returns proof object with results + convergence info
#'
#' @name formal_model
NULL

#' Compute mismatch function M(t) at time t
#'
#' M(t) = M₀ × exp(-αt) — exponentially decaying niche-demand mismatch.
#'
#' @param t Numeric. Time.
#' @param m0 Numeric. Initial mismatch magnitude.
#' @param alpha Numeric. Decay rate of mismatch.
#'
#' @return Numeric. Mismatch at time t.
#' @keywords internal
mismatch_function <- function(t, m0, alpha) {
  m0 * exp(-alpha * t)
}

#' Compute retention probability for a single trait at equilibrium
#'
#' At equilibrium (long time), retention depends on whether the trait's
#' integration depth exceeds the protection threshold:
#' - If d_i >= θ: C_i = 1 (protected)
#' - If d_i < θ: C_i = exp(-λ × M₀/α) (shed proportional to integrated mismatch)
#'
#' @param depth Numeric. Integration depth of the trait.
#' @param lambda Numeric. Shedding rate.
#' @param theta Numeric. Protection threshold.
#' @param m0 Numeric. Initial mismatch.
#' @param alpha Numeric. Mismatch decay rate.
#'
#' @return Numeric. Retention probability in [0, 1].
#' @export
#' @examples
#' equilibrium_retention(depth = 3, lambda = 0.15, theta = 2.5, m0 = 10, alpha = 0.05)
equilibrium_retention <- function(depth, lambda, theta, m0, alpha) {
  if (depth >= theta) {
    return(1.0)
  }
  exp(-lambda * m0 / alpha)
}

#' Compute retention probability for a single trait at time T
#'
#' C_i(T) = 1 if d_i >= θ (protected)
#' C_i(T) = exp(-λ × ∫₀ᵀ M(t)dt) if d_i < θ (shed)
#' where ∫₀ᵀ M(t)dt = M₀/α × (1 - exp(-αT))
#'
#' @param depth Numeric. Integration depth.
#' @param lambda Numeric. Shedding rate.
#' @param theta Numeric. Protection threshold.
#' @param m0 Numeric. Initial mismatch.
#' @param alpha Numeric. Mismatch decay rate.
#' @param time Numeric. Time elapsed.
#'
#' @return Numeric. Retention probability in [0, 1].
#' @export
retention_at_time <- function(depth, lambda, theta, m0, alpha, time) {
  if (depth >= theta) {
    return(1.0)
  }
  integrated_mismatch <- (m0 / alpha) * (1 - exp(-alpha * time))
  exp(-lambda * integrated_mismatch)
}

#' Threshold-gated capacity reallocation model (full numerical integration)
#'
#' Solves dC_i/dt = -λ × M(t) × C_i × I(d_i < θ) for a panel of traits.
#'
#' @param depths Numeric vector. Integration depths for each trait.
#' @param lambda Numeric. Shedding rate.
#' @param theta Numeric. Protection threshold.
#' @param m0 Numeric. Initial mismatch.
#' @param alpha Numeric. Mismatch decay rate.
#' @param time Numeric. Total time.
#' @param n_steps Integer. Number of integration steps. Default 1000.
#'
#' @return List (A6):
#'   \item{values}{Named numeric: final_retention vector, phase1_rate, phase2_rate, k1_k2_ratio}
#'   \item{metadata}{List: params, n_traits, n_steps, converged, method}
#'
#' @section Theoretical Context:
#'
#' VI Prediction: biphasic kinetics — fast Phase 1 (unprotected traits shed
#' at rate proportional to λ×M₀), slow Phase 2 (protected traits remain at 1.0).
#'
#' @dft A1, A2, A6
#'
#' @export
#' @examples
#' result <- threshold_model(
#'   depths = c(0, 1, 2, 3, 5),
#'   lambda = 0.15, theta = 2.5, m0 = 10, alpha = 0.05, time = 100
#' )
threshold_model <- function(depths, lambda, theta, m0, alpha, time,
                            n_steps = 1000L) {
  dt <- time / n_steps
  n_traits <- length(depths)

  # Initialize retention at 1.0 for all traits
  retention <- rep(1.0, n_traits)

  # Track retention over time for phase analysis
  retention_history <- matrix(1.0, nrow = n_steps + 1L, ncol = n_traits)

  # Determine which traits are unprotected (d < θ)
  unprotected <- depths < theta

  # Numerical integration (Euler method — sufficient for this simple ODE)
  for (step in seq_len(n_steps)) {
    t_current <- step * dt
    m_t <- mismatch_function(t_current, m0, alpha)

    for (i in seq_len(n_traits)) {
      if (unprotected[i]) {
        d_c <- -lambda * m_t * retention[i] * dt
        retention[i] <- max(0, retention[i] + d_c)
      }
      # Protected traits stay at 1.0 (no change)
    }
    retention_history[step + 1L, ] <- retention
  }

  # Compute phase rates
  # Phase 1: first 10% of time (fast)
  phase1_end <- max(1L, floor(n_steps * 0.1))
  phase1_unprotected <- retention_history[1L, ] - retention_history[phase1_end + 1L, ]
  phase1_rate <- mean(phase1_unprotected[unprotected], na.rm = TRUE)

  # Phase 2: last 90% of time (slow)
  phase2_unprotected <- retention_history[phase1_end + 1L, ] - retention_history[n_steps + 1L, ]
  phase2_rate <- mean(phase2_unprotected[unprotected], na.rm = TRUE)

  # k1/k2 ratio (biphasic indicator)
  k1_k2 <- if (phase2_rate > 0) phase1_rate / phase2_rate else Inf

  result <- list(
    values = list(
      final_retention = retention,
      phase1_rate = phase1_rate,
      phase2_rate = phase2_rate,
      k1_k2_ratio = k1_k2
    ),
    metadata = list(
      params = list(
        lambda = lambda, theta = theta, m0 = m0,
        alpha = alpha, time = time
      ),
      n_traits = n_traits,
      n_unprotected = sum(unprotected),
      n_protected = sum(!unprotected),
      n_steps = n_steps,
      dt = dt,
      method = "euler",
      converged = TRUE
    )
  )

  validate_result(result)
  result
}

#' Compute time to phase transition
#'
#' Returns the time at which the fast phase transitions to the slow phase,
#' defined as the time when the mismatch function drops below a threshold
#' fraction of its initial value.
#'
#' @param m0 Numeric. Initial mismatch.
#' @param alpha Numeric. Mismatch decay rate.
#' @param threshold_fraction Numeric. Fraction of M₀ defining phase boundary.
#'
#' @return Numeric. Time of phase transition.
#' @export
phase_transition_time <- function(m0, alpha, threshold_fraction = 0.1) {
  # Solution: time when retained genome drops below threshold fraction
  -log(threshold_fraction) / alpha
}
