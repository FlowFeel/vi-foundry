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
#' @return List with data frame: T_norm, M, J, h, L

generate_ising <- function(seed = 42L, L = 16L, J = 1.0, h = 0.0,
                           n_sweeps = 1000L, n_temps = 20L,
                           T_range = c(1.0, 4.0)) {
  withr::with_seed(seed, {
    temps <- seq(T_range[1], T_range[2], length.out = n_temps)
    mags <- numeric(n_temps)

    for (t_idx in 1:n_temps) {
      T <- temps[t_idx]
      beta <- 1.0 / T

      spins <- matrix(sample(c(-1, 1), L * L, replace = TRUE), L, L)

      for (sweep in 1:n_sweeps) {
        for (k in 1:(L * L)) {
          i <- sample(1:L, 1)
          j <- sample(1:L, 1)

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

      mags[t_idx] <- abs(mean(spins))
    }

    data <- data.frame(
      T_norm = temps / 2.269,
      M = mags,
      J = J,
      h = h,
      L = L,
      stage = "ising"
    )

    list(
      values = list(n_temps = n_temps, Tc = 2.269, J = J, h = h, L = L),
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
