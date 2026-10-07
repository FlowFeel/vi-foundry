#' Closed-form 4D dynamical system: B-ρ-Ω-N with emergent λ*
#'
#' The complete VI closed-form system coupling behavioral commitment (B),
#' mean capacity (ρ), niche space volume (Ω), and lineage count (N).
#' Diversity-dependence sign λ* emerges from the η·C(N) > α·N balance
#' rather than being externally imposed.
#'
#' @section Equations:
#'
#' \deqn{\dot{B} = \gamma V(\rho)(1-B) - \delta (1-V(\rho)) B}
#' \deqn{V(\rho) = \exp(-(\rho-\rho_{\text{opt}})^2/2\sigma^2)}
#' \deqn{\dot{\rho} = -k_1(1+\alpha_1 B)(\rho-\rho_1) - k_2(1+\alpha_2 B)(\rho-\rho_2)}
#' \deqn{\dot{\Omega} = \Omega(-\alpha N + \eta_0(1+\kappa B)N^\gamma)(1-\Omega/\Omega_{\max})}
#' \deqn{\dot{N} = N(s_0(\Omega/N)(1-N/K) - e_0/(\Omega/N + \epsilon))}
#'
#' @section Regimes:
#' - Generalist (κ < 1): negative DD, N → 0, standard ecological saturation
#' - Cultural (κ > 2, η₀ > 0.05): positive DD, N → K, autocatalytic niche construction
#' - Domesticate (κ → 0, η₀ → 0): negative DD, N → 0, consumes substrate without producing
#'
#' @name closed_form_system
NULL

# =========================================================================
# Core ODE functions
# =========================================================================

#' Default parameters for the closed-form system
#'
#' @return List of 18 parameters with calibrated values and metadata.
#' @export
cf_defaults <- function() {
  list(
    # B dynamics
    gamma     = 0.5,   # commitment rate
    delta     = 0.06,  # disengagement rate
    sigma     = 0.4,   # valence function width
    rho_opt   = 0.1,   # niche optimum capacity

    # ρ dynamics (biphasic relaxation, §3.3)
    k10       = 0.08,  # fast relaxation base rate
    k20       = 0.005, # slow relaxation base rate
    alpha1    = 0.3,   # B→fast relaxation coupling
    alpha2    = 0.1,   # B→slow relaxation coupling
    rho1      = 0.25,  # fast equilibrium
    rho2      = 0.05,  # slow equilibrium (universal residual)

    # Ω dynamics (niche space)
    eta0      = 0.05,  # baseline innovation rate
    kappa     = 1.5,   # B→innovation coupling (KEY regime parameter)
    alpha_comp = 0.2,  # competitive consumption rate
    gamma_net = 1.3,   # network connectivity exponent

    # N dynamics (lineage count)
    s0        = 0.1,   # baseline speciation rate
    e0        = 0.05,  # baseline extinction rate
    K         = 15,    # lineage carrying capacity (calibrated, §S5.2)
    Omega_max = 500,   # niche space carrying capacity
    e_floor   = 0.001  # extinction floor
  )
}

#' Core ODE function for the B-ρ-Ω-N system
#'
#' @param t Numeric. Time.
#' @param state Numeric vector of length 4: B, rho, Omega, N.
#' @param params List. Parameter list (from cf_defaults or modified).
#' @return List with derivatives and diagnostics (lambda_star, dd_sign).
#' @export
cf_ode <- function(t, state, params) {
  B <- max(0, min(1, state[1]))
  rho <- max(0, min(1, state[2]))
  Omega <- max(0, state[3])
  N <- max(1, state[4])

  # B dynamics
  lambda <- abs(rho - params$rho_opt)
  V <- exp(-lambda^2 / (2 * params$sigma^2))
  dB <- params$gamma * V * (1 - B) - params$delta * (1 - V) * B

  # ρ dynamics with B-coupling (biphasic)
  k1 <- params$k10 * (1 + params$alpha1 * B)
  k2 <- params$k20 * (1 + params$alpha2 * B)
  drho <- -k1 * (rho - params$rho1) - k2 * (rho - params$rho2)
  drho <- if (rho > params$rho_opt) min(drho, 0) else 0

  # Ω dynamics (niche space with logistic cap)
  C_N <- N^params$gamma_net
  eta <- params$eta0 * (1 + params$kappa * B)
  dOmega <- Omega * (-params$alpha_comp * N + eta * C_N) *
    (1 - Omega / params$Omega_max)

  # N dynamics (per-capita niche space drives speciation)
  per_capita <- max(Omega, 0.1) / max(N, 0.1)
  spp <- params$s0 * per_capita * (1 - N / params$K)
  ext <- params$e0 / (per_capita + 0.01) + params$e_floor
  dN <- N * (spp - ext)

  # Emergent λ* (critical B for DD sign reversal)
  ls <- if (params$eta0 * C_N > 1e-10 && params$kappa > 0)
    (params$alpha_comp * N / (params$eta0 * C_N) - 1) / params$kappa
  else Inf

  list(c(dB, drho, dOmega, dN),
       lambda_star = ls,
       dd_sign = sign(eta * C_N - params$alpha_comp * N))
}

