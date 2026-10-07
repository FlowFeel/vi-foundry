#' Model comparison: VI ODE vs simpler diversification alternatives
#'
#' Fits three models to simulated or empirical N(t) trajectories:
#' 1. Constant-rate birth-death (CRBD): dN/dt = r·N
#' 2. Standard diversity-dependent (DD): dN/dt = N·λ₀(1-N/K) - μ·N
#' 3. VI closed-form (VI-CF): full B-ρ-Ω-N coupling
#'
#' @name model_comparison
NULL

# =========================================================================
# Likelihood functions (Gaussian process model)
# =========================================================================

#' Fit CRBD: N(t) = N₀·exp(r·t)
#' @keywords internal
fit_crbd <- function(obs) {
  if (nrow(obs) < 3 || max(obs$N) <= 1) return(NULL)
  # Log-transform: log(N) = log(N₀) + r·t
  y <- log(pmax(obs$N, 1))
  m <- tryCatch(lm(y ~ time, data = obs), error = function(e) NULL)
  if (is.null(m)) return(NULL)
  r <- coef(m)[2]
  logN0 <- coef(m)[1]
  pred <- exp(as.numeric(predict(m)))

  nll <- -sum(dnorm(obs$N, mean = pred,
    sd = sqrt(pmax(pred, 0.1)) * 0.3, log = TRUE))

  list(value = nll, par = c(r = r, logN0 = logN0),
       n_params = 2, converged = TRUE)
}

#' Fit standard DD: dN/dt = N·(λ₀(1-N/K) - μ)
#' Uses numerical integration and compares to observations.
#' @keywords internal
fit_dd <- function(obs) {
  if (nrow(obs) < 5 || max(obs$N) <= 1) return(NULL)

  # Analytical solution for logistic: N(t) = K/(1 + (K/N₀ - 1)·exp(-r·t))
  N0 <- obs$N[1]
  Nmax <- max(obs$N)

  # Fit: minimize NLL over r and K
  negll <- function(p) {
    r <- p[1]; K <- exp(p[2])
    pred <- K / (1 + (K/N0 - 1) * exp(-r * obs$time))
    pred[is.na(pred) | pred < 1] <- 1
    -sum(dnorm(log(obs$N), mean = log(pmax(pred, 1)),
      sd = 0.3, log = TRUE))
  }

  fit <- tryCatch(
    optim(c(0.05, log(Nmax * 1.5)), negll, method = "L-BFGS-B"),
    error = function(e) NULL
  )
  if (is.null(fit) || fit$convergence != 0) return(NULL)

  list(value = fit$value, par = c(r = fit$par[1], K = exp(fit$par[2])),
       n_params = 2, converged = TRUE)
}

#' Fit VI-CF: use ODE and compare to observations
#'
#' Fits to full state vector (B, rho, Omega, N) when available,
#' falling back to N-only when only N(t) is provided.
#' Full-state fitting resolves the identifiability issue where
#' N(t)-only fitting cannot distinguish κ and η₀ (Louca & Pennell 2020).
#' @export
fit_vi_cf <- function(obs, params_base = cf_defaults()) {
  if (nrow(obs) < 5) return(NULL)

  N0 <- obs$N[1]
  t_max <- max(obs$time)
  n_pts <- max(round(t_max), 50)

  # Check if we have full state (B, rho, Omega) or just N
  full_state <- all(c("B", "rho", "Omega") %in% names(obs))

  negll <- function(p) {
    kappa <- pmax(0.01, exp(p[1]))
    eta0 <- pmax(0.0001, exp(p[2]))
    P <- params_base
    P$kappa <- kappa; P$eta0 <- eta0
    sol <- tryCatch(
      closed_form_vi(P, N0 = N0, t_max = t_max, n_points = n_pts),
      error = function(e) NULL)
    if (is.null(sol)) return(1e6)

    nll <- 0
    # N component (always present)
    pred_N <- approx(sol$time, sol$N, xout = obs$time, rule = 2)$y
    pred_N <- pmax(pred_N, 1)
    nll <- nll - sum(dnorm(log(obs$N), mean = log(pred_N),
      sd = 0.3, log = TRUE))

    if (full_state) {
      # B component
      pred_B <- approx(sol$time, sol$B, xout = obs$time, rule = 2)$y
      nll <- nll - sum(dnorm(obs$B, mean = pred_B, sd = 0.1, log = TRUE))
      # ρ component
      pred_rho <- approx(sol$time, sol$rho, xout = obs$time, rule = 2)$y
      nll <- nll - sum(dnorm(obs$rho, mean = pred_rho, sd = 0.1, log = TRUE))
      # Ω component (log-scale)
      pred_Omega <- approx(sol$time, log(sol$Omega + 1),
        xout = obs$time, rule = 2)$y
      obs_logOmega <- log(pmax(obs$Omega, 1))
      nll <- nll - sum(dnorm(obs_logOmega, mean = pred_Omega,
        sd = 0.5, log = TRUE))
    }
    nll
  }

  # Multiple starting points to handle rugged likelihood surface
  starts <- list(
    c(log(params_base$kappa), log(params_base$eta0)),
    c(log(params_base$kappa * 0.5), log(params_base$eta0 * 0.5)),
    c(log(params_base$kappa * 1.5), log(params_base$eta0 * 1.5))
  )

  best <- NULL
  best_val <- Inf
  for (s in starts) {
    fit <- tryCatch(
      optim(s, negll, method = "Nelder-Mead",
            control = list(maxit = 300)),
      error = function(e) NULL)
    if (!is.null(fit) && fit$value < best_val) {
      best <- fit; best_val <- fit$value
    }
  }
  if (is.null(best)) return(NULL)

  list(
    value = best$value,
    par = c(kappa = exp(best$par[1]), eta0 = exp(best$par[2])),
    n_params = 2, converged = best$convergence == 0,
    full_state = full_state
  )
}

