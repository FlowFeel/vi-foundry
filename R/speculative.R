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

# =====================================================================
# Realm 3 — The Homo-inversion explorer
# =====================================================================
#
# RISK AND WORKAROUND (documented):
#
# The toy-realms-plan.md proposed the per-capita rate formula:
#   pc_rate = r * (feedback + (1-feedback) * N/(N+K))
# with feedback=0 -> logistic (negative DD) and feedback=0.5 -> autocatalytic
# (positive DD). This formula is WRONG: at feedback=0 it gives r*N/(N+K),
# whose derivative w.r.t. N is r*K/(N+K)^2 > 0 — ALWAYS positive DD. The
# function N/(N+K) is increasing in N, so (1-feedback)*N/(N+K) is always
# increasing; the formula interpolates between two POSITIVE-DD forms, not
# between logistic and autocatalytic.
#
# WORKAROUND: blend two bounded functions — one increasing (autocatalytic),
# one decreasing (bounded logistic):
#   autocatalytic(N) = 0.5 + 0.5*N/(N+K)   [increasing, bounded (0.5, 1)]
#   bounded_logistic(N) = K/(N+K)           [decreasing, bounded (0, 1)]
#   pc_rate = r * [feedback * autocatalytic(N) + (1-feedback) * bounded_logistic(N)]
#
# Analytical derivative:
#   d(pc_rate)/dN = r * K/(N+K)^2 * (1.5*feedback - 1)
# This is negative for feedback < 2/3 (niche-filling), positive for
# feedback > 2/3 (Homo inversion), zero at feedback = 2/3 (the bifurcation).
# Both terms are bounded in (0, 1), so pc_rate stays in (0, r) — no negative
# growth, no blow-up. At feedback=1 this reduces to r*(0.5+0.5*N/(N+K)),
# exactly matching the existing generate_autocatalytic_set() dynamics
# (verified: identical time series at feedback=1).

#' Generate a diversity time series with parameterized feedback (internal)
#'
#' Generates an innovation-count time series whose per-capita rate blends
#' autocatalytic (positive DD) and bounded-logistic (negative DD) growth:
#'   pc_rate = r * [feedback * (0.5 + 0.5*N/(N+K)) + (1-feedback) * K/(N+K)]
#' At feedback=0: bounded logistic (negative DD, niche-filling).
#' At feedback=1: bounded autocatalytic (positive DD, Homo inversion) —
#'   matches generate_autocatalytic_set() exactly.
#' Bifurcation at feedback = 2/3 (DD slope = 0).
#'
#' @param n_steps Integer. Time series length.
#' @param innovation_rate Numeric. Base rate r.
#' @param capacity Numeric. Carrying capacity K.
#' @param feedback Numeric in [0, 1]. 0 = logistic (negative DD), 1 =
#'   autocatalytic (positive DD). Bifurcation at 2/3.
#' @param seed Integer. RNG seed (unused — deterministic, A2 — but kept for
#'   contract consistency).
#' @return Numeric vector. Innovation counts over time.
#' @keywords internal
generate_dd_series <- function(n_steps, innovation_rate, capacity, feedback,
                                seed = 42L) {
  withr::with_seed(seed, {
    counts <- numeric(n_steps)
    counts[1] <- 1
    for (t in seq_len(n_steps)[-1]) {
      N <- counts[t - 1]
      pc_rate <- innovation_rate * (
        feedback * (0.5 + 0.5 * N / (N + capacity)) +
          (1 - feedback) * capacity / (N + capacity)
      )
      counts[t] <- max(0, counts[t - 1] + pc_rate * N)
    }
    counts
  })
}