#' Run a single closed-form simulation
#'
#' @param params List. Parameters (from cf_defaults or modified).
#' @param N0 Numeric. Initial lineage count. Default 5.
#' @param Omega0 Numeric. Initial niche space volume. Default 100.
#' @param t_max Numeric. Maximum simulation time. Default 500.
#' @param n_points Integer. Number of time points. Default 1000.
#' @return Data frame with columns: time, B, rho, Omega, N, lambda_star, 
#'         dd_sign, crossed. Attributes: flipped, final_ls.
#' @export
#' @examples
#' p <- cf_defaults()
#' p$kappa <- 2.5; p$eta0 <- 0.08  # cultural regime
#' sol <- closed_form_vi(p, N0 = 1, t_max = 1000)
#' tail(sol$N, 1)  # final lineage count
closed_form_vi <- function(params = cf_defaults(), N0 = 5, Omega0 = 100,
                           t_max = 500, n_points = 1000) {
  y0 <- c(B = 0.1, rho = 0.95, Omega = Omega0, N = N0)
  times <- seq(0, t_max, length.out = n_points)

  suppressWarnings({
    sol <- deSolve::ode(y0, times, cf_ode, params,
               method = "lsoda", rtol = 1e-4, atol = 1e-6)
  })

  df <- data.frame(time = sol[, 1], B = sol[, 2], rho = sol[, 3],
                   Omega = sol[, 4], N = sol[, 5])

  if (ncol(sol) >= 7) {
    df$lambda_star <- sol[, 6]
    df$dd_sign <- sol[, 7]
    df$crossed <- df$B > df$lambda_star & is.finite(df$lambda_star)
  }

  attr(df, "flipped") <- any(df$crossed, na.rm = TRUE)
  attr(df, "final_ls") <- tail(df$lambda_star, 1)
  df
}

#' Run all three regimes and return comparison
#'
#' @param K_calibrated Numeric. Carrying capacity K (default 15 for Homo range).
#' @return List with three named elements: eco, cult, dom. Each is a
#'         simulation data frame from closed_form_vi().
#' @export
#' @examples
#' regimes <- cf_regime_comparison()
#' regimes$cult$N |> tail(1)  # cultural final N
cf_regime_comparison <- function(K_calibrated = 15) {
  base <- cf_defaults()
  base$K <- K_calibrated

  # Generalist (ecological)
  p_eco <- base
  p_eco$kappa <- 0.5; p_eco$eta0 <- 0.02; p_eco$gamma_net <- 1.0
  sol_eco <- closed_form_vi(p_eco, N0 = 5, t_max = 500)

  # Cultural (Homo)
  p_cult <- base
  p_cult$kappa <- 2.5; p_cult$eta0 <- 0.08; p_cult$gamma_net <- 1.5
  sol_cult <- closed_form_vi(p_cult, N0 = 1, t_max = 1000, n_points = 2000)

  # Domesticate (Canis)
  p_dom <- base
  p_dom$eta0 <- 0.001; p_dom$kappa <- 0.1; p_dom$gamma_net <- 1.0
  sol_dom <- closed_form_vi(p_dom, N0 = 3, Omega0 = 50, t_max = 500)

  list(eco = sol_eco, cult = sol_cult, dom = sol_dom)
}

# =========================================================================
# λ* derivation (analytical)
# =========================================================================