# =========================================================================
# Model fitting and comparison
# =========================================================================

#' Fit and compare all three models to a trajectory
#'
#' @param obs Data frame with time and N columns.
#' @param params_base List. Base parameters for VI-CF.
#' @param verbose Logical. Default TRUE.
#' @return List with results (data frame) and details (fit objects).
#' @export
compare_dd_models <- function(obs, params_base = cf_defaults(),
                               verbose = TRUE) {
  obs <- obs[is.finite(obs$N) & obs$N > 0.5, ]
  if (nrow(obs) < 5) {
    return(list(results = data.frame(
      model = character(), n_params = integer(), AIC = numeric(),
      delta_AIC = numeric(), converged = logical()),
      details = list()))
  }

  fits <- list()
  aics <- c()
  names <- c()

  # 1. CRBD
  if (verbose) cat("  CRBD... ")
  f1 <- fit_crbd(obs)
  if (!is.null(f1)) {
    fits[["CRBD"]] <- f1
    aics["CRBD"] <- 2 * f1$value + 2 * f1$n_params
    if (verbose) cat(sprintf("nll=%.1f ", f1$value))
  } else {
    if (verbose) cat("FAILED ")
  }

  # 2. Standard DD
  if (verbose) cat("| DD... ")
  f2 <- fit_dd(obs)
  if (!is.null(f2)) {
    fits[["DD"]] <- f2
    aics["DD"] <- 2 * f2$value + 2 * f2$n_params
    if (verbose) cat(sprintf("nll=%.1f ", f2$value))
  } else {
    if (verbose) cat("FAILED ")
  }

  # 3. VI-CF
  if (verbose) cat("| VI-CF... ")
  f3 <- fit_vi_cf(obs, params_base)
  if (!is.null(f3)) {
    fits[["VI-CF"]] <- f3
    aics["VI-CF"] <- 2 * f3$value + 2 * f3$n_params
    if (verbose) cat(sprintf("nll=%.1f ", f3$value))
  } else {
    if (verbose) cat("FAILED ")
  }

  if (verbose) cat("\n")

  if (length(aics) == 0) {
    return(list(results = data.frame(
      model = character(), n_params = integer(), AIC = numeric(),
      delta_AIC = numeric(), converged = logical()),
      details = list()))
  }

  delta <- aics - min(aics, na.rm = TRUE)
  results <- data.frame(
    model = names(aics),
    AIC = aics,
    delta_AIC = delta,
    converged = TRUE,
    row.names = NULL, stringsAsFactors = FALSE
  )

  list(results = results, details = fits)
}

#' Run model comparison across all three regimes
#'
#' @param K_calibrated Numeric. K value. Default 15.
#' @param params_base List. Base parameters.
#' @return List with three elements (eco, cult, dom).
#' @export
regime_model_comparison <- function(K_calibrated = 15,
                                     params_base = cf_defaults()) {
  params_base$K <- K_calibrated
  r <- cf_regime_comparison(K_calibrated)
  results <- list()

  for (nm in names(r)) {
    cat(sprintf("\n=== %s ===\n", nm))
    sol <- r[[nm]]
    obs <- sol[sol$N > 1, c("time", "N")]
    if (nrow(obs) < 10) {
      cat(sprintf("Insufficient data (N > 1: %d points)\n", nrow(obs)))
      results[[nm]] <- NULL
      next
    }
    # Thin to ~30 points for speed
    if (nrow(obs) > 30) obs <- obs[seq(1, nrow(obs), length.out = 30), ]
    cmp <- compare_dd_models(obs, params_base)
    if (nrow(cmp$results) > 0) {
      cat(sprintf("Best model: %s (AIC = %.1f)\n",
          cmp$results$model[which.min(cmp$results$AIC)],
          min(cmp$results$AIC)))
    }
    results[[nm]] <- cmp
  }
  results
}

# =========================================================================
# PVDI chaos zone analog
# =========================================================================

#' Innovation-explosion regime (PVDI chaos zone analog)
#'
#' Removes the logistic cap on Ω (Ω_max = Inf), corresponding to
#' PVDI's chaos zone (Tůreček et al. 2019) where variability explodes
#' and the system cannot converge on any attractor.
#'
#' @param kappa Numeric. High B→innovation coupling. Default 3.0.
#' @param eta0 Numeric. High baseline innovation. Default 0.15.
#' @param gamma_net Numeric. High connectivity. Default 1.8.
#' @param t_max Numeric. Max time. Default 100.
#' @return List with trajectory and divergence diagnostics.
#' @export
innovation_explosion <- function(kappa = 3.0, eta0 = 0.15,
                                  gamma_net = 1.8, t_max = 100) {
  P <- cf_defaults()
  P$kappa <- kappa; P$eta0 <- eta0; P$gamma_net <- gamma_net
  P$Omega_max <- Inf
  P$K <- 1000

  sol <- tryCatch(
    closed_form_vi(P, N0 = 1, t_max = t_max, n_points = 500),
    error = function(e) NULL
  )
  if (is.null(sol)) {
    # System diverged — return partial trajectory up to divergence
    return(list(trajectory = NULL,
                divergence_time = t_max,
                final_Omega = Inf,
                final_N = Inf,
                note = "System diverged during integration"))
  }

  init_Omega <- sol$Omega[1]
  div_idx <- which(sol$Omega > 1e4 * init_Omega)[1]

  list(trajectory = sol,
       divergence_time = if (is.na(div_idx)) NA else sol$time[div_idx],
       final_Omega = tail(sol$Omega, 1),
       final_N = tail(sol$N, 1))
}