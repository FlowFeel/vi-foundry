# generate_cusp_system.R — Simulacrum synthetic data generator
#
# Generates a synthetic cusp catastrophe system near a known bifurcation
# point. The cusp catastrophe has equilibrium condition:
#   x³ + a·x + b = 0
# where x is the state variable, and (a, b) are control parameters.
# Bifurcation set: 4a³ + 27b² = 0
#
# For a < 0 and |b| < 2·(a/3)^(3/2), the system has three real roots
# (two stable, one unstable). Crossing the bifurcation set causes a fold
# bifurcation — the stable equilibrium disappears, forcing a sudden jump.
#
# DFT A1: pure function, no file I/O, no side effects
# DFT A2: deterministic — seed injected, never hidden
#
# @param a Numeric. First control parameter (splitting factor). Default -1.
#   For a < 0 the system is in the cusp region.
# @param b_range Numeric vector of length 2. Range for the second control
#   parameter (normal factor). Default c(-2, 2).
# @param n Integer. Number of points to generate. Default 100.
# @param seed Integer. Seed for reproducibility. Default 42.
# @param noise_sd Numeric. Standard deviation of Gaussian noise. Default 0.05.
#
# @return data.frame with columns:
#   - control_a: first control parameter
#   - control_b: second control parameter
#   - state: equilibrium state (with noise)
#   - state_true: equilibrium state before noise
#   - n_real_roots: number of real equilibrium roots at this parameter point
#   - bifurcation_distance: value of 4a³ + 27b² (0 = at bifurcation)
#
# @examples
#
# @dft A1, A2

#' @export
generate_cusp_system <- function(a = -1,
                                 b_range = c(-2, 2),
                                 n = 100L,
                                 seed = 42L,
                                 noise_sd = 0.05) {
  withr::with_seed(seed, {
    b_vals <- seq(b_range[1], b_range[2], length.out = n)

    states_true <- numeric(n)
    n_roots <- integer(n)

    for (i in seq_len(n)) {
      b <- b_vals[i]
      # Solve cubic: x³ + a·x + b = 0
      roots <- polyroot(c(b, a, 0, 1))
      real_roots <- Re(roots)[abs(Im(roots)) < 1e-10]

      n_roots[i] <- length(real_roots)

      if (length(real_roots) == 0) {
        # Should not happen for real coefficients (at least 1 real root)
        states_true[i] <- Re(roots[1])
      } else if (length(real_roots) == 1) {
        # Single real root — unique stable equilibrium
        states_true[i] <- real_roots[1]
      } else {
        # Three real roots — pick the upper branch (stable equilibrium)
        # For a < 0, the outer roots are stable, the middle is unstable
        # Pick the positive stable branch (upper)
        stable_roots <- c(real_roots[1], real_roots[3])
        states_true[i] <- max(stable_roots)
      }
    }

    states <- states_true + rnorm(n, 0, noise_sd)
    bifurcation_distance <- 4 * a^3 + 27 * b_vals^2

    data.frame(
      control_a = a,
      control_b = b_vals,
      state = states,
      state_true = states_true,
      n_real_roots = n_roots,
      bifurcation_distance = bifurcation_distance,
      noise_sd = noise_sd,
      stringsAsFactors = FALSE
    )
  })
}

#' Create a stateful equilibrium function for hysteresis detection
#'
#' Wraps the cusp equilibrium solver with a stateful branch-following
#' behavior. The function tracks the previous equilibrium state and
#' selects the nearest stable equilibrium, simulating the path-dependent
#' behavior of a real cusp catastrophe system.
#'
#' @param a Numeric. First control parameter (splitting factor).
#' @param initial_state Numeric. Initial state for the first call.
#'   Default 0.
#'
#' @return Function that takes a single numeric argument (control_b)
#'   and returns the equilibrium state, following the nearest branch.
#'
#' @keywords internal
make_cusp_equilibrium_fn <- function(a = -1, initial_state = 0) {
  state <- initial_state
  function(b) {
    roots <- polyroot(c(b, a, 0, 1))
    real_roots <- Re(roots)[abs(Im(roots)) < 1e-10]
    if (length(real_roots) == 1) {
      state <<- real_roots[1]
    } else {
      # Pick the real root closest to the previous state
      state <<- real_roots[which.min(abs(real_roots - state))]
    }
    state
  }
}
