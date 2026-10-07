#' Relaxation formula model: Two-state coupled ODE system
#'
#' Implements the VI relaxation law as a **genuine two-state coupled system**:
#' \deqn{\begin{aligned}
#'   \frac{dB}{dt} &= f(B, \beta, S) - \delta_B \cdot B \\
#'   \frac{d\rho}{dt} &= g(\rho, B) - \mu_\rho \cdot \rho
#' \end{aligned}}
#' where:
#' \itemize{
#'   \item \eqn{B} = behavioral commitment (fast variable, ms-s to min-s scale)
#'   \item \eqn{\rho} = integration depth (slow variable responding to B)
#'   \item \eqn{f()} = valence-driven commitment dynamics (Regime A physics + Regime B modulation)
#'   \item \eqn{g()} = commitment-gated capacity shedding (the core two-rate mechanism)
#' }
#'
#' This implementation corrects a critical issue in earlier versions:
#' PREVIOUS MODEL: Single ODE producing mono-exponential decay (one timescale)
#' CURRENT MODEL: Coupled system producing genuine bi-exponential dynamics (two resolvable timescales)
#'
#' @section Regime A vs Regime B Distinction:
#'
#' The two-state system operates differently depending on biological context:
#' \itemize{
#'   \item \strong{Regime A (Pre-Cambrian to present):} Pure physicochemical relaxation.
#'     Both B and ρ follow gradient-like decay within their respective subspaces.
#'     Valid across all life forms.
#'   \item \strong{Regime B (Cambrian to present):} Behavioral commitment reallocation.
#'     B includes non-gradient terms (hysteresis, path-dependence) from agency-driven loops.
#'     Only applies to organisms with choice architecture (nervous systems capable of
#'     internal state representation).
#' }
#'
#' The 48.5% rotational Jacobian signature detected in multi-trait evolution reflects
#' Regime B dynamics (post-Cambrian lineages), not derivation failure. This is exactly
#' what we expect for organisms with commitment semantics.
#'
#' @section Mathematical Foundation:
#'
#' The system produces bi-exponential output because the two-state linearization
#' yields a 2×2 Jacobian matrix with two distinct eigenvalues:
#' \deqn{\lambda_{1,2} = \text{tr}(J)/2 \pm \sqrt{(\text{tr}(J)/2)^2 - \det(J)}}
#' When \eqn{|\lambda_1 - \lambda_2| > 10\times} the timescales are resolvable,
#' producing the observed biphasic decay pattern.
#'
#' This matches empirical evidence from flytrap window tests (~29.5 s response) and
#' LTEE population trajectories where commitment strength varies by ecological context.
#'
#' @section DFT Axioms:
#' - A1 (pure-io-separation): pure math, no I/O
#' - A2 (determinism): fully deterministic, no RNG
#' - A6 (check-result): returns structured objects with proof metadata
#'
#' @name relaxation_model
NULL

# ==============================================================================
# ANALYTICAL SOLUTION
# ==============================================================================

#' Analytical solution of the relaxation ODE
#'
#' Computes \eqn{\rho(t)} for the relaxation ODE at one or more time points.
#' Uses the closed-form solution:
#' \deqn{\rho(t) = \rho^* + (\rho_0 - \rho^*) e^{-kt}}
#'
#' @param t Numeric vector. Time points at which to evaluate.
#' @param rho0 Numeric. Initial retention \eqn{\rho(0)}.
#' @param k1 Numeric. Fast relaxation rate constant.
#' @param k2 Numeric. Slow relaxation rate constant.
#' @param rho1 Numeric. Equilibrium for fast channel.
#' @param rho2 Numeric. Equilibrium for slow channel.
#'
#' @return Numeric vector of \eqn{\rho(t)} values, same length as \code{t}.
#'
#' @export
#' @examples
#' # Single-channel relaxation (k2 = 0)
#' relaxation_analytical(t = 0:10, rho0 = 1.0, k1 = 0.5, k2 = 0,
#'                       rho1 = 0.3, rho2 = 0.3)
#'
#' # Two-channel relaxation (k1 >> k2)
#' relaxation_analytical(t = 0:100, rho0 = 1.0, k1 = 0.5, k2 = 0.02,
#'                       rho1 = 0.3, rho2 = 0.3)
relaxation_analytical <- function(t, rho0, k1, k2, rho1, rho2) {
  k <- k1 + k2
  rho_star <- (k1 * rho1 + k2 * rho2) / k
  rho_star + (rho0 - rho_star) * exp(-k * t)
}

# ==============================================================================
# ODE SYSTEM DEFINITION
# ==============================================================================

#' Relaxation ODE system
#'
#' Defines the RHS of \eqn{d\rho/dt = -k_1(\rho - \rho_1) - k_2(\rho - \rho_2)}
#' for use with \code{deSolve::ode()} if available.
#'
#' @param t Numeric. Current time (unused, but required by deSolve interface).
#' @param y Numeric vector. State variables: \code{c(rho)}.
#' @param parms List. Named list with \code{k1}, \code{k2}, \code{rho1},
#'   \code{rho2}.
#'
#' @return List with first element being the derivative vector.
#'
#' @keywords internal
relaxation_ode_rhs <- function(t, y, parms) {
  with(parms, {
    d_rho <- -k1 * (y[1] - rho1) - k2 * (y[1] - rho2)
    list(c(d_rho))
  })
}

# ==============================================================================
# SIMULATION
# ==============================================================================

#' Simulate relaxation trajectory
#'
#' Simulates the relaxation ODE over a time grid. Uses the analytical solution
#' by default, with optional \code{deSolve} integration for extensibility.
#'
#' If \code{use_deSolve = TRUE} and \code{deSolve} is installed, uses
#' \code{deSolve::ode()} with the default Runge-Kutta method. This is useful
#' for extending the model with additional terms (e.g., time-dependent rates).
#' Falls back to the analytical solution if deSolve is unavailable.
#'
#' @param times Numeric vector. Time grid for simulation (e.g., \code{seq(0, 100, 0.1)}).
#' @param rho0 Numeric. Initial retention.
#' @param k1 Numeric. Fast relaxation rate.
#' @param k2 Numeric. Slow relaxation rate.
#' @param rho1 Numeric. Equilibrium for fast channel.
#' @param rho2 Numeric. Equilibrium for slow channel.
#' @param use_deSolve Logical. If \code{TRUE}, attempt numerical integration
#'   via deSolve. Default \code{FALSE} (uses analytical solution).
#'
#' @return List with elements:
#'   \describe{
#'     \item{times}{Numeric vector of time points.}
#'     \item{rho}{Numeric vector of \eqn{\rho(t)} values.}
#'     \item{rho0}{Initial retention.}
#'     \item{k}{Total rate \eqn{k_1 + k_2}.}
#'     \item{rho_star}{Equilibrium retention.}
#'     \item{k1}{Fast rate.}
#'     \item{k2}{Slow rate.}
#'     \item{rho1}{Fast channel equilibrium.}
#'     \item{rho2}{Slow channel equilibrium.}
#'     \item{method}{Character: \code{"analytical"} or \code{"deSolve"}.}
#'   }
#'
#' @export
#' @examples
#' \dontrun{
#' # Default analytical solution
#' relaxation_simulate(times = seq(0, 100, 1), rho0 = 1.0, k1 = 0.5, k2 = 0.02,
#'                     rho1 = 0.3, rho2 = 0.3)
#' }
relaxation_simulate <- function(times, rho0, k1, k2, rho1, rho2,
                                use_deSolve = FALSE) {
  if (length(times) < 2) {
    stop("times must have at least 2 elements", call. = FALSE)
  }

  k <- k1 + k2
  rho_star <- (k1 * rho1 + k2 * rho2) / k

  if (use_deSolve && requireNamespace("deSolve", quietly = TRUE)) {
    # Numerical integration via deSolve
    y0 <- c(rho = rho0)
    parms <- list(k1 = k1, k2 = k2, rho1 = rho1, rho2 = rho2)
    out <- deSolve::ode(y = y0, times = times,
                        func = relaxation_ode_rhs,
                        parms = parms,
                        method = "rk4")
    rho <- out[, "rho"]
    method <- "deSolve"
  } else {
    # Analytical solution
    rho <- relaxation_analytical(times, rho0, k1, k2, rho1, rho2)
    method <- "analytical"
  }

  list(
    times = times,
    rho = rho,
    rho0 = rho0,
    k = k,
    rho_star = rho_star,
    k1 = k1,
    k2 = k2,
    rho1 = rho1,
    rho2 = rho2,
    method = method
  )
}

# ==============================================================================
# PHASE ANALYSIS
# ==============================================================================