#' Compute the diversity-dependence contrast
#'
#' Generates two matched innovation time series — one with logistic growth
#' (feedback = 0, negative DD, niche-filling — the competitor's model) and one
#' with autocatalytic growth (feedback = 1, positive DD, the Homo inversion —
#' VI's prediction) — and computes the diversity-dependence slope for each via
#' [diversity_dependence_sign()]. The *contrast* is the difference: positive
#' = the Homo inversion signature (autocatalytic DD slope > logistic DD slope).
#'
#' This makes the DD sign flip *visible*: the two trajectories have the same
#' growth direction (both increase) but opposite DD signs — the per-capita-
#' rate-vs-N slope flips from negative (logistic) to positive (autocatalytic).
#'
#' @param n_steps Integer. Time series length. Default 20.
#' @param innovation_rate Numeric. Base rate. Default 0.3.
#' @param capacity Numeric. Carrying capacity. Default 30.
#' @param seed Integer. Default 42.
#'
#' @return List (A6):
#'   \item{values}{List: `autocatalytic_dd_slope`, `autocatalytic_dd_sign`,
#'     `logistic_dd_slope`, `logistic_dd_sign`, `contrast`, `contrast_sign`,
#'     `autocatalytic_counts`, `logistic_counts`}
#'   \item{metadata}{List: `n`, `params`, `method`, `seed`, `converged`}
#'
#' @section Theoretical Context:
#'
#' VI Prediction: the Homo inversion — positive diversity-dependence (per-
#' capita innovation rate increases with diversity N). Competitor: niche-
#' filling — negative diversity-dependence (per-capita rate decreases with N).
#' Both produce growing time series, but the DD slope has opposite signs. The
#' contrast quantifies the difference: positive contrast = VI signature.
#'
#' @section Risk note:
#'
#' The formula used here (blend of autocatalytic + bounded-logistic) corrects
#' a bug in the original toy-realms-plan.md, which proposed
#' `r*(feedback + (1-feedback)*N/(N+K))` — a formula that is always positive-DD
#' (N/(N+K) is increasing in N, so the blend is always increasing). See the
#' comment block above `generate_dd_series()` for the full analysis.
#'
#' @dft A1, A2, A6
#'
#' @export
#' @examples
#' result <- diversity_dependence_contrast(n_steps = 20, capacity = 30)
#' result$values$contrast  # > 0 (Homo inversion signature)
diversity_dependence_contrast <- function(n_steps = 20, innovation_rate = 0.3,
                                           capacity = 30, seed = 42L) {
  # Autocatalytic: feedback = 1 (positive DD, Homo inversion)
  ac_counts <- generate_dd_series(n_steps, innovation_rate, capacity,
                                   feedback = 1, seed = seed)
  ac_dd <- diversity_dependence_sign(ac_counts, seed = seed)

  # Logistic: feedback = 0 (negative DD, niche-filling)
  log_counts <- generate_dd_series(n_steps, innovation_rate, capacity,
                                    feedback = 0, seed = seed)
  log_dd <- diversity_dependence_sign(log_counts, seed = seed)

  ac_slope <- ac_dd$values[["diversity_dependence_slope"]]
  log_slope <- log_dd$values[["diversity_dependence_slope"]]
  contrast <- ac_slope - log_slope

  result <- list(
    values = list(
      autocatalytic_dd_slope = ac_slope,
      autocatalytic_dd_sign = ac_dd$values[["diversity_dependence_sign"]],
      logistic_dd_slope = log_slope,
      logistic_dd_sign = log_dd$values[["diversity_dependence_sign"]],
      contrast = contrast,
      contrast_sign = ifelse(contrast > 0, "positive", "negative"),
      autocatalytic_counts = ac_counts,
      logistic_counts = log_counts
    ),
    metadata = list(
      n = n_steps,
      params = list(
        innovation_rate = innovation_rate,
        capacity = capacity,
        feedback_ac = 1,
        feedback_log = 0
      ),
      method = "dd_contrast",
      seed = seed,
      converged = TRUE
    )
  )

  validate_result(result)
  result
}

