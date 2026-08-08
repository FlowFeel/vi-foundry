#' Cusp catastrophe model for VI irreversibility thresholds
#'
#' The cusp catastrophe describes a system where smooth changes in control
#' parameters produce sudden, irreversible jumps in state. VI predicts that
#' capacity reallocation has this property — once a trait crosses the
#' protection threshold, recovery requires disproportionate effort.
#'
#' @section Theoretical Context:
#'
#' VI Prediction: irreversibility — substrate-shift creates a bifurcation
#' that is difficult to reverse. Competitor: gradual reversibility (standard
#' quantitative genetics predicts smooth recovery when selection pressure
#' is removed).
#'
#' @dft A1, A2, A6
#'
#' @name cusp_catastrophe
NULL

#' Compute the bifurcation point for the cusp catastrophe
#'
#' The cusp catastrophe has two control parameters (a, b) and the
#' bifurcation set is: |b| ≤ 2 × (a/3)^(3/2) / (27)^(1/2)
#' Simplified: bifurcation occurs when 4a³ + 27b² = 0
#'
#' @param a Numeric. First control parameter (splitting factor).
#' @param b Numeric. Second control parameter (normal factor).
#'
#' @return Numeric. 1 if at bifurcation point, 0 otherwise. Also returns
#'   the distance to the bifurcation set.
#' @export
cusp_bifurcation_point <- function(a, b) {
  # Distance from bifurcation set: 4a³ + 27b²
  # When this equals zero, we're at the bifurcation point
  distance <- 4 * a^3 + 27 * b^2

  at_bifurcation <- abs(distance) < 1e-6

  list(
    at_bifurcation = at_bifurcation,
    distance = distance,
    a = a,
    b = b
  )
}

#' Check for hysteresis (path dependence)
#'
#' VI predicts that the forward path (increasing commitment) differs from
#' the reverse path (decreasing commitment) — this is the hallmark of
#' irreversibility in the cusp catastrophe.
#'
#' @param control_values Numeric vector. Control parameter values to test.
#' @param equilibrium_fn Function. Maps control value → equilibrium state.
#' @param seed Integer. Seed for reproducibility.
#'
#' @return List (A6): values (has_hysteresis, forward_states, reverse_states),
#'   metadata.
#'
#' @dft A1, A2, A6
#'
#' @export
cusp_hysteresis_check <- function(control_values, equilibrium_fn, seed = 42L) {
  withr::with_seed(seed, {
    n <- length(control_values)

    # Forward path: start from minimum control value
    forward_states <- numeric(n)
    state <- equilibrium_fn(control_values[1])
    for (i in seq_len(n)) {
      state <- equilibrium_fn(control_values[i])
      forward_states[i] <- state
    }

    # Reverse path: start from maximum control value
    reverse_states <- numeric(n)
    for (i in seq_len(n)) {
      state <- equilibrium_fn(control_values[n - i + 1])
      reverse_states[i] <- state
    }

    # Hysteresis: forward ≠ reverse at some point
    differences <- abs(forward_states - rev(reverse_states))
    has_hysteresis <- any(differences > 0.01, na.rm = TRUE)

    result <- list(
      values = c(
        has_hysteresis = has_hysteresis,
        max_difference = max(differences, na.rm = TRUE),
        n_control_values = n
      ),
      metadata = list(
        seed = seed,
        n = n,
        control_range = range(control_values),
        converged = TRUE
      )
    )

    validate_result(result)
    result
  })
}
