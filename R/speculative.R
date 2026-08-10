#' Speculative simulation capacity — toy realms for exploring VI
#'
#' The toy realms are a theoretical-exploration layer that makes VI's
#' predictions explorable across parameter space and hypothetical substrates.
#' They are NOT empirical tests — they do not source new data and do not claim
#' to corroborate VI. Each realm names the experiment that would convert it
#' from speculative to empirical.
#'
#' See `docs/review/toy-realms-plan.md` for the execution plan and
#' `docs/review/modeling-sim-viz-review.md` Part III for the proposal.
#'
#' @section Theoretical Context:
#'
#' The empirical tests are blocked on data (Items 4–6). The formal model is a
#' theoretical ODE that cannot fail. The toy realms fill the gap: they let a
#' reader *explore* the consequences of VI across parameter space — "if VI
#' were true, what would we expect to see in worlds we have not measured?" —
#' sharpening the predictions for when the data arrives.
#'
#' @dft
#' - A1 (pure-io-separation): pure math, no I/O
#' - A2 (determinism): no RNG — fully deterministic (wraps deterministic models)
#' - A6 (check-result): returns proof objects with results + metadata
#'
#' @name speculative
NULL

#' Sweep the protection threshold θ across a grid
#'
#' For each θ in `theta_grid`, runs [threshold_model()] and records the
#' biphasic signal (`threshold_biphasicity`), the protected/unprotected
#' counts, and the mean retention. This makes the threshold gate *visible* as
#' a control parameter: the gate opens (biphasicity → 1) when θ separates
#' protected from unprotected traits, and closes (biphasicity → 0) when θ is
#' below the minimum depth (all protected) or above the maximum depth (all
#' unprotected).
#'
#' @param depths Numeric vector. The dependency architecture (integration
#'   depths of a hypothetical organism's traits).
#' @param theta_grid Numeric vector. θ values to sweep.
#' @param lambda Numeric. Shedding rate. Default 0.15.
#' @param m0 Numeric. Initial mismatch. Default 10.
#' @param alpha Numeric. Mismatch decay rate. Default 0.05.
#' @param time Numeric. Total integration time. Default 100.
#'
#' @return List (A6):
#'   \item{values}{List: `sweep` (data frame: theta, threshold_biphasicity,
#'     n_protected, n_unprotected, mean_retention), `peak_biphasicity`,
#'     `peak_theta`, `results` (full per-θ result list)}
#'   \item{metadata}{List: n, n_traits, depths, params, method, seed, converged}
#'
#' @section Theoretical Context:
#'
#' VI Prediction: biphasic kinetics — the threshold gate separates protected
#' traits (d ≥ θ, retention = 1.0) from unprotected traits (d < θ, retention
#' → 0). The biphasic signal IS the gate (math-review Issue 3, resolved).
#'
#' This sweep shows the gate as a control parameter: shifting θ changes which
#' traits are protected, and the biphasic signal responds discontinuously at
#' each trait's depth. This makes the R6 method-misspecification visceral: a
#' cross-sectional regression across organisms with *different* θ would see
#' noise, not a logistic — which is exactly why T3 fails on real data.
#'
#' Competitors: constant rate (no gate, no biphasicity), accelerating (no
#' gate). The biphasic gate is unique to VI's threshold-gated model.
#'
#' @dft A1, A2, A6
#'
#' @export
#' @examples
#' result <- sweep_threshold(
#'   depths = c(0, 1, 2, 3, 5),
#'   theta_grid = seq(0, 6, by = 0.5)
#' )
#' result$values$peak_theta  # θ where the gate is maximally open
sweep_threshold <- function(depths, theta_grid, lambda = 0.15,
                            m0 = 10, alpha = 0.05, time = 100) {
  n_theta <- length(theta_grid)
  n_traits <- length(depths)

  # Collect per-theta results
  results <- lapply(theta_grid, function(th) {
    r <- tryCatch(
      suppressWarnings(threshold_model(
        depths = depths, lambda = lambda, theta = th,
        m0 = m0, alpha = alpha, time = time
      )),
      error = function(e) NULL
    )
    if (is.null(r)) {
      # Edge case: model failed (should not happen after the edge-case fix,
      # but guard defensively). Report zero contrast.
      list(
        theta = th,
        threshold_biphasicity = 0,
        n_protected = sum(depths >= th),
        n_unprotected = sum(depths < th),
        mean_retention = NA_real_,
        final_retention = rep(NA_real_, n_traits)
      )
    } else {
      bp <- r$values[["threshold_biphasicity"]]
      # Replace NA (all-protected or all-unprotected) with 0: no contrast.
      if (is.na(bp)) bp <- 0
      list(
        theta = th,
        threshold_biphasicity = bp,
        n_protected = r$metadata$n_protected,
        n_unprotected = r$metadata$n_unprotected,
        mean_retention = mean(r$values[["final_retention"]]),
        final_retention = r$values[["final_retention"]]
      )
    }
  })

  # Build sweep data frame
  sweep_df <- data.frame(
    theta = vapply(results, `[[`, numeric(1), "theta"),
    threshold_biphasicity = vapply(results, `[[`, numeric(1), "threshold_biphasicity"),
    n_protected = vapply(results, `[[`, integer(1), "n_protected"),
    n_unprotected = vapply(results, `[[`, integer(1), "n_unprotected"),
    mean_retention = vapply(results, `[[`, numeric(1), "mean_retention")
  )

  # Peak analysis
  peak_idx <- which.max(sweep_df$threshold_biphasicity)

  result <- list(
    values = list(
      sweep = sweep_df,
      peak_biphasicity = sweep_df$threshold_biphasicity[[peak_idx]],
      peak_theta = sweep_df$theta[[peak_idx]],
      results = results
    ),
    metadata = list(
      n = n_theta,
      n_traits = n_traits,
      depths = depths,
      params = list(lambda = lambda, m0 = m0, alpha = alpha, time = time),
      method = "threshold_sweep",
      seed = NA_integer_, # deterministic (A2: no RNG)
      converged = TRUE
    )
  )

  validate_result(result)
  result
}