#' Sweep the endogenous-K feedback parameter
#'
#' Sweeps the feedback parameter (cultural complexity / endogenous-K strength)
#' across a grid and returns the diversity-dependence sign at each level. Shows
#' the bifurcation from negative DD (niche-filling, feedback < 2/3) to positive
#' DD (Homo inversion, feedback > 2/3). The theoretical bifurcation is at
#' feedback = 2/3; the measured bifurcation (from the linear regression in
#' [diversity_dependence_sign()]) is approximate but close.
#'
#' @param feedback_grid Numeric vector. Feedback values in [0, 1] to sweep.
#' @param n_steps Integer. Time series length. Default 20.
#' @param innovation_rate Numeric. Base rate. Default 0.3.
#' @param capacity Numeric. Carrying capacity. Default 30.
#' @param seed Integer. Default 42.
#'
#' @return List (A6):
#'   \item{values}{List: `sweep` (data frame: feedback, dd_slope, dd_sign),
#'     `bifurcation_feedback` (theoretical = 2/3), `measured_bifurcation_feedback`}
#'   \item{metadata}{List: `n`, `feedback_grid`, `params`, `method`, `seed`,
#'     `converged`}
#'
#' @section Theoretical Context:
#'
#' VI Prediction: the Homo inversion is a bifurcation — there is a threshold
#' in cultural complexity (feedback strength) beyond which diversity-
#' dependence flips from negative (niche-filling) to positive (autocatalytic).
#' This sweep makes the bifurcation explorable: below the threshold, the
#' system is niche-filling (competitor); above it, the system is autocatalytic
#' (VI). The threshold is the endogenous-K bifurcation (Review Item 3).
#'
#' @section Risk note:
#'
#' See [diversity_dependence_contrast()] — the feedback formula corrects a bug
#' in the original plan. The theoretical bifurcation is at feedback = 2/3
#' (where the analytical DD slope = 0). The *measured* bifurcation (where the
#' linear regression slope crosses zero) is approximate because the regression
#' fits a linear approximation to a nonlinear per-capita-rate function; the
#' sign is reliable but the exact crossing point may differ slightly from 2/3.
#'
#' @dft A1, A2, A6
#'
#' @export
#' @examples
#' result <- sweep_endogenous_k(feedback_grid = seq(0, 1, by = 0.1))
#' result$values$bifurcation_feedback  # theoretical = 2/3
sweep_endogenous_k <- function(feedback_grid, n_steps = 20, innovation_rate = 0.3,
                                capacity = 30, seed = 42L) {
  results <- lapply(feedback_grid, function(fb) {
    counts <- generate_dd_series(n_steps, innovation_rate, capacity,
                                  feedback = fb, seed = seed)
    dd <- diversity_dependence_sign(counts, seed = seed)
    list(
      feedback = fb,
      dd_slope = dd$values[["diversity_dependence_slope"]],
      dd_sign = dd$values[["diversity_dependence_sign"]],
      counts = counts
    )
  })

  sweep_df <- data.frame(
    feedback = vapply(results, `[[`, numeric(1), "feedback"),
    dd_slope = vapply(results, `[[`, numeric(1), "dd_slope"),
    dd_sign = vapply(results, `[[`, character(1), "dd_sign"),
    stringsAsFactors = FALSE
  )

  # Measured bifurcation: the feedback where dd_slope crosses zero.
  # Find the sign change (last negative, first positive).
  neg_idx <- which(sweep_df$dd_slope < 0)
  pos_idx <- which(sweep_df$dd_slope > 0)
  measured_bif <- if (length(neg_idx) > 0 && length(pos_idx) > 0) {
    # Linear interpolation between last negative and first positive
    last_neg <- max(neg_idx)
    first_pos <- min(pos_idx[pos_idx > last_neg])
    if (length(first_pos) > 0 && first_pos > last_neg) {
      s1 <- sweep_df$dd_slope[last_neg]
      s2 <- sweep_df$dd_slope[first_pos]
      f1 <- sweep_df$feedback[last_neg]
      f2 <- sweep_df$feedback[first_pos]
      f1 - s1 * (f2 - f1) / (s2 - s1)
    } else NA_real_
  } else NA_real_

  result <- list(
    values = list(
      sweep = sweep_df,
      bifurcation_feedback = 2 / 3,
      measured_bifurcation_feedback = measured_bif
    ),
    metadata = list(
      n = length(feedback_grid),
      feedback_grid = feedback_grid,
      params = list(
        innovation_rate = innovation_rate,
        capacity = capacity,
        n_steps = n_steps
      ),
      method = "endogenous_k_sweep",
      seed = seed,
      converged = TRUE
    )
  )

  validate_result(result)
  result
}

