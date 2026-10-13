# test-simulacrum-assemblage.R — Simulacra: production-bias parameter recovery
#
# STDD: synthetic data with known ground truth -> does the pipeline recover it?
# Question: given a simulated diversity cycle (Figs 6/8/9 style), can we recover
# the k trajectory that generated it? And does the LBK/WTC empirical series
# reject the null model (no production bias)?

library(testthat)

context("Simulacrum: assemblage diversity parameter recovery")

# --- Helper: fit k from a simulated trajectory ----------------------------------
# The update renormalizes, so k is not directly observable from proportions;
# but the diversity trajectory's shape carries k's signature. Recovery uses
# the stability-threshold relation: at constant p_primary, r_stab = k·C/(C−p/k).
# We recover k by grid search minimizing RMSE between simulated and
# re-simulated diversity trajectories.

.recover_k <- function(p0, r, k_true, C = 1, k_grid = seq(0.55, 2.0, by = 0.05)) {
  # Search is restricted to the viable regime: k must stay above the dominant
  # type's proportion (paper Eq 4 constraint p/k <= C), or the assemblage
  # collapses to a singularity.
  stopifnot(max(p0) < min(k_grid))
  n_steps <- 8
  k_t <- rep(k_true, n_steps)
  sim <- dg_simulate_cycle(p0, r, k_t, C = C)
  div_true <- sim$diversity
  errs <- vapply(k_grid, function(k) {
    s <- dg_simulate_cycle(p0, r, rep(k, n_steps), C = C)
    sqrt(mean((s$diversity - div_true)^2))
  }, numeric(1))
  k_grid[which.min(errs)]
}

test_that("k recovery: k=1.1 recovered from simulated trajectory", {
  p0 <- c(A = 0.5, B = 0.25, C = 0.125, D = 0.125)
  r <- c(A = 3.6, B = 1.73, C = 1.73, D = 1.73)
  k_hat <- .recover_k(p0, r, k_true = 1.1)
  expect_equal(k_hat, 1.1, tolerance = 0.15)
})

test_that("k recovery: k=0.7 (declining production) recovered", {
  p0 <- c(A = 0.5, B = 0.25, C = 0.125, D = 0.125)
  r <- c(A = 3.6, B = 1.73, C = 1.73, D = 1.73)
  k_hat <- .recover_k(p0, r, k_true = 0.7)
  expect_equal(k_hat, 0.7, tolerance = 0.15)
})

test_that("dg_simulate_cycle: diversity rises then falls under production growth", {
  # Fig 6 pattern: production growth (k: 1 -> 2) raises diversity past the
  # equilibrium, then renormalization forces the decline. k is bounded <= 2
  # (paper Eq 4); the Fig 6 'scaled production' column > 2 is the population
  # proxy, not k.
  p0 <- c(A = 0.1, B = 0.8, C = 0.05, D = 0.05)
  r <- c(A = 3.6, B = 1.73, C = 1.73, D = 1.73)
  k_t <- c(1.0, 1.2, 1.4, 1.6, 1.8, 2.0, 1.8, 1.6)
  sim <- dg_simulate_cycle(p0, r, k_t)
  expect_equal(nrow(sim), 8)
  expect_equal(sim$diversity[1], 2.0306309908905886, tolerance = 1e-9)
  # Diversity peaks mid-cycle then declines (rise-and-fall signature)
  peak <- which.max(sim$diversity)
  expect_gt(peak, 1)
  expect_lt(peak, 8)
})

test_that("null control: flat k (k=1 constant production) yields no forced cycle", {
  # r_alpha at the stability threshold and r_B=4 (Eq 3 constraint): proportions
  # stay flat, so diversity is constant. This is the null: no cycle without a
  # k-trajectory / bias driver.
  p0 <- c(A = 0.25, B = 0.75)
  r <- c(A = dg_stability_threshold(0.25, 1.0, 1), B = 4)
  sim <- dg_simulate_cycle(p0, r, rep(1.0, 10))
  expect_equal(sim$diversity, rep(1.754865, 10), tolerance = 1e-4)
})