#' Compute λ* (critical commitment) at given N
#'
#' λ* = (1/κ)(α/η₀ · N^{1-γ} - 1)
#'
#' Interpretation:
#' - λ* < 0: unconditionally positive DD
#' - λ* → ∞: can never reach positive DD
#' - 0 < λ* < 1: finite threshold crossing (state-dependent)
#'
#' @param kappa Numeric. B→innovation coupling.
#' @param eta0 Numeric. Baseline innovation rate.
#' @param alpha_comp Numeric. Competitive consumption rate.
#' @param gamma_net Numeric. Network connectivity exponent.
#' @param N Numeric. Lineage count.
#' @return Numeric. λ* value.
#' @export
compute_lambda_star <- function(kappa, eta0, alpha_comp, gamma_net, N) {
  if (kappa <= 0 || eta0 * N^gamma_net < 1e-10) return(Inf)
  (alpha_comp * N^(1 - gamma_net) / eta0 - 1) / kappa
}

# =========================================================================
# Substrate sweep (κ × η₀ parameter space)
# =========================================================================

#' Sweep over κ × η₀ to map λ*-crossing boundary
#'
#' @param kappa_vals Numeric vector. κ values. Default seq(0, 3, length.out = 12).
#' @param eta_vals Numeric vector. η₀ values. Default seq(0.01, 0.12, length.out = 12).
#' @param params_base List. Base parameters (from cf_defaults).
#' @return List with elements: grid (data frame with kappa, eta0, flipped, max_N),
#'         flipped_matrix (12×12 matrix for contour plots).
#' @export
#' @examples
#' sw <- cf_substrate_sweep()
#' sum(sw$grid$flipped)  # how many combos cross λ*
cf_substrate_sweep <- function(
    kappa_vals = seq(0, 3, length.out = 12),
    eta_vals = seq(0.01, 0.12, length.out = 12),
    params_base = cf_defaults()) {

  grid <- expand.grid(kappa = kappa_vals, eta0 = eta_vals,
                      stringsAsFactors = FALSE)
  grid$flipped <- NA
  grid$final_N <- NA
  grid$max_N <- NA

  for (i in seq_len(nrow(grid))) {
    p <- params_base
    p$kappa <- grid$kappa[i]
    p$eta0 <- grid$eta0[i]
    sol <- closed_form_vi(p, N0 = 1)
    grid$flipped[i] <- attr(sol, "flipped")
    grid$final_N[i] <- tail(sol$N, 1)
    grid$max_N[i] <- max(sol$N)
  }

  flipped_matrix <- matrix(grid$flipped, nrow = length(kappa_vals), byrow = TRUE)

  list(grid = grid, flipped_matrix = flipped_matrix,
       kappa_vals = kappa_vals, eta_vals = eta_vals)
}

#' Full multi-parameter sensitivity sweep
#'
#' Sweeps over κ, η₀, γ_net, α_comp, and Ω_max to map regime boundaries.
#' More comprehensive than cf_substrate_sweep, which only sweeps κ × η₀.
#'
#' @param n_per_dim Integer. Points per dimension. Default 6 (keeps total manageable).
#' @param params_base List. Base parameters.
#' @return Data frame with all combinations and crossing status.
#' @export
cf_sensitivity_sweep <- function(n_per_dim = 6, params_base = cf_defaults()) {
  kappa_vals <- seq(0.1, 3, length.out = n_per_dim)
  eta_vals <- seq(0.01, 0.12, length.out = n_per_dim)
  gamma_vals <- seq(0.8, 2.0, length.out = n_per_dim)
  alpha_vals <- seq(0.05, 0.5, length.out = n_per_dim)
  Omega_vals <- c(100, 200, 500, 1000, 2000, 5000)

  total <- length(kappa_vals) * length(eta_vals) * length(gamma_vals) *
    length(alpha_vals) * length(Omega_vals)
  cat(sprintf("Full sensitivity sweep: %d parameter combos\n", total))

  # We'll do κ × η₀ as the main sweep, replicate for each γ_net value
  # (full 6D sweep would be too large)
  results <- data.frame()
  for (g in gamma_vals) {
    for (a in alpha_vals) {
      for (o in Omega_vals) {
        p <- params_base
        p$gamma_net <- g; p$alpha_comp <- a; p$Omega_max <- o
        sw <- cf_substrate_sweep(kappa_vals = kappa_vals, eta_vals = eta_vals,
                                 params_base = p)
        sw$grid$gamma_net <- g; sw$grid$alpha_comp <- a; sw$grid$Omega_max <- o
        results <- rbind(results, sw$grid)
      }
    }
  }
  results
}