#' Visualize the diversity-dependence contrast
#'
#' Overlays the autocatalytic and logistic innovation trajectories (left) and
#' their per-capita-rate-vs-N slopes (right) in one figure. The DD sign flip
#' is visible: the autocatalytic per-capita rate increases with N (positive
#' slope, Homo inversion); the logistic per-capita rate decreases with N
#' (negative slope, niche-filling).
#'
#' @param contrast_result List. A [diversity_dependence_contrast()] result.
#'
#' @return A ggplot2 object (two-panel: trajectory + DD slope).
#'
#' @section Theoretical Context:
#'
#' The Homo inversion is the framework's signature theoretical contribution.
#' This visualization makes the DD sign flip — the core of the prediction —
#' visible in one figure. Both trajectories grow (positive growth direction),
#' but their per-capita-rate-vs-N slopes have opposite signs: that is the
#' Homo inversion.
#'
#' @dft A1, A6
#'
#' @export
#' @examples
#' \dontrun{
#' result <- diversity_dependence_contrast(n_steps = 20, capacity = 30)
#' plot_dd_contrast(result)
#' }
plot_dd_contrast <- function(contrast_result) {
  ac <- contrast_result$values$autocatalytic_counts
  lo <- contrast_result$values$logistic_counts
  n <- length(ac)

  # Trajectory data
  traj_df <- data.frame(
    time = rep(seq_len(n), 2),
    counts = c(ac, lo),
    model = rep(c("Autocatalytic (Homo inversion)", "Logistic (niche-filling)"),
                each = n)
  )

  # DD slope data: per-capita rate vs N
  N_prev <- c(ac[-n], lo[-n])
  pc_rate <- c(diff(ac) / pmax(ac[-n], .Machine$double.xmin),
               diff(lo) / pmax(lo[-n], .Machine$double.xmin))
  dd_df <- data.frame(
    N = N_prev,
    pc_rate = pc_rate,
    model = rep(c("Autocatalytic (Homo inversion)", "Logistic (niche-filling)"),
                each = n - 1)
  )

  # Two-panel plot
  p1 <- ggplot2::ggplot(traj_df, ggplot2::aes(x = .data$time, y = .data$counts,
                                               color = .data$model)) +
    ggplot2::geom_line(linewidth = 1) +
    ggplot2::geom_point(size = 1.5) +
    ggplot2::scale_color_manual(values = c(
      "Autocatalytic (Homo inversion)" = "#2ecc71",
      "Logistic (niche-filling)" = "#e74c3c"
    )) +
    ggplot2::labs(
      title = "Diversity-dependence contrast: Homo inversion vs niche-filling",
      subtitle = "Both trajectories grow — but DD slopes have opposite signs",
      x = "Time", y = "Innovation count"
    ) +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(legend.position = "bottom",
                   legend.title = ggplot2::element_blank())

  p2 <- ggplot2::ggplot(dd_df, ggplot2::aes(x = .data$N, y = .data$pc_rate,
                                            color = .data$model)) +
    ggplot2::geom_point(size = 2) +
    ggplot2::geom_smooth(method = "lm", se = FALSE, linewidth = 0.8) +
    ggplot2::scale_color_manual(values = c(
      "Autocatalytic (Homo inversion)" = "#2ecc71",
      "Logistic (niche-filling)" = "#e74c3c"
    )) +
    ggplot2::labs(
      subtitle = paste0("DD slope: AC = ",
                        format(contrast_result$values$autocatalytic_dd_slope, digits = 3),
                        " (positive), Log = ",
                        format(contrast_result$values$logistic_dd_slope, digits = 3),
                        " (negative)"),
      x = "Diversity N", y = "Per-capita rate (dN/dt)/N",
      caption = paste0("Contrast = ",
                       format(contrast_result$values$contrast, digits = 3),
                       " (positive = Homo inversion)")
    ) +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(legend.position = "none")

  patchwork::wrap_plots(p1, p2, ncol = 2)
}
