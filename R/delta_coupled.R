#' δ-coupled distributed-capacity model
#'
#' Extends the bulk-ρ model by distributing capacity across δ bins,
#' each with a different relaxation rate determined by bioelectric
#' cascade depth. Shallower δ → faster relaxation → more capacity loss.
#' Deeper δ → slower relaxation → capacity persistence.
#'
#' @section Cross-scale coupling chain:
#' V_mem(t) = V₀ + V₁·B(t) → f(δ_i) = 1/(1+β·δ_i) → k_i = k_base·f(δ_i)·(1+0.5·B)
#' 
#' β is the universal shielding coefficient, measurable in zebrafish
#' via optogenetic V_mem perturbation → phosphoproteomics → trait change rate.
#'
#' @section Startup fragility:
#' The δ-coupled model reveals a fragility absent from the bulk-ρ model:
#' at low N₀, Ω is consumed during ρ decline before innovation ramps up.
#' This predicts a minimum effective population size for cultural take-off,
#' consistent with Henrich (2004) and Powell et al. (2009).
#'
#' @name delta_coupled
NULL

# =========================================================================
# δ-coupled ODE
# =========================================================================

#' Internal ODE function for the δ-coupled system
#' @keywords internal
delta_ode <- function(t, state, params) {
  B <- max(0, min(1, state[1]))
  M <- params$n_bins
  rhos <- state[2:(1+M)]
  N <- max(1, state[2+M])
  Omega <- max(0, state[3+M])

  # Ensemble mean capacity (weighted)
  rho <- sum(params$weights * rhos) / sum(params$weights)
  rho <- max(0, min(1, rho))

  # B dynamics (via ensemble ρ — same valence function)
  lambda_v <- abs(rho - params$rho_opt)
  V <- exp(-lambda_v^2 / (2 * params$sigma^2))
  dB <- params$gamma * V * (1 - B) - params$delta_rate * (1 - V) * B

  # Per-bin ρ dynamics: rate depends on δ via f(δ) = 1/(1+β·δ)
  drhos <- numeric(M)
  for (i in 1:M) {
    di <- params$deltas[i]
    f_d <- 1 / (1 + params$beta * di)
    k_i <- params$k10_scaled * f_d * (1 + 0.5 * B)
    drhos[i] <- -k_i * (rhos[i] - params$rho_eq[i])
    if (rhos[i] > params$rho_eq[i]) drhos[i] <- min(drhos[i], 0)
  }

  # Ω dynamics (same as closed-form)
  C_N <- N^params$gamma_net
  eta <- params$eta0 * (1 + params$kappa * B)
  dOmega <- Omega * (-params$alpha_comp * N + eta * C_N) *
    (1 - Omega / params$Omega_max)

  # N dynamics (same as closed-form)
  per_cap <- max(Omega, 0.1) / max(N, 0.1)
  spp <- params$s0 * per_cap * (1 - N / params$K)
  ext <- params$e0 / (per_cap + 0.01) + params$e_floor
  dN <- N * (spp - ext)

  # λ* (same)
  ls <- if (params$eta0 * C_N > 1e-10 && params$kappa > 0)
    (params$alpha_comp * N / (params$eta0 * C_N) - 1) / params$kappa
  else Inf

  list(c(dB, drhos, dOmega, dN),
       lambda_star = ls,
       dd_sign = sign(eta * C_N - params$alpha_comp * N),
       mean_rho = rho)
}

#' Default δ-coupled parameter set
#'
#' 5 bins: δ = {2, 5, 8, 12, 20}\cr
#' Weights: decreasing with δ (more shallow capacity initially)\cr
#' Equilibria: increasing with δ (deeper δ → more retained capacity)
#'
#' @return List of parameters with M = 5 bins.
#' @export
delta_defaults <- function() {
  list(
    gamma = 0.5, delta_rate = 0.06, sigma = 0.4, rho_opt = 0.1,
    k10_scaled = 0.08, beta = 0.3,
    eta0 = 0.08, kappa = 2.5, alpha_comp = 0.2, gamma_net = 1.5,
    s0 = 0.1, e0 = 0.05, K = 15, Omega_max = 500, e_floor = 0.001,
    n_bins = 5,
    deltas = c(2, 5, 8, 12, 20),
    weights = c(0.35, 0.25, 0.20, 0.12, 0.08),
    rho_eq = c(0.04, 0.08, 0.15, 0.30, 0.60)
  )
}

