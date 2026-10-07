#' Real-data fitting using van Holstein & Foley (2024) calibration targets
#'
#' Fits κ and η₀ using the published DD signs from van Holstein & Foley (2024):
#' - Homo: positive DD (Gl > 0) 
#' - Canis: negative DD (Gl < 0)
#'
#' Uses ABC-like rejection sampling: sample κ, η₀ from priors, run ODE,
#' accept if the predicted DD sign matches the empirical target.
#'
#' @name real_data_fitting
NULL

#' ABC-like rejection sampling for κ, η₀
#'
#' @param target_eco Data frame with columns: regime ("generalist", "cultural", "domesticate"),
#'        target_N (empirical lineage count), target_DD ("positive" or "negative"),
#'        tol_N (tolerance for N match, default 0.5 = ±50%).
#' @param n_samples Integer. Number of prior samples. Default 1000.
#' @param priors List with kappa_range (c(min, max)) and eta0_range (c(min, max)).
#' @return Data frame with accepted samples (kappa, eta0, regime, pred_N, pred_DD).
#' @export
#' @examples
#' targets <- data.frame(
#'   regime = c("generalist", "cultural", "domesticate"),
#'   target_N = c(5, 15, 1),
#'   target_DD = c("negative", "positive", "negative"),
#'   tol_N = c(0.5, 0.3, 0.5),
#'   stringsAsFactors = FALSE)
#' abc <- abc_fit_parameters(targets, n_samples = 200)
#' aggregate(kappa ~ regime, abc, median)
abc_fit_parameters <- function(targets, n_samples = 1000,
                                priors = list(
                                  kappa_range = c(0.05, 4.0),
                                  eta0_range = c(0.001, 0.15))) {

  if (!requireNamespace("deSolve", quietly = TRUE)) stop("deSolve required")

  results <- data.frame()
  n_accepted <- 0
  n_total <- 0

  P_base <- cf_defaults()

  for (regime in targets$regime) {
    t <- targets[targets$regime == regime, ]
    target_N <- t$target_N[1]
    target_DD <- t$target_DD[1]
    tol_N <- t$tol_N[1]

    kappa_samples <- runif(n_samples, priors$kappa_range[1], priors$kappa_range[2])
    eta0_samples <- runif(n_samples, priors$eta0_range[1], priors$eta0_range[2])

    for (i in seq_len(n_samples)) {
      P <- P_base
      P$kappa <- kappa_samples[i]
      P$eta0 <- eta0_samples[i]

      # Set regime-specific defaults
      if (regime == "generalist") {
        P$gamma_net <- 1.0; N0 <- 5
      } else if (regime == "cultural") {
        P$gamma_net <- 1.5; N0 <- 1
      } else {
        P$gamma_net <- 1.0; N0 <- 3; P$Omega_max <- 50
      }

      sol <- tryCatch(closed_form_vi(P, N0 = N0, t_max = 500),
                      error = function(e) NULL)
      if (is.null(sol)) next

      pred_N <- max(1, tail(sol$N, 1))
      pred_DD <- if (tail(sol$dd_sign, 1) >= 0) "positive" else "negative"

      # Acceptance criteria
      # 1. DD sign matches
      dd_match <- pred_DD == target_DD
      # 2. N is within tolerance of target (only for non-extinct regimes)
      N_ok <- if (target_N > 1) {
        abs(log(pred_N) - log(target_N)) < abs(log(1 + tol_N))
      } else TRUE

      n_total <- n_total + 1
      if (dd_match && N_ok) {
        n_accepted <- n_accepted + 1
        results <- rbind(results, data.frame(
          regime = regime,
          kappa = kappa_samples[i],
          eta0 = eta0_samples[i],
          pred_N = pred_N,
          pred_DD = pred_DD,
          stringsAsFactors = FALSE))
      }
    }
    cat(sprintf("  %s: accepted %d/%d (%.1f%%)\n",
        regime, nrow(results[results$regime == regime, ]),
        n_samples, 100 * nrow(results[results$regime == regime, ]) / n_samples))
  }
  results
}

#' Fit parameters using van Holstein & Foley (2024) target values
#'
#' Pre-configured with published targets:
#' - Homo (cultural): positive DD, N ≈ 15
#' - Canis (domesticate): negative DD, N ≈ 1 (low diversity)
#' - Ecological baseline (generalist): negative DD, N ≈ 5
#'
#' @param n_samples Integer. Prior samples per regime. Default 500.
#' @return List with: samples (accepted parameter draws),
#'         summary (median κ, η₀ per regime), fit_figures (optional).
#' @export
fit_from_empirical_targets <- function(n_samples = 500) {
  targets <- data.frame(
    regime = c("generalist", "cultural", "domesticate"),
    target_N = c(5, 15, 1),
    target_DD = c("negative", "positive", "negative"),
    tol_N = c(0.5, 0.3, 0.5),
    stringsAsFactors = FALSE)

  cat("Fitting VI parameters to empirical targets (van Holstein & Foley 2024):\n")
  cat("Cultural (Homo): positive DD, N ~ 15\n")
  cat("Domesticate (Canis): negative DD, N ~ 1\n")
  cat("Generalist (ecological): negative DD, N ~ 5\n\n")

  samples <- abc_fit_parameters(targets, n_samples = n_samples)

  if (nrow(samples) == 0) {
    cat("No accepted samples. Try increasing n_samples or widening priors.\n")
    return(list(samples = samples, summary = NULL))
  }

  summary <- aggregate(cbind(kappa, eta0) ~ regime, samples,
    FUN = function(x) c(median = median(x),
                        q25 = quantile(x, 0.25),
                        q75 = quantile(x, 0.75)))
  summary <- do.call(data.frame, summary)

  cat("\nFitted parameter summaries:\n")
  for (i in seq_len(nrow(summary))) {
    cat(sprintf("  %s: κ=%.2f [%.2f–%.2f], η₀=%.4f [%.4f–%.4f]\n",
        summary$regime[i],
        summary$kappa.median[i], summary$kappa.q25[i], summary$kappa.q75[i],
        summary$eta0.median[i], summary$eta0.q25[i], summary$eta0.q75[i]))
  }

  list(samples = samples, summary = summary)
}