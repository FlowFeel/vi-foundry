#' Generate step-function synthetic data (Simulacrum 6: Step Recovery)
#'
#' Generates synthetic (theta, rho) data from a known Heaviside step function:
#'   rho = rho_sat * H(theta - theta_star)
#'
#' Tests whether the pipeline can recover the step parameters from noisy data
#' and distinguish a step from a steep sigmoid.
#'
#' @section Theoretical Context:
#'
#' VI Formula: rho(theta) = rho_sat * H(theta - theta_star)
#'   - theta_star = 0 (proposed from percolation theory)
#'   - rho_sat = 0.35 (empirically observed, proposed as drift-selection boundary)
#'
#' This simulacrum tests:
#' 1. Can the pipeline recover rho_sat = 0.35 from noisy step data?
#' 2. Can it recover theta_star = 0?
#' 3. Can it distinguish a step (s -> Inf) from a steep sigmoid (s = 10)?
#'
#' Competitors:
#' - Sigmoid: rho = rho_sat / (1 + exp(-s * (theta - theta_star)))
#' - Linear: rho = slope * theta + intercept
#' - The step function should win on AIC when data is generated from a step
#'
#' @param seed Integer. Default 42.
#' @param n_pre Integer. Number of pre-threshold data points. Default 10.
#' @param n_post Integer. Number of post-threshold data points. Default 10.
#' @param rho_sat Numeric. True saturation value. Default 0.35.
#' @param theta_star Numeric. True threshold. Default 0.
#' @param noise_sd Numeric. SD of Gaussian noise on rho. Default 0.02.
#'
#' @return List (A6 proof object):
#'   \item{values}{Named: n, true_rho_sat, true_theta_star, true_noise}
#'   \item{metadata}{List: seed, data (data.frame with theta, rho, model="step"),
#'     params, generator, converged}
#'
#' @section DFT Axioms:
#' - A1 (pure-io-separation): pure function, no file I/O
#' - A2 (determinism): seed injected via withr::with_seed
#' - A6 (check-result): returns proof object with values + metadata

generate_step_function <- function(seed = 42L, n_pre = 10L, n_post = 10L,
                                    rho_sat = 0.35, theta_star = 0,
                                    noise_sd = 0.02) {
  withr::with_seed(seed, {
    theta_pre <- seq(-1, theta_star - 0.01, length.out = n_pre)
    theta_post <- seq(theta_star + 0.01, 1, length.out = n_post)
    theta <- c(theta_pre, theta_post)
    rho_true <- c(rep(0, n_pre), rep(rho_sat, n_post))
    rho <- rho_true + rnorm(length(theta), 0, noise_sd)
    rho <- pmax(0, pmin(1, rho))

    data <- data.frame(
      theta = theta,
      rho = rho,
      model = "step"
    )

    list(
      values = list(
        n = n_pre + n_post,
        true_rho_sat = rho_sat,
        true_theta_star = theta_star,
        true_noise = noise_sd
      ),
      metadata = list(
        seed = seed,
        data = data,
        params = list(
          n_pre = n_pre, n_post = n_post,
          rho_sat = rho_sat, theta_star = theta_star,
          noise_sd = noise_sd
        ),
        generator = "generate_step_function",
        converged = TRUE
      )
    )
  })
}


#' Generate steep-sigmoid synthetic data (Simulacrum 6 null/competitor)
#'
#' Generates synthetic (theta, rho) data from a steep sigmoid:
#'   rho = rho_sat / (1 + exp(-s * (theta - theta_star)))
#'
#' Used to test whether the pipeline can DISTINGUISH a step from a steep
#' sigmoid. If the pipeline reports "step" on sigmoid data, it's a false
#' positive for the step model.
#'
#' @param seed Integer. Default 42.
#' @param n Integer. Total data points. Default 20.
#' @param rho_sat Numeric. Saturation value. Default 0.35.
#' @param theta_star Numeric. Midpoint. Default 0.
#' @param s Numeric. Steepness. Default 10 (steep but finite).
#' @param noise_sd Numeric. SD of Gaussian noise. Default 0.02.
#'
#' @return List (A6 proof object, same structure as generate_step_function)

generate_steep_sigmoid <- function(seed = 42L, n = 20L,
                                    rho_sat = 0.35, theta_star = 0,
                                    s = 10, noise_sd = 0.02) {
  withr::with_seed(seed, {
    theta <- seq(-1, 1, length.out = n)
    rho_true <- rho_sat / (1 + exp(-s * (theta - theta_star)))
    rho <- rho_true + rnorm(n, 0, noise_sd)
    rho <- pmax(0, pmin(1, rho))

    data <- data.frame(
      theta = theta,
      rho = rho,
      model = "sigmoid"
    )

    list(
      values = list(
        n = n,
        true_rho_sat = rho_sat,
        true_theta_star = theta_star,
        true_s = s,
        true_noise = noise_sd
      ),
      metadata = list(
        seed = seed,
        data = data,
        params = list(
          n = n, rho_sat = rho_sat, theta_star = theta_star,
          s = s, noise_sd = noise_sd
        ),
        generator = "generate_steep_sigmoid",
        converged = TRUE
      )
    )
  })
}


