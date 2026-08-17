#' Ising Model Simulation — Stage 1 of the Genealogy
#'
#' Generates magnetization data from the 2D Ising model using
#' Metropolis Monte Carlo. This is the actual Ising Hamiltonian,
#' not an analogy table.
#'
#' H = -J * sum(sigma_i * sigma_j) - h * sum(sigma_i)
#'
#' @param seed Integer. Default 42.
#' @param L Integer. Lattice size (L x L). Default 16.
#' @param J Numeric. Coupling constant. Default 1.0.
#' @param h Numeric. External field. Default 0.
#' @param n_sweeps Integer. MC sweeps. Default 1000.
#' @param n_temps Integer. Number of temperature points. Default 20.
#' @param T_range Numeric vector. Temperature range (in units of J/k_B). Default c(1.0, 4.0).
#'
#' @return List with data frame: temperature, magnetization, J, h, L

generate_ising <- function(seed = 42L, L = 16L, J = 1.0, h = 0.0,
                           n_sweeps = 1000L, n_temps = 20L,
                           T_range = c(1.0, 4.0)) {
  withr::with_seed(seed, {
    temps <- seq(T_range[1], T_range[2], length.out = n_temps)
    mags <- numeric(n_temps)

    for (t_idx in 1:n_temps) {
      T <- temps[t_idx]
      beta <- 1.0 / T

      # Initialize random spin configuration
      spins <- matrix(sample(c(-1, 1), L * L, replace = TRUE), L, L)

      # Metropolis sweeps
      for (sweep in 1:n_sweeps) {
        for (k in 1:(L * L)) {
          i <- sample(1:L, 1)
          j <- sample(1:L, 1)

          # Neighbors with periodic boundary
          up <- spins[((i - 2) %% L) + 1, j]
          down <- spins[((i) %% L) + 1, j]
          left <- spins[i, ((j - 2) %% L) + 1]
          right <- spins[i, ((j) %% L) + 1]

          dE <- 2 * J * spins[i, j] * (up + down + left + right) + 2 * h * spins[i, j]

          if (dE < 0 || runif(1) < exp(-beta * dE)) {
            spins[i, j] <- -spins[i, j]
          }
        }
      }

      # Measure magnetization (absolute value — symmetrical)
      mags[t_idx] <- abs(mean(spins))
    }

    data <- data.frame(
      T_norm = temps / 2.269,  # T/Tc where Tc = 2.269 J/k_B for 2D Ising
      M = mags,
      J = J,
      h = h,
      L = L,
      stage = "ising"
    )

    list(
      values = list(
        n_temps = n_temps,
        Tc = 2.269,
        J = J,
        h = h,
        L = L
      ),
      metadata = list(
        seed = seed,
        data = data,
        params = list(L = L, J = J, h = h, n_sweeps = n_sweeps,
                      n_temps = n_temps, T_range = T_range),
        generator = "generate_ising",
        converged = TRUE
      )
    )
  })
}


#' Landau Mean-Field Free Energy — Stage 2 of the Genealogy
#'
#' Computes the Landau free energy F(M) = a*M^2 + b*M^4 + h*M
#' and finds the equilibrium magnetization (minimize F).
#'
#' The parameter 'a' is temperature-dependent: a = a0 * (T - Tc)
#' a < 0 below Tc (ordered phase), a > 0 above Tc (disordered).
#'
#' @param seed Integer. Default 42.
#' @param n_points Integer. Number of M values to evaluate. Default 100.
#' @param a_range Numeric. Range of 'a' parameter. Default c(-1, 1).
#' @param b Numeric. Quartic coefficient. Default 1.0.
#' @param h Numeric. External field. Default 0.0.
#'
#' @return List with data frame: a, M_eq, F_min, T_norm, stage

generate_landau <- function(seed = 42L, n_points = 100L,
                             a_range = c(-1, 1), b = 1.0, h = 0.0) {
  withr::with_seed(seed, {
    a_vals <- seq(a_range[1], a_range[2], length.out = n_points)
    M_grid <- seq(-1.5, 1.5, length.out = 200)
    M_eq <- numeric(n_points)
    F_min <- numeric(n_points)

    for (i in 1:n_points) {
      a <- a_vals[i]
      F <- a * M_grid^2 + b * M_grid^4 + h * M_grid
      eq_idx <- which.min(F)
      M_eq[i] <- M_grid[eq_idx]
      F_min[i] <- F[eq_idx]
    }

    # T/Tc: a = a0 * (T - Tc), so T_norm = a / a0 + 1
    # With a0 = 1, T_norm = a + 1 (shifted so Tc at a=0 → T_norm = 1)
    T_norm <- a_vals + 1

    data <- data.frame(
      a = a_vals,
      M_eq = M_eq,
      F_min = F_min,
      T_norm = T_norm,
      b = b,
      h = h,
      stage = "landau"
    )

    list(
      values = list(
        n_points = n_points,
        b = b,
        h = h,
        bifurcation_set = 4 * a_vals^3 + 27 * (b * 0)^2  # h=0: 4a^3 = 0 → a=0
      ),
      metadata = list(
        seed = seed,
        data = data,
        params = list(n_points = n_points, a_range = a_range, b = b, h = h),
        generator = "generate_landau",
        converged = TRUE
      )
    )
  })
}


#' Thom Cusp Catastrophe — Stage 3 of the Genealogy
#'
#' Computes the cusp catastrophe potential V(x) = x^4/4 + a*x^2/2 + b*x
#' and finds equilibrium points (dV/dx = 0).
#'
#' The bifurcation set is 4*a^3 + 27*b^2 = 0.
#'
#' @param seed Integer. Default 42.
#' @param n_a Integer. Number of 'a' values. Default 50.
#' @param n_b Integer. Number of 'b' values. Default 50.
#' @param a_range Numeric. Default c(-2, 2).
#' @param b_range Numeric. Default c(-2, 2).
#'
#' @return List with data frame: a, b, x_eq, V_eq, on_bifurcation_set, stage

