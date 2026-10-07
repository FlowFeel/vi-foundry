#' Spatially-buffered ecological regime
#'
#' Extends the closed-form system with immigration from a metacommunity,
#' allowing ecological lineages to maintain stable diversity under
#' negative diversity-dependence. This resolves the 0% generalist
#' acceptance problem: the standard ODE's ecological regime drives
#' N → 0 because it lacks spatial buffering.
#'
#' @section Immigration model:
#' dN += m * (N_meta - N/N_meta)
#' where m = immigration rate, N_meta = metacommunity diversity
#' (MacArthur & Wilson 1967 island biogeography).
#'
#' @section Parameterization (persistent ecological regime):
#' - κ = 0.3-0.7 (weak behavioral coupling)
#' - η₀ = 0.02-0.03 (low baseline innovation)
#' - γ_net ≈ 1.0 (linear network connectivity)
#' - K = 20-50 (carrying capacity)
#' - m = 0.02-0.05 (immigration rate)
#' - N_meta = 10-30 (metacommunity pool)
#' - dd_sign = negative (no λ* crossing)
#' - N stable at 3-15 through immigration balance
#'
#' @name spatial_ecology
NULL

#' ODE with immigration buffer
#' @keywords internal
eco_ode <- function(t, state, params) {
  B <- max(0, min(1, state[1]))
  rho <- max(0, min(1, state[2]))
  Omega <- max(0, state[3])
  N <- max(1, state[4])

  lambda <- abs(rho - params$rho_opt)
  V <- exp(-lambda^2 / (2 * params$sigma^2))
  dB <- params$gamma * V * (1 - B) - params$delta * (1 - V) * B

  k1 <- params$k10 * (1 + params$alpha1 * B)
  k2 <- params$k20 * (1 + params$alpha2 * B)
  drho <- -k1 * (rho - params$rho1) - k2 * (rho - params$rho2)
  drho <- if (rho > params$rho_opt) min(drho, 0) else 0

  C_N <- N^params$gamma_net
  eta <- params$eta0 * (1 + params$kappa * B)
  dOmega <- Omega * (-params$alpha_comp * N + eta * C_N) *
    (1 - Omega / params$Omega_max)

  per_cap <- max(Omega, 0.1) / max(N, 0.1)
  spp <- params$s0 * per_cap * (1 - N / params$K)
  ext <- params$e0 / (per_cap + 0.01) + params$e_floor
  dN <- N * (spp - ext)

  # Immigration buffer (MacArthur & Wilson island biogeography)
  if (params$immig_m > 0) {
    dN <- dN + params$immig_m * (params$immig_Nmeta - N / params$immig_Nmeta)
  }

  ls <- if (params$eta0 * C_N > 1e-10 && params$kappa > 0)
    (params$alpha_comp * N / (params$eta0 * C_N) - 1) / params$kappa
  else Inf
  list(c(dB, drho, dOmega, dN),
       lambda_star = ls,
       dd_sign = sign(eta * C_N - params$alpha_comp * N))
}

#' Run spatially-buffered ecological simulation
#'
#' @param params List. Parameters with immigration fields.
#' @param N0 Numeric. Initial N. Default 5.
#' @param t_max Numeric. Max time. Default 500.
#' @return Data frame with trajectory.
#' @export
eco_sim <- function(params = cf_defaults(), N0 = 5, t_max = 500) {
  y0 <- c(B = 0.1, rho = 0.95, Omega = 100, N = N0)
  times <- seq(0, t_max, length.out = 1000)
  suppressWarnings(sol <- deSolve::ode(y0, times, eco_ode, params,
               method = "lsoda", rtol = 1e-4, atol = 1e-6))
  df <- data.frame(time = sol[,1], B = sol[,2], rho = sol[,3],
                   Omega = sol[,4], N = sol[,5])
  if (ncol(sol) >= 7) {
    df$lambda_star <- sol[,6]; df$dd_sign <- sol[,7]
    df$crossed <- df$B > df$lambda_star & is.finite(df$lambda_star)
  }
  attr(df, "flipped") <- any(df$crossed, na.rm = TRUE)
  df
}

#' Find persistent ecological regimes via sweep
#'
#' Searches parameter space for ecological regimes that:
#' 1. Have negative DD sign throughout
#' 2. Maintain N > 3 for at least 200 generations
#' 3. Do NOT cross λ*
#'
#' @param n_scan Integer. Number of combinations. Default 500.
#' @return Data frame of successful regimes.
#' @export
#' @examples
#' eco_regimes <- find_persistent_ecological_regimes(n_scan = 100)
#' head(eco_regimes)
find_persistent_ecological_regimes <- function(n_scan = 500) {
  results <- data.frame()
  for (i in 1:n_scan) {
    p <- cf_defaults()
    p$kappa <- runif(1, 0.05, 1.5)
    p$eta0 <- runif(1, 0.005, 0.05)
    p$gamma_net <- runif(1, 0.8, 1.3)
    p$K <- sample(c(10, 20, 30, 50, 100), 1)
    p$e_floor <- runif(1, 0, 0.005)
    p$immig_m <- runif(1, 0, 0.1)
    p$immig_Nmeta <- sample(c(10, 20, 30, 50), 1)

    sol <- tryCatch(eco_sim(p, N0 = 5), error = function(e) NULL)
    if (is.null(sol)) next

    # Check: persistent N?
    n_above <- sum(sol$N > 3)
    if (n_above < 200) next

    # Check: negative DD throughout?
    neg_dd <- all(tail(sol$dd_sign[sol$N > 1], 100) < 0, na.rm = TRUE)
    if (!neg_dd) next

    # Check: no λ* crossing?
    flipped <- attr(sol, "flipped")
    if (isTRUE(flipped)) next

    results <- rbind(results, data.frame(
      kappa = p$kappa, eta0 = p$eta0, gamma_net = p$gamma_net,
      K = p$K, immig_m = p$immig_m, immig_Nmeta = p$immig_Nmeta,
      N_final = round(tail(sol$N, 1)),
      N_max = round(max(sol$N)),
      stringsAsFactors = FALSE))
  }
  results
}