#' Generate null data (no signal) for Simulacrum 6
#'
#' Generates synthetic (theta, rho) data with no step, no sigmoid — just
#' noise around a constant. Tests whether the pipeline produces false
#' positives when no signal exists.
#'
#' @param seed Integer. Default 42.
#' @param n Integer. Total data points. Default 20.
#' @param rho_baseline Numeric. Constant baseline. Default 0.35.
#' @param noise_sd Numeric. SD of Gaussian noise. Default 0.05.
#'
#' @return List (A6 proof object)

generate_null_rho <- function(seed = 42L, n = 20L,
                               rho_baseline = 0.35, noise_sd = 0.05) {
  withr::with_seed(seed, {
    theta <- seq(-1, 1, length.out = n)
    rho <- rep(rho_baseline, n) + rnorm(n, 0, noise_sd)
    rho <- pmax(0, pmin(1, rho))

    data <- data.frame(
      theta = theta,
      rho = rho,
      model = "null"
    )

    list(
      values = list(
        n = n,
        true_rho_sat = 0,  # no signal
        true_theta_star = NA,  # no threshold
        true_noise = noise_sd
      ),
      metadata = list(
        seed = seed,
        data = data,
        params = list(n = n, rho_baseline = rho_baseline, noise_sd = noise_sd),
        generator = "generate_null_rho",
        converged = TRUE
      )
    )
  })
}


#' Generate percolation network data (Simulacrum 7: Percolation Threshold)
#'
#' Generates a synthetic dependency network and tests whether the percolation
#' threshold is at zero provision (theta_star = 0) for a connected network.
#'
#' The generative model:
#'   - Network G = (V, E) is a connected random graph
#'   - Each node has a dependency set (its neighbors)
#'   - A provision set S is a random subset of V
#'   - The zero-dependency set Z = {v : dependency_set(v) ⊆ S}
#'   - |Z| / |V| is the order parameter
#'
#' For a connected network, ANY non-empty S should produce non-empty Z
#' (proposed but not formally proven — this simulacrum tests it empirically).
#'
#' @param seed Integer. Default 42.
#' @param n_nodes Integer. Number of nodes. Default 100.
#' @param p_edge Numeric. Edge probability for Erdos-Renyi. Default 0.1.
#' @param n_provision_levels Integer. Number of provision levels to test. Default 20.
#'
#' @return List (A6 proof object)

generate_percolation_network <- function(seed = 42L, n_nodes = 100L,
                                          p_edge = 0.1,
                                          n_provision_levels = 20L) {
  withr::with_seed(seed, {
    # Generate connected Erdos-Renyi graph
    adj <- matrix(0, n_nodes, n_nodes)
    for (i in 1:(n_nodes - 1)) {
      for (j in (i + 1):n_nodes) {
        if (runif(1) < p_edge) {
          adj[i, j] <- 1
          adj[j, i] <- 1
        }
      }
    }
    # Ensure connectivity: add a chain if disconnected
    for (i in 1:(n_nodes - 1)) {
      if (adj[i, i + 1] == 0) {
        adj[i, i + 1] <- 1
        adj[i + 1, i] <- 1
      }
    }

    # Dependency set for each node = its neighbors
    dep_sets <- lapply(1:n_nodes, function(i) which(adj[i, ] == 1))

    # Test provision levels from 1 node to all nodes
    provision_sizes <- round(seq(1, n_nodes, length.out = n_provision_levels))
    zero_dep_fractions <- numeric(n_provision_levels)

    for (k in 1:n_provision_levels) {
      S <- sample(1:n_nodes, provision_sizes[k])
      # Z = nodes whose entire dependency set is in S
      Z <- sapply(1:n_nodes, function(v) {
        deps <- dep_sets[[v]]
        if (length(deps) == 0) return(TRUE)  # isolated node
        all(deps %in% S)
      })
      zero_dep_fractions[k] <- sum(Z) / n_nodes
    }

    # theta = provision fraction, rho = zero-dependency fraction
    theta <- provision_sizes / n_nodes
    rho <- zero_dep_fractions

    data <- data.frame(
      theta = theta,
      rho = rho,
      provision_size = provision_sizes,
      model = "percolation"
    )

    # Check: is theta_star = 0? (first non-zero provision should give non-zero Z)
    first_Z <- rho[1]
    theta_star_est <- if (first_Z > 0) 0 else theta[which(rho > 0)[1]]

    list(
      values = list(
        n_nodes = n_nodes,
        n_provision_levels = n_provision_levels,
        theta_star_est = theta_star_est,
        first_provision_Z = first_Z,
        is_connected = TRUE,
        network_density = sum(adj) / (n_nodes * (n_nodes - 1))
      ),
      metadata = list(
        seed = seed,
        data = data,
        params = list(n_nodes = n_nodes, p_edge = p_edge,
                      n_provision_levels = n_provision_levels),
        generator = "generate_percolation_network",
        converged = TRUE
      )
    )
  })
}
