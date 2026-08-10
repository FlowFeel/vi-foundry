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

# =====================================================================
# Realm 2 — Irreversibility explorer
# =====================================================================

#' Compute the hysteresis loop area
#'
#' Runs [cusp_hysteresis_check()] and computes the area enclosed between the
#' forward and reverse equilibrium paths using the trapezoid rule. Zero area
#' means no hysteresis (the system is reversible); large area means strong
#' irreversibility (the forward and reverse paths enclose a loop).
#'
#' This is the *quantitative* irreversibility metric — [cusp_hysteresis_check()]
#' returns a boolean (`has_hysteresis`) and a max pointwise difference; this
#' function returns the full loop area, which is a continuous measure of how
#' irreversible the system is.
#'
#' @param control_values Numeric vector. The control parameter path (e.g., a
#'   sequence of `b` values from low to high).
#' @param equilibrium_fn Function. Pure `(control_value, prev_state) -> state`.
#'   Typically from [make_cusp_equilibrium_fn()].
#' @param seed Integer. Seed for reproducibility. Default 42.
#' @param initial_state Numeric. Starting state for the forward sweep. Default 0.
#'
#' @return List (A6):
#'   \item{values}{Named: `loop_area`, `max_difference`, `has_hysteresis`,
#'     `n_control_values`}
#'   \item{metadata}{List: `seed`, `n`, `control_range`, `initial_state`,
#'     `method`, `converged`}
#'
#' @section Theoretical Context:
#'
#' VI Prediction: irreversibility — the forward path (increasing commitment)
#' differs from the reverse path (decreasing commitment). The loop area
#' quantifies *how much* they differ. A system with no bifurcation (e.g.,
#' `a >= 0` in the cusp) has loop area = 0 (fully reversible). A system deep
#' in the cusp region (`a << 0`) has a large loop area (strongly irreversible).
#'
#' Competitor: gradual reversibility predicts loop area = 0 always (no
#' bifurcation, smooth recovery).
#'
#' @dft A1, A2, A6
#'
#' @export
#' @examples
#' eq_fn <- make_cusp_equilibrium_fn(a = -1)
#' result <- hysteresis_loop_area(seq(-2, 2, length.out = 100), eq_fn)
#' result$values$loop_area  # > 0 (cusp region: irreversible)
hysteresis_loop_area <- function(control_values, equilibrium_fn, seed = 42L,
                                  initial_state = 0) {
  hyst <- cusp_hysteresis_check(
    control_values = control_values,
    equilibrium_fn = equilibrium_fn,
    seed = seed,
    initial_state = initial_state
  )

  fwd <- hyst$values$forward_states
  rev_states <- hyst$values$reverse_states
  cv <- hyst$values$control_values

  # rev(rev_states) is ordered by increasing control (matching forward).
  # Signed loop area via the trapezoid rule:
  #   area = integral of (forward - reverse) d(control)
  diff_vals <- fwd - rev(rev_states)
  dx <- diff(cv)
  signed_area <- sum(0.5 * dx * (diff_vals[-length(diff_vals)] +
                                   diff_vals[-1]), na.rm = TRUE)
  loop_area <- abs(signed_area)

  result <- list(
    values = list(
      loop_area = loop_area,
      max_difference = hyst$values$max_difference,
      has_hysteresis = hyst$values$has_hysteresis,
      n_control_values = length(cv)
    ),
    metadata = list(
      seed = seed,
      n = length(cv),
      control_range = range(cv),
      initial_state = initial_state,
      method = "trapezoid_rule",
      converged = TRUE
    )
  )

  validate_result(result)
  result
}