#' Run δ-coupled simulation
#'
#' @param params List. Parameters from delta_defaults() or modified.
#' @param N0 Numeric. Initial lineage count. Default 5 (below fragility threshold).
#' @param Omega0 Numeric. Initial niche space. Default 100.
#' @param rho_init Numeric vector. Initial per-bin capacities. NULL = all 0.95.
#' @param t_max Numeric. Maximum time. Default 2000.
#' @param n_points Integer. Number of time points. Default 2000.
#' @return Data frame with columns: time, B, rho_{δ}, Omega, N, lambda_star,
#'         dd_sign, crossed. Attributes: flipped, final_ls.
#' @export
#' @examples
#' p <- delta_defaults()
#' sol <- delta_vi(p, N0 = 5)
#' tail(sol$N, 1)
delta_vi <- function(params = delta_defaults(), N0 = 5, Omega0 = 100,
                      rho_init = NULL, t_max = 2000, n_points = 2000) {
  M <- params$n_bins
  if (is.null(rho_init)) rho_init <- rep(0.95, M)
  y0 <- c(B = 0.1, rho_init, N = N0, Omega = Omega0)
  times <- seq(0, t_max, length.out = n_points)

  suppressWarnings({
    sol <- deSolve::ode(y0, times, delta_ode, params,
               method = "lsoda", rtol = 1e-4, atol = 1e-6)
  })

  df <- data.frame(time = sol[, 1], B = sol[, 2])
  for (i in 1:M) df[[paste0("rho_", params$deltas[i])]] <- sol[, 2 + i]
  df$Omega <- sol[, 3 + M]
  df$N <- sol[, 2 + M]

  if (ncol(sol) >= 5 + M) {
    df$lambda_star <- sol[, 4 + M]
    df$dd_sign <- sol[, 5 + M]
    df$crossed <- df$B > df$lambda_star & is.finite(df$lambda_star)
  }

  attr(df, "flipped") <- any(df$crossed, na.rm = TRUE)
  attr(df, "final_ls") <- tail(df$lambda_star, 1)
  df
}

# =========================================================================
# Startup fragility analysis
# =========================================================================

#' Map the startup fragility threshold
#'
#' Tests a range of N₀ values to find the minimum initial lineage count
#' required for λ* crossing (positive DD take-off).
#'
#' @param params List. δ-coupled parameters (from delta_defaults).
#' @param N0_range Numeric vector. Initial lineage counts to test.
#'        Default c(1, 2, 3, 5, 7, 10, 15, 20).
#' @param t_max Numeric. Maximum time per run. Default 2000.
#' @return Data frame with columns: N0, N_final, flipped, phase.
#' @export
#' @examples
#' ft <- startup_fragility(delta_defaults())
#' ft[ft$flipped, ]  # which N0 values succeed
startup_fragility <- function(params = delta_defaults(),
                               N0_range = c(1, 2, 3, 5, 7, 10, 15, 20),
                               t_max = 2000) {
  results <- data.frame(N0 = N0_range, N_final = NA,
                        flipped = NA, phase = NA_character_,
                        stringsAsFactors = FALSE)

  for (i in seq_along(N0_range)) {
    sol <- delta_vi(params, N0 = N0_range[i], t_max = t_max)
    results$N_final[i] <- tail(sol$N, 1)
    results$flipped[i] <- attr(sol, "flipped")
    # Phase: no flip = pre-takeoff, flip + N > 1 = growth, flip + N = 1 = transient
    if (!attr(sol, "flipped")) {
      results$phase[i] <- "pre-takeoff"
    } else if (tail(sol$N, 1) > 1) {
      results$phase[i] <- "sustained"
    } else {
      results$phase[i] <- "transient"
    }
  }
  results
}

# =========================================================================
# β sensitivity sweep
# =========================================================================

#' Sweep over β to test shielding function sensitivity
#'
#' @param beta_vals Numeric vector. β values to test. Default c(0.1, 0.3, 0.5, 1.0).
#' @param params List. δ-coupled parameters (from delta_defaults).
#' @return Data frame with final ρ per bin for each β.
#' @export
beta_sensitivity <- function(beta_vals = c(0.1, 0.3, 0.5, 1.0),
                              params = delta_defaults()) {
  results <- data.frame(beta = beta_vals)
  di_names <- paste0("rho_", params$deltas)
  for (d in di_names) results[[d]] <- NA

  for (i in seq_along(beta_vals)) {
    p <- params; p$beta <- beta_vals[i]
    sol <- delta_vi(p)
    for (d in di_names) results[i, d] <- tail(sol[[d]], 1)
  }
  results
}

#' Compute per-bin relaxation half-lives
#'
#' @param deltas Numeric vector. δ depths. Default c(2, 5, 8, 12, 20).
#' @param k_base Numeric. Baseline relaxation rate. Default 0.08.
#' @param beta Numeric. Shielding coefficient. Default 0.3.
#' @param B Numeric. Commitment level at which to evaluate. Default 0.5.
#' @return Data frame with delta, k_effective, half_life.
#' @export
delta_half_lives <- function(deltas = c(2, 5, 8, 12, 20),
                              k_base = 0.08, beta = 0.3, B = 0.5) {
  f <- 1 / (1 + beta * deltas)
  k <- k_base * f * (1 + 0.5 * B)
  t_half <- log(2) / k
  data.frame(delta = deltas, k_eff = k, half_life = t_half)
}