#' Refitted ABC with proper ecological regime
#'
#' Now includes immigration-buffered ecological lineages and uses
#' persistence time (not just final N) as acceptance criterion.
#'
#' @param n_per_regime Integer. Prior samples per regime. Default 200.
#' @return List with samples and summary.
#' @export
abc_refitted <- function(n_per_regime = 200) {
  all_results <- data.frame()

  for (regime in c("generalist", "cultural", "domesticate")) {
    n_acc <- 0
    for (i in 1:n_per_regime) {
      if (regime == "cultural") {
        k <- runif(1, 0.1, 4); e <- runif(1, 0.01, 0.15)
        p <- cf_defaults(); p$kappa <- k; p$eta0 <- e
        p$gamma_net <- 1.5; p$K <- 15; p$immig_m <- 0
        s <- tryCatch(suppressWarnings(closed_form_vi(p, N0 = 1, t_max = 1000)),
                      error = function(e) NULL)
        if (is.null(s)) next
        # Accept if DD positive and N in [5, 30]
        dd_ok <- tail(s$dd_sign[s$N > 1], 1) >= 0
        N_ok <- tail(s$N, 1) >= 5 && tail(s$N, 1) <= 30
        if (dd_ok && N_ok) {
          n_acc <- n_acc + 1
          all_results <- rbind(all_results, data.frame(
            regime = regime, kappa = k, eta0 = e,
            N_final = round(tail(s$N, 1)), dd = "positive"))
        }
      } else if (regime == "domesticate") {
        k <- runif(1, 0.05, 2); e <- runif(1, 0.001, 0.05)
        p <- cf_defaults(); p$kappa <- k; p$eta0 <- e
        p$gamma_net <- 1.0; p$K <- 15; p$immig_m <- 0; p$Omega_max <- 50
        s <- tryCatch(suppressWarnings(
          closed_form_vi(p, N0 = 3, Omega0 = 50, t_max = 500)),
          error = function(e) NULL)
        if (is.null(s)) next
        # Accept if DD negative and N < 3 (low diversity)
        dd_ok <- tail(s$dd_sign[s$N > 1], 1) < 0
        N_ok <- sum(s$N > 3) < 20  # quickly drops below 3
        if (dd_ok && N_ok) {
          n_acc <- n_acc + 1
          all_results <- rbind(all_results, data.frame(
            regime = regime, kappa = k, eta0 = e,
            N_final = round(max(1, tail(s$N, 1))), dd = "negative"))
        }
      } else { # generalist — now with immigration buffer
        k <- runif(1, 0.05, 2); e <- runif(1, 0.005, 0.05)
        g <- runif(1, 0.8, 1.3)
        Kc <- sample(c(20, 30, 50), 1)
        m <- runif(1, 0.01, 0.08)
        nm <- sample(c(15, 20, 30), 1)
        p <- cf_defaults(); p$kappa <- k; p$eta0 <- e
        p$gamma_net <- g; p$K <- Kc; p$immig_m <- m
        p$immig_Nmeta <- nm
        s <- tryCatch(suppressWarnings(eco_sim(p, N0 = 5, t_max = 500)),
                      error = function(e) NULL)
        if (is.null(s)) next
        # Accept if DD negative, N persists > 200 gen above 3, no λ* crossing
        neg_dd <- all(tail(s$dd_sign[s$N > 1], 50) < 0, na.rm = TRUE)
        persist <- sum(s$N > 3) > 200
        no_flip <- !isTRUE(attr(s, "flipped"))
        if (neg_dd && persist && no_flip) {
          n_acc <- n_acc + 1
          all_results <- rbind(all_results, data.frame(
            regime = regime, kappa = k, eta0 = e, gamma = round(g, 2),
            K = Kc, m = round(m, 3), Nmeta = nm,
            N_final = round(tail(s$N, 1)), dd = "negative"))
        }
      }
    }
    cat(sprintf("  %s: %d accepted / %d (%.0f%%)\n",
        regime, n_acc, n_per_regime, 100 * n_acc / n_per_regime))
  }

  # Summarize
  if (nrow(all_results) > 0) {
    cat("\nFitted parameters:\n")
    for (r in unique(all_results$regime)) {
      sub <- all_results[all_results$regime == r, ]
      cat(sprintf("  %s (n=%d): κ=%.2f", r, nrow(sub),
          median(sub$kappa)))
      if ("eta0" %in% names(sub))
        cat(sprintf(" η₀=%.3f", median(sub$eta0)))
      if ("m" %in% names(sub))
        cat(sprintf(" m=%.3f", median(sub$m)))
      cat(sprintf(" N_final=%.0f\n", median(sub$N_final)))
    }
  }
  all_results
}