#' Visualize the threshold gate: θ vs biphasicity
#'
#' Plots the protection threshold θ (x-axis) against `threshold_biphasicity`
#' (y-axis) from a [sweep_threshold()] result. The gate "opens" (biphasicity
#' → 1) when θ separates protected from unprotected traits, and "closes"
#' (biphasicity → 0) at the edges. Vertical dashed lines mark each trait's
#' depth (where the gate composition changes).
#'
#' @param sweep_result List. A [sweep_threshold()] result.
#'
#' @return A ggplot2 object.
#'
#' @section Theoretical Context:
#'
#' The threshold gate is the heart of VI's biphasic prediction. Seeing it
#' respond to θ builds the intuition that the biphasic signal is *the gate*,
#' not the displacement ratio (math-review Issue 3, resolved). The shaded
#' region is the "gate open" zone — the parameter range where VI's biphasic
#' prediction is active.
#'
#' @dft A1, A6
#'
#' @export
#' @examples
#' \dontrun{
#' result <- sweep_threshold(depths = c(0, 1, 2, 3, 5), theta_grid = seq(0, 6, 0.5))
#' plot_threshold_gate(result)
#' }
plot_threshold_gate <- function(sweep_result) {
  df <- sweep_result$values$sweep
  depths <- sweep_result$metadata$depths

  p <- ggplot2::ggplot(df, ggplot2::aes(x = .data$theta,
                                        y = .data$threshold_biphasicity)) +
    # Shade the "gate open" region (biphasicity > 0)
    ggplot2::geom_area(fill = "#3498db", alpha = 0.15) +
    ggplot2::geom_line(color = "#3498db", linewidth = 1) +
    ggplot2::geom_point(size = 2, color = "#3498db") +
    # Vertical lines at each unique depth (gate composition changes)
    ggplot2::geom_vline(
      xintercept = unique(depths),
      linetype = "dashed", color = "grey50", linewidth = 0.4
    ) +
    ggplot2::ylim(0, 1.05) +
    ggplot2::labs(
      title = "Threshold gate: biphasic signal vs protection threshold \u03b8",
      subtitle = "The gate opens when \u03b8 separates protected from unprotected traits",
      x = "Protection threshold \u03b8",
      y = "threshold_biphasicity\n(protected \u2212 unprotected retention)",
      caption = paste("Dashed lines = trait depths:",
                      paste(unique(depths), collapse = ", "))
    ) +
    ggplot2::theme_minimal(base_size = 12)

  p
}
