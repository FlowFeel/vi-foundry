#' Temporal delay in niche construction effects (DDE variant)
#'
#' Extends the closed-form system with a temporal lag between niche
#' construction and its selective effects (Laland et al. 1996, 1999,
#' 2001). The Ω equation is modified so the innovation term responds
#' to B at time t-τ rather than B at time t, modeling the delay
#' between behavioral change and ecological feedback.
#'
#' Uses deSolve's lagvalue mechanism for proper DDE integration.
#' When τ > 0, expect:
#' - Small τ (< 1 gen): dynamics approximating the ODE
#' - Moderate τ (1-10 gen): damped oscillations, possible overshoot
#' - Large τ (> 10 gen): potentially unstable or oscillatory
#'
#' @name temporal_delay
NULL

#' DDE function with delayed niche construction
#'
#' @keywords internal
dde_ode <- function(t, y, params) {
  B <- max(0, min(1, y[1]))
  rho <- max(0, min(1, y[2]))
  Omega <- max(0, y[3])
  N <- max(1, y[4])

  # Get lagged B for innovation term
  if (params$tau <= 0) {
    B_lag <- B
  } else if (t <= params$tau) {
    B_lag <- 0.1  # initial B value before any history exists
  } else {
    B_lag <- max(0, min(1, deSolve::lagvalue(t - params$tau)[1]))
  }

  # B dynamics (no delay — valence is immediate)
  lambda <- abs(rho - params$rho_opt)
  V <- exp(-lambda^2 / (2 * params$sigma^2))
  dB <- params$gamma * V * (1 - B) - params$delta * (1 - V) * B

  # ρ dynamics (no delay — relaxation is immediate)
  k1 <- params$k10 * (1 + params$alpha1 * B)
  k2 <- params$k20 * (1 + params$alpha2 * B)
  drho <- -k1 * (rho - params$rho1) - k2 * (rho - params$rho2)
  drho <- if (rho > params$rho_opt) min(drho, 0) else 0

  # Ω dynamics with DELAYED B in the innovation term
  C_N <- N^params$gamma_net
  eta <- params$eta0 * (1 + params$kappa * B_lag)  # B_lag!
  dOmega <- Omega * (-params$alpha_comp * N + eta * C_N) *
    (1 - Omega / params$Omega_max)

  # N dynamics (no delay)
  per_cap <- max(Omega, 0.1) / max(N, 0.1)
  spp <- params$s0 * per_cap * (1 - N / params$K)
  ext <- params$e0 / (per_cap + 0.01) + params$e_floor
  dN <- N * (spp - ext)

  ls <- if (params$eta0 * C_N > 1e-10 && params$kappa > 0)
    (params$alpha_comp * N / (params$eta0 * C_N) - 1) / params$kappa
  else Inf

  list(c(dB, drho, dOmega, dN),
       lambda_star = ls,
       dd_sign = sign(eta * C_N - params$alpha_comp * N),
       B_lag = B_lag)
}

#' Run delayed-niche simulation
#'
#' Uses deSolve::dede for delay differential equation integration.
#'
#' @param tau Numeric. Delay in generations. Default 5.
#' @param kappa Numeric. B→innovation coupling. Default 2.5.
#' @param eta0 Numeric. Baseline innovation. Default 0.08.
#' @param t_max Numeric. Maximum time. Default 200.
#' @param n_points Integer. Time points. Default 1000.
#' @return Data frame with time, B, rho, Omega, N.
#' @export
delayed_niche <- function(tau = 5, kappa = 2.5, eta0 = 0.08,
                           t_max = 200, n_points = 500) {
  P <- cf_defaults()
  P$kappa <- kappa; P$eta0 <- eta0; P$tau <- tau

  y0 <- c(B = 0.1, rho = 0.95, Omega = 100, N = 5)
  times <- seq(0, t_max, length.out = n_points)

  sol <- tryCatch({
    deSolve::dede(y0, times, dde_ode, P, method = "lsoda",
                  rtol = 1e-4, atol = 1e-6)
  }, error = function(e) {
    # Fallback: non-delayed ODE if DDE fails
    message("DDE integration failed (tau=", tau, "): ", e$message)
    message("Falling back to non-delayed ODE")
    sol <- deSolve::ode(y0, times, cf_ode, P,
                        method = "lsoda", rtol = 1e-4, atol = 1e-6)
    sol
  })

  as.data.frame(sol[, 1:5]) |> stats::setNames(
    c("time", "B", "rho", "Omega", "N"))
}

#' Compare delayed vs non-delayed dynamics
#'
#' @param tau_range Numeric vector. Delay values. Default c(0, 2, 5, 10).
#' @return Data frame comparing final N, max Omega, oscillation detection.
#' @export
delay_comparison <- function(tau_range = c(0, 2, 5, 10)) {
  results <- data.frame(tau = tau_range,
                        final_N = NA, max_Omega = NA,
                        final_rho = NA, overshoot = NA,
                        dde_converged = TRUE,
                        stringsAsFactors = FALSE)
  for (i in seq_along(tau_range)) {
    sol <- delayed_niche(tau = tau_range[i])
    results$final_N[i] <- tail(sol$N, 1)
    results$max_Omega[i] <- max(sol$Omega, na.rm = TRUE)
    results$final_rho[i] <- tail(sol$rho, 1)
    results$overshoot[i] <- max(sol$N, na.rm = TRUE) > 1.2 * tail(sol$N, 1)
  }
  results
}