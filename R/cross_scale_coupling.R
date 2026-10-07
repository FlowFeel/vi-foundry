#' Cross-scale coupling: V_mem as 5th state variable
#'
#' Extends the closed-form system with membrane potential V_mem as a
#' 5th state variable, completing the cross-scale coupling chain
#' from bioelectric state to macroevolutionary dynamics.
#'
#' @section Coupling chain:
#' dV_mem/dt = V₁·dB/dt  (V_mem tracks behavioral commitment)\cr
#' k_i(δ_i, V_mem) = k_base·f(δ_i) + α·(V_mem - V₀)/V₁\cr
#' Shallow δ (< 5): fully exposed to V_mem shifts → fast relaxation\cr
#' Deep δ (> 12): shielded → slow relaxation
#'
#' @name cross_scale_coupling
NULL

#' ODE with V_mem as 5th state variable (bulk-ρ version)
#'
#' State: (B, ρ, Ω, N, V_mem). V_mem couples to ρ relaxation rates.
#' @keywords internal
vm_ode_2d <- function(t, state, params) {
  B <- max(0, min(1, state[1]))
  rho <- max(0, min(1, state[2]))
  Omega <- max(0, state[3])
  N <- max(1, state[4])
  V_mem <- state[5]  # 5th state variable

  # B dynamics (same)
  lambda <- abs(rho - params$rho_opt)
  V <- exp(-lambda^2 / (2 * params$sigma^2))
  dB <- params$gamma * V * (1 - B) - params$delta * (1 - V) * B

  # ρ dynamics with V_mem coupling
  # Normalized V_mem drives acceleration: κ_V scales V_mem's effect
  V_norm <- (V_mem - params$V0) / (1 - params$V0)  # normalize to [0,1]
  V_norm <- max(0, min(1, V_norm))
  k1 <- params$k10 * (1 + params$alpha1 * B + params$kappa_V * V_norm)
  k2 <- params$k20 * (1 + params$alpha2 * B + params$kappa_V * V_norm * 0.3)
  drho <- -k1 * (rho - params$rho1) - k2 * (rho - params$rho2)
  drho <- if (rho > params$rho_opt) min(drho, 0) else 0

  # Ω dynamics (same)
  C_N <- N^params$gamma_net
  eta <- params$eta0 * (1 + params$kappa * B)
  dOmega <- Omega * (-params$alpha_comp * N + eta * C_N) *
    (1 - Omega / params$Omega_max)

  # N dynamics (same)
  per_cap <- max(Omega, 0.1) / max(N, 0.1)
  spp <- params$s0 * per_cap * (1 - N / params$K)
  ext <- params$e0 / (per_cap + 0.01) + params$e_floor
  dN <- N * (spp - ext)

  # V_mem dynamics: tracks B with scaling and noise
  # dV/dt = V₁·dB/dt + recovery toward resting potential
  dV_mem <- params$V1 * dB - params$V_rec * (V_mem - params$V0)

  list(c(dB, drho, dOmega, dN, dV_mem),
       lambda_star = if (params$eta0 * C_N > 1e-10 && params$kappa > 0)
         (params$alpha_comp * N / (params$eta0 * C_N) - 1) / params$kappa
       else Inf,
       dd_sign = sign(eta * C_N - params$alpha_comp * N))
}

#' Parameters for the V_mem-coupled system
#'
#' @return List with 5th-variable parameters.
#' @export
vm_defaults <- function() {
  p <- cf_defaults()
  p$V0 <- -70        # resting membrane potential (mV)
  p$V1 <- 30         # scaling: B=0 → -70mV, B=1 → -40mV
  p$V_rec <- 0.1     # recovery rate toward resting potential
  p$kappa_V <- 0.2   # V_mem coupling to relaxation rate
  p
}

#' Run V_mem-coupled simulation
#'
#' @param params List. Parameters from vm_defaults().
#' @param V0_init Numeric. Initial V_mem. Default -70 (resting).
#' @inheritParams closed_form_vi
#' @return Data frame with columns: time, B, rho, Omega, N, V_mem.
#' @export
closed_form_vi_vm <- function(params = vm_defaults(), N0 = 5, Omega0 = 100,
                               V0_init = -70, t_max = 500, n_points = 1000) {
  y0 <- c(B = 0.1, rho = 0.95, Omega = Omega0, N = N0, V_mem = V0_init)
  times <- seq(0, t_max, length.out = n_points)
  suppressWarnings(sol <- deSolve::ode(y0, times, vm_ode_2d, params,
               method = "lsoda", rtol = 1e-4, atol = 1e-6))
  df <- as.data.frame(sol[, 1:6])
  names(df) <- c("time", "B", "rho", "Omega", "N", "V_mem")
  # Extract extra columns (lambda_star, dd_sign) if present
  if (ncol(sol) >= 8) {
    df$lambda_star <- sol[, 7]
    df$dd_sign <- sol[, 8]
    df$crossed <- df$B > df$lambda_star & is.finite(df$lambda_star)
  }
  attr(df, "flipped") <- any(df$crossed, na.rm = TRUE)
  df
}

#' Compare V_mem-coupled vs uncoupled dynamics
#'
#' @param kappa_vals Numeric vector. κ values to test. Default c(0.5, 1.5, 2.5).
#' @return Data frame with regime, κ, N_final, flipped, V_mem_range.
#' @export
#' @examples
#' vc <- vm_comparison()
#' vc[vc$flipped, ]
vm_comparison <- function(kappa_vals = c(0.5, 1.5, 2.5)) {
  results <- data.frame(kappa = kappa_vals, N_final = NA,
                        flipped = NA, V_mem_final = NA,
                        V_mem_range = NA, regime = NA_character_,
                        stringsAsFactors = FALSE)
  for (i in seq_along(kappa_vals)) {
    p <- vm_defaults()
    p$kappa <- kappa_vals[i]
    if (kappa_vals[i] < 1) { p$eta0 <- 0.02; p$gamma_net <- 1.0 }
    else if (kappa_vals[i] > 2) { p$eta0 <- 0.08; p$gamma_net <- 1.5 }
    else { p$eta0 <- 0.05; p$gamma_net <- 1.3 }
    sol <- closed_form_vi_vm(p, N0 = if(kappa_vals[i]>2) 1 else 5,
                              t_max = 500)
    results$N_final[i] <- tail(sol$N, 1)
    results$flipped[i] <- attr(sol, "flipped")
    results$V_mem_final[i] <- tail(sol$V_mem, 1)
    results$V_mem_range[i] <- max(sol$V_mem) - min(sol$V_mem)
    results$regime[i] <- if (kappa_vals[i] < 1) "generalist"
      else if (kappa_vals[i] > 2) "cultural" else "transitional"
  }
  results
}