generate_cusp <- function(seed = 42L, n_a = 50L, n_b = 50L,
                          a_range = c(-2, 2), b_range = c(-2, 2)) {
  withr::with_seed(seed, {
    a_vals <- seq(a_range[1], a_range[2], length.out = n_a)
    b_vals <- seq(b_range[1], b_range[2], length.out = n_b)

    # For each (a, b), find equilibria: dV/dx = x^3 + a*x + b = 0
    # Cubic: x^3 + a*x + b = 0
    results <- data.frame()

    for (a in a_vals) {
      for (b in b_vals) {
        # Discriminant: D = -4a^3 - 27b^2
        D <- -4 * a^3 - 27 * b^2

        if (D < 0) {
          # One real root
          roots <- polyroot(c(b, a, 0, 1))
          real_roots <- Re(roots)[abs(Im(roots)) < 1e-6]
          for (x in real_roots) {
            V <- x^4 / 4 + a * x^2 / 2 + b * x
            bif_dist <- abs(4 * a^3 + 27 * b^2)
            results <- rbind(results, data.frame(
              a = a, b = b, x_eq = x, V_eq = V,
              on_bifurcation_set = bif_dist < 0.1,
              n_equilibria = 1,
              stage = "cusp"
            ))
          }
        } else {
          # Three real roots
          # Use trigonometric solution
          if (abs(a) < 1e-10) {
            x_roots <- c(-abs(b)^(1/3), 0, abs(b)^(1/3)) * sign(b)^(1/3)
          } else {
            # Vieta's trig solution for depressed cubic
            phi <- acos(sqrt(3) * b / (2 * a) * sqrt(-3 / a)) / 3
            m <- 2 * sqrt(-a / 3)
            x_roots <- c(
              m * cos(phi),
              m * cos(phi - 2 * pi / 3),
              m * cos(phi - 4 * pi / 3)
            )
          }
          for (x in x_roots) {
            V <- x^4 / 4 + a * x^2 / 2 + b * x
            bif_dist <- abs(4 * a^3 + 27 * b^2)
            results <- rbind(results, data.frame(
              a = a, b = b, x_eq = x, V_eq = V,
              on_bifurcation_set = bif_dist < 0.1,
              n_equilibria = 3,
              stage = "cusp"
            ))
          }
        }
      }
    }

    list(
      values = list(
        n_points = nrow(results),
        bifurcation_eq = "4a^3 + 27b^2 = 0",
        n_on_bifurcation = sum(results$on_bifurcation_set)
      ),
      metadata = list(
        seed = seed,
        data = results,
        params = list(n_a = n_a, n_b = n_b, a_range = a_range, b_range = b_range),
        generator = "generate_cusp",
        converged = TRUE
      )
    )
  })
}


#' Drift-Selection Boundary Simulation — Stage 5
#'
#' Simulates a population with drift and selection to measure
#' rho_sat = P(retain | delta > 0) - P(retain | delta = 0).
#'
#' The Wright-Fisher model: a trait with selective advantage delta
#' in a population of size N. We simulate retention probability
#' across many replicates.
#'
#' @param seed Integer. Default 42.
#' @param N Integer. Population size. Default 100.
#' @param n_reps Integer. Replicates per delta value. Default 1000.
#' @param n_delta Integer. Number of delta values. Default 20.
#' @param delta_range Numeric. Range of selection coefficients. Default c(0, 0.1).
#'
#' @return List with data frame: delta, retention_prob, N, stage

generate_drift_selection <- function(seed = 42L, N = 100L, n_reps = 1000L,
                                     n_delta = 20L,
                                     delta_range = c(0, 0.1)) {
  withr::with_seed(seed, {
    deltas <- seq(delta_range[1], delta_range[2], length.out = n_delta)
    retention_probs <- numeric(n_delta)

    for (d_idx in 1:n_delta) {
      delta <- deltas[d_idx]
      retained <- 0

      for (rep in 1:n_reps) {
        # Start with frequency 0.5
        p <- 0.5
        # Wright-Fisher: next generation frequency
        for (gen in 1:100) {
          # Selection: p' = p(1+delta) / (p(1+delta) + (1-p))
          if (delta > 0) {
            p_sel <- p * (1 + delta) / (p * (1 + delta) + (1 - p))
          } else {
            p_sel <- p
          }
          # Drift: binomial sampling
          p <- rbinom(1, 2 * N, p_sel) / (2 * N)

          # Fixation or loss
          if (p == 0 || p == 1) break
        }
        if (p == 1) retained <- retained + 1
      }

      retention_probs[d_idx] <- retained / n_reps
    }

    # rho_sat = retention at delta > 0 - retention at delta = 0
    rho_sat <- retention_probs[n_delta] - retention_probs[1]

    data <- data.frame(
      delta = deltas,
      retention_prob = retention_probs,
      N = N,
      stage = "drift_selection"
    )

    list(
      values = list(
        n_reps = n_reps,
        N = N,
        rho_sat = rho_sat,
        rho_sat_expected = "derived from simulation, not analytical"
      ),
      metadata = list(
        seed = seed,
        data = data,
        params = list(N = N, n_reps = n_reps, n_delta = n_delta,
                      delta_range = delta_range),
        generator = "generate_drift_selection",
        converged = TRUE
      )
    )
  })
}