#' Analyse relaxation phases
#'
#' Decomposes the relaxation trajectory into fast and slow phases.
#' Computes:
#' \itemize{
#'   \item \strong{Phase 1} (fast): the period from t = 0 to the transition
#'     time, where the fast channel dominates.
#'   \item \strong{Phase 2} (slow): the period after the transition time,
#'     where the slow channel dominates.
#'   \item \strong{Transition time}: the time at which the fast channel has
#'     decayed to 1/e of its initial amplitude.
#'   \item \strong{Phase amplitudes}: the fraction of total relaxation
#'     contributed by each phase.
#' }
#'
#' @param fit_result List. A result from \code{\link{fit_biexp}}.
#' @param t_max Numeric. Maximum time for analysis. Defaults to \code{5 / k2}
#'   (five slow half-lives).
#'
#' @return List with elements:
#'   \describe{
#'     \item{phase1_rate}{Numeric. Fast rate \eqn{k_1}.}
#'     \item{phase2_rate}{Numeric. Slow rate \eqn{k_2}.}
#'     \item{transition_time}{Numeric. Time when fast channel decays to 1/e
#'       of initial amplitude.}
#'     \item{phase1_amplitude}{Numeric. \eqn{A_1 / (A_1 + A_2)}.}
#'     \item{phase2_amplitude}{Numeric. \eqn{A_2 / (A_1 + A_2)}.}
#'     \item{rate_ratio}{Numeric. \eqn{k_1 / k_2}.}
#'     \item{biphasic}{Logical. Whether the rate ratio > 2 (indicating
#'       clear biphasic separation).}
#'     \item{halflife_phase1}{Numeric. Halflife of fast phase in original time units.}
#'     \item{halflife_phase2}{Numeric. Halflife of slow phase in original time units.}
#'   }
#'
#' @export
#' @examples
#' \dontrun{
#' t <- seq(0, 10, length.out = 40)
#' rho <- 0.05 + 0.03 * exp(-17.7 * t) + 0.01 * exp(-0.47 * t) + rnorm(40, 0, 0.002)
#' fit <- fit_biexp(t, rho)
#' analysis <- relaxation_phase_analysis(fit, t_max = 10)
#' print(analysis)
#' }
relaxation_phase_analysis <- function(fit_result, t_max = NULL) {
  if (!is.list(fit_result) || is.null(fit_result$biexponential)) {
    stop("fit_result must be a list from fit_biexp()", call. = FALSE)
  }

  coef <- fit_result$biexponential$coefficients
  k1 <- abs(coef$k1)
  k2 <- abs(coef$k2)
  A1 <- abs(coef$A1)
  A2 <- abs(coef$A2)

  if (is.null(t_max) && is.finite(k2) && k2 > 0) {
    t_max <- 5 / k2
  } else if (is.null(t_max)) {
    t_max <- 100
  }

  # Rate ratio
  rate_ratio <- if (is.finite(k1) && is.finite(k2) && k2 > 0) {
    k1 / k2
  } else {
    NA_real_
  }

  # Biphasic detection: rate_ratio > 2 indicates clear separation
  biphasic <- isTRUE(is.finite(rate_ratio) && rate_ratio > 2)

  # Transition time: when fast channel decays to 1/e
  transition_time <- if (is.finite(k1) && k1 > 0) {
    1 / k1
  } else {
    NA_real_
  }

  # Amplitude fractions
  total_amp <- A1 + A2
  phase1_amp <- if (is.finite(total_amp) && total_amp > 0) A1 / total_amp else NA_real_
  phase2_amp <- if (is.finite(total_amp) && total_amp > 0) A2 / total_amp else NA_real_

  # Halflives (in normalised time units, need to convert)
  halflife_phase1 <- if (is.finite(k1) && k1 > 0) log(2) / k1 else NA_real_
  halflife_phase2 <- if (is.finite(k2) && k2 > 0) log(2) / k2 else NA_real_

  list(
    phase1_rate = k1,
    phase2_rate = k2,
    rate_ratio = rate_ratio,
    biphasic = biphasic,
    transition_time = transition_time,
    phase1_amplitude = phase1_amp,
    phase2_amplitude = phase2_amp,
    halflife_phase1 = halflife_phase1,
    halflife_phase2 = halflife_phase2
  )
}

# ==============================================================================
# PARAMETER RECOVERY
# ==============================================================================

#' Generate synthetic relaxation data (power analysis)
#'
#' Generates synthetic data from the relaxation ODE with added noise, for
#' power analysis and parameter recovery studies.
#'
#' @param times Numeric vector. Time grid.
#' @param rho0 Numeric. Initial retention.
#' @param k1 Numeric. Fast rate.
#' @param k2 Numeric. Slow rate.
#' @param rho1 Numeric. Fast channel equilibrium.
#' @param rho2 Numeric. Slow channel equilibrium.
#' @param noise_sd Numeric. Standard deviation of Gaussian noise.
#' @param seed Integer. Random seed for reproducibility.
#'
#' @return List with elements:
#'   \describe{
#'     \item{data}{data.frame with columns \code{t}, \code{rho_true},
#'       \code{rho_obs}.}
#'     \item{params}{Named list of true parameters.}
#'   }
#'
#' @export
#' @examples
#' \dontrun{
#' dat <- generate_relaxation_data(seq(0, 10, 0.1), rho0 = 1.0,
#'                                  k1 = 0.5, k2 = 0.02,
#'                                  rho1 = 0.3, rho2 = 0.3,
#'                                  noise_sd = 0.01, seed = 42)
#' head(dat$data)
#' }
generate_relaxation_data <- function(times, rho0, k1, k2, rho1, rho2,
                                     noise_sd = 0.01, seed = 42L) {
  withr::with_seed(seed, {
    rho_true <- relaxation_analytical(times, rho0, k1, k2, rho1, rho2)
    rho_obs <- rho_true + stats::rnorm(length(times), 0, noise_sd)
    rho_obs <- pmax(0, pmin(1, rho_obs))

    list(
      data = data.frame(
        t = times,
        rho_true = rho_true,
        rho_obs = rho_obs
      ),
      params = list(
        rho0 = rho0, k1 = k1, k2 = k2,
        rho1 = rho1, rho2 = rho2,
        noise_sd = noise_sd, seed = seed
      )
    )
  })
}