#' Sweep the cusp parameter `a` and compute loop area at each value
#'
#' For each `a` in `a_grid`, creates a cusp equilibrium function
#' ([make_cusp_equilibrium_fn()]), runs [hysteresis_loop_area()], and records
#' the loop area. This shows irreversibility emerging at the bifurcation
#' (`a = 0`): for `a >= 0` (no bifurcation) the loop area is 0; for `a < 0`
#' (cusp region) the loop area rises as `|a|` increases (the cusp region
#' widens, producing a larger hysteresis loop).
#'
#' @param a_grid Numeric vector. Values of the cusp parameter `a` to sweep.
#' @param control_values Numeric vector. The control parameter path (`b`
#'   values). Default `seq(-2, 2, length.out = 100)`.
#' @param seed Integer. Seed for reproducibility. Default 42.
#' @param initial_state Numeric. Starting state for each forward sweep.
#'   Default 0.
#'
#' @return List (A6):
#'   \item{values}{List: `sweep` (data frame: a, loop_area, has_hysteresis,
#'     max_difference), `peak_loop_area`, `peak_a`, `bifurcation_a`}
#'   \item{metadata}{List: `n`, `a_grid`, `control_range`, `seed`,
#'     `initial_state`, `method`, `converged`}
#'
#' @section Theoretical Context:
#'
#' VI Prediction: irreversibility emerges discontinuously at the bifurcation.
#' For `a >= 0` the system has a single equilibrium (no bifurcation, fully
#' reversible, loop area = 0). For `a < 0` the system has a cusp (two stable
#' equilibria); the loop area grows as `|a|` increases because the cusp
#' region widens. This makes irreversibility *quantitative* and shows exactly
#' where it emerges.
#'
#' Competitor: gradual reversibility predicts loop area = 0 for all `a` (no
#' bifurcation ever).
#'
#' @dft A1, A2, A6
#'
#' @export
#' @examples
#' result <- sweep_cusp_irreversibility(
#'   a_grid = seq(1, -2, by = -0.25),
#'   control_values = seq(-2, 2, length.out = 100)
#' )
#' result$values$peak_a  # most negative a (largest loop area)
sweep_cusp_irreversibility <- function(a_grid,
                                       control_values = seq(-2, 2, length.out = 100),
                                       seed = 42L,
                                       initial_state = 0) {
  results <- lapply(a_grid, function(a) {
    eq_fn <- make_cusp_equilibrium_fn(a = a)
    hysteresis_loop_area(
      control_values = control_values,
      equilibrium_fn = eq_fn,
      seed = seed,
      initial_state = initial_state
    )
  })

  sweep_df <- data.frame(
    a = a_grid,
    loop_area = vapply(results, function(r) r$values$loop_area, numeric(1)),
    has_hysteresis = vapply(results, function(r) r$values$has_hysteresis, logical(1)),
    max_difference = vapply(results, function(r) r$values$max_difference, numeric(1))
  )

  peak_idx <- which.max(sweep_df$loop_area)

  result <- list(
    values = list(
      sweep = sweep_df,
      peak_loop_area = sweep_df$loop_area[[peak_idx]],
      peak_a = sweep_df$a[[peak_idx]],
      bifurcation_a = 0
    ),
    metadata = list(
      n = length(a_grid),
      a_grid = a_grid,
      control_range = range(control_values),
      seed = seed,
      initial_state = initial_state,
      method = "cusp_irreversibility_sweep",
      converged = TRUE
    )
  )

  validate_result(result)
  result
}

#' Visualize the irreversibility sweep: `a` vs loop area
#'
#' Plots the cusp parameter `a` (x-axis) against the hysteresis loop area
#' (y-axis) from a [sweep_cusp_irreversibility()] result. The loop area is 0
#' for `a >= 0` (no bifurcation, reversible) and rises for `a < 0` (cusp
#' region, irreversible). The cusp region is shaded; the bifurcation point
#' (`a = 0`) is marked with a dashed line.
#'
#' @param sweep_result List. A [sweep_cusp_irreversibility()] result.
#'
#' @return A ggplot2 object.
#'
#' @section Theoretical Context:
#'
#' Irreversibility is VI's sharpest departure from gradual reversibility.
#' This visualization shows that irreversibility is *quantitative* (loop
#' area, not just a boolean) and that it emerges at the bifurcation (`a = 0`).
#' The shaded region is where VI's irreversibility prediction is active.
#'
#' @dft A1, A6
#'
#' @export
#' @examples
#' \dontrun{
#' result <- sweep_cusp_irreversibility(a_grid = seq(1, -2, by = -0.25))
#' plot_irreversibility_sweep(result)
#' }
plot_irreversibility_sweep <- function(sweep_result) {
  df <- sweep_result$values$sweep

  p <- ggplot2::ggplot(df, ggplot2::aes(x = .data$a, y = .data$loop_area)) +
    # Shade the cusp region (a < 0: irreversible)
    ggplot2::geom_area(data = df[df$a <= 0, ], fill = "#e74c3c", alpha = 0.15) +
    ggplot2::geom_line(color = "#e74c3c", linewidth = 1) +
    ggplot2::geom_point(size = 2, color = "#e74c3c") +
    # Vertical line at the bifurcation (a = 0)
    ggplot2::geom_vline(xintercept = 0, linetype = "dashed", color = "grey50") +
    ggplot2::labs(
      title = "Irreversibility: hysteresis loop area vs cusp parameter a",
      subtitle = paste0("Loop area = 0 for a \u2265 0 (reversible); ",
                        "rises for a < 0 (cusp region: irreversible)"),
      x = "Cusp parameter a",
      y = "Hysteresis loop area",
      caption = "Dashed line = bifurcation (a = 0). Shaded = cusp region."
    ) +
    ggplot2::theme_minimal(base_size = 12)

  p
}
