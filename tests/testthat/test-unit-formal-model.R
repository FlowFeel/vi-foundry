# test-unit-formal-model.R — Unit tests for formal model
# DFT A1: pure math, deterministic, no I/O, no RNG (A2 not needed)

library(testthat)

context("Formal model")

# === equilibrium_retention ===

test_that("equilibrium_retention returns 1.0 for protected traits (depth >= theta)", {
  expect_equal(equilibrium_retention(depth = 3, lambda = 0.15, theta = 2.5, m0 = 10, alpha = 0.05), 1.0)
  expect_equal(equilibrium_retention(depth = 2.5, lambda = 0.15, theta = 2.5, m0 = 10, alpha = 0.05), 1.0)
})

test_that("equilibrium_retention returns < 1.0 for unprotected traits", {
  val <- equilibrium_retention(depth = 0, lambda = 0.15, theta = 2.5, m0 = 10, alpha = 0.05)
  expect_lt(val, 1.0)
  expect_gt(val, 0)
})

test_that("equilibrium_retention decreases with higher lambda", {
  low_lambda <- equilibrium_retention(depth = 0, lambda = 0.01, theta = 2.5, m0 = 10, alpha = 0.05)
  high_lambda <- equilibrium_retention(depth = 0, lambda = 0.5, theta = 2.5, m0 = 10, alpha = 0.05)
  expect_lt(high_lambda, low_lambda)
})

test_that("equilibrium_retention decreases with higher mismatch", {
  low_m0 <- equilibrium_retention(depth = 0, lambda = 0.15, theta = 2.5, m0 = 1, alpha = 0.05)
  high_m0 <- equilibrium_retention(depth = 0, lambda = 0.15, theta = 2.5, m0 = 100, alpha = 0.05)
  expect_lt(high_m0, low_m0)
})

# === retention_at_time ===

test_that("retention_at_time returns 1.0 for protected traits at any time", {
  expect_equal(retention_at_time(depth = 3, lambda = 0.15, theta = 2.5, m0 = 10, alpha = 0.05, time = 50), 1.0)
  expect_equal(retention_at_time(depth = 3, lambda = 0.15, theta = 2.5, m0 = 10, alpha = 0.05, time = 1000), 1.0)
})

test_that("retention_at_time decreases over time for unprotected traits", {
  early <- retention_at_time(depth = 0, lambda = 0.15, theta = 2.5, m0 = 10, alpha = 0.05, time = 10)
  late <- retention_at_time(depth = 0, lambda = 0.15, theta = 2.5, m0 = 10, alpha = 0.05, time = 100)
  expect_lt(late, early)
})

test_that("retention_at_time approaches equilibrium as time → infinity", {
  t_large <- retention_at_time(depth = 0, lambda = 0.15, theta = 2.5, m0 = 10, alpha = 0.05, time = 10000)
  eq <- equilibrium_retention(depth = 0, lambda = 0.15, theta = 2.5, m0 = 10, alpha = 0.05)
  expect_equal(t_large, eq, tolerance = 0.01)
})

# === threshold_model (full numerical integration) ===

test_that("threshold_model returns A6 proof object", {
  result <- threshold_model(depths = c(0, 1, 2, 3, 5), lambda = 0.15,
                            theta = 2.5, m0 = 10, alpha = 0.05, time = 100)
  expect_true(validate_result(result))
  expect_equal(result$metadata$n_traits, 5)
  expect_true(result$metadata$converged)
})

test_that("threshold_model protects deep traits at 1.0", {
  depths <- c(0, 1, 2, 3, 5)
  result <- threshold_model(depths = depths, lambda = 0.15, theta = 2.5,
                            m0 = 10, alpha = 0.05, time = 100)
  # Traits at depth 3 and 5 should be protected (>= theta=2.5)
  retention <- result$values[grep("final_retention", names(result$values))]
  expect_equal(length(retention), 5)
  # Protected traits (depth 3, 5 → indices 4, 5) should be 1.0
  expect_gte(retention[4], 0.99)
  expect_gte(retention[5], 0.99)
})

test_that("threshold_model sheds unprotected traits below 1.0", {
  depths <- c(0, 1, 2, 3, 5)
  result <- threshold_model(depths = depths, lambda = 0.15, theta = 2.5,
                            m0 = 10, alpha = 0.05, time = 100)
  retention <- result$values[grep("final_retention", names(result$values))]
  # Trait at depth 0 should be most shed
  expect_lt(retention[1], 0.9)
})

test_that("threshold_model produces biphasic kinetics (k1/k2 > 1)", {
  result <- threshold_model(depths = c(0, 1, 2, 3, 5), lambda = 0.15,
                            theta = 2.5, m0 = 10, alpha = 0.05, time = 100)
  expect_gt(result$values["k1_k2_ratio"], 1)
})

test_that("threshold_model is fully deterministic (A2 — no RNG)", {
  r1 <- threshold_model(depths = c(0, 1, 2, 3, 5), lambda = 0.15,
                        theta = 2.5, m0 = 10, alpha = 0.05, time = 100)
  r2 <- threshold_model(depths = c(0, 1, 2, 3, 5), lambda = 0.15,
                        theta = 2.5, m0 = 10, alpha = 0.05, time = 100)
  expect_equal(r1$values, r2$values)
})

# === phase_transition_time ===

test_that("phase_transition_time returns positive time", {
  t <- phase_transition_time(m0 = 10, alpha = 0.05, threshold_fraction = 0.1)
  expect_gt(t, 0)
})

test_that("phase_transition_time decreases with higher alpha", {
  slow <- phase_transition_time(m0 = 10, alpha = 0.01, threshold_fraction = 0.1)
  fast <- phase_transition_time(m0 = 10, alpha = 0.1, threshold_fraction = 0.1)
  expect_lt(fast, slow)
})

test_that("phase_transition_time increases with smaller threshold fraction", {
  loose <- phase_transition_time(m0 = 10, alpha = 0.05, threshold_fraction = 0.5)
  tight <- phase_transition_time(m0 = 10, alpha = 0.05, threshold_fraction = 0.01)
  expect_gt(tight, loose)
})
