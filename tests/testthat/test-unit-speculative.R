# test-unit-speculative.R — Unit tests for the speculative toy realms
#
# Tests the speculative simulation capacity (toy realms).
# DFT A1: pure math, no I/O. A2: deterministic (no RNG). A6: proof objects.
#
# This file matches the `unit` filter (run_tests.R unit).

library(testthat)

context("Speculative toy realms")

# === sweep_threshold ===

test_that("sweep_threshold returns A6 proof object", {
  result <- sweep_threshold(
    depths = c(0, 1, 2, 3, 5),
    theta_grid = seq(0, 6, by = 0.5)
  )
  expect_true(validate_result(result))
  expect_true("sweep" %in% names(result$values))
  expect_true("peak_biphasicity" %in% names(result$values))
  expect_true("peak_theta" %in% names(result$values))
})

test_that("sweep_threshold produces one row per theta value", {
  theta_grid <- seq(0, 6, by = 0.5)
  result <- sweep_threshold(depths = c(0, 1, 2, 3, 5), theta_grid = theta_grid)
  expect_equal(nrow(result$values$sweep), length(theta_grid))
  expect_equal(result$values$sweep$theta, theta_grid)
})

test_that("sweep_threshold handles all-protected edge case (theta=0)", {
  result <- sweep_threshold(depths = c(0, 1, 2, 3, 5), theta_grid = c(0, 2.5, 6))
  # theta=0: all protected, no contrast → biphasicity = 0
  expect_equal(result$values$sweep$threshold_biphasicity[[1]], 0)
  expect_equal(result$values$sweep$n_protected[[1]], 5)
  expect_equal(result$values$sweep$n_unprotected[[1]], 0)
})

test_that("sweep_threshold handles all-unprotected edge case (theta > max)", {
  result <- sweep_threshold(depths = c(0, 1, 2, 3, 5), theta_grid = c(0, 2.5, 6))
  # theta=6: all unprotected, no contrast → biphasicity = 0
  expect_equal(result$values$sweep$threshold_biphasicity[[3]], 0)
  expect_equal(result$values$sweep$n_protected[[3]], 0)
  expect_equal(result$values$sweep$n_unprotected[[3]], 5)
})

test_that("sweep_threshold shows gate opening: biphasicity rises 0 -> 1 -> 0", {
  depths <- c(0, 1, 2, 3, 5)
  result <- sweep_threshold(depths = depths, theta_grid = seq(0, 6, by = 0.25))
  bp <- result$values$sweep$threshold_biphasicity

  # At theta=0 (all protected): biphasicity ~ 0
  expect_lt(bp[[1]], 0.01)

  # At peak (gate open): biphasicity ~ 1
  expect_gt(result$values$peak_biphasicity, 0.99)

  # At theta > max(depths) (all unprotected): biphasicity ~ 0
  expect_lt(bp[[length(bp)]], 0.01)

  # The peak theta is in the interior (not at the edges)
  expect_gt(result$values$peak_theta, min(depths))
  expect_lt(result$values$peak_theta, max(depths))
})

test_that("sweep_threshold n_protected decreases as theta increases", {
  depths <- c(0, 1, 2, 3, 5)
  result <- sweep_threshold(depths = depths, theta_grid = seq(0, 6, by = 1))
  n_prot <- result$values$sweep$n_protected
  # n_protected should be monotonically non-increasing
  expect_true(all(diff(n_prot) <= 0))
})

test_that("sweep_threshold is deterministic (A2 — no RNG)", {
  r1 <- sweep_threshold(depths = c(0, 1, 2, 3, 5), theta_grid = seq(0, 6, 0.5))
  r2 <- sweep_threshold(depths = c(0, 1, 2, 3, 5), theta_grid = seq(0, 6, 0.5))
  expect_equal(r1$values$sweep, r2$values$sweep)
})

test_that("sweep_threshold metadata records params and depths", {
  depths <- c(0, 1, 2, 3, 5)
  result <- sweep_threshold(depths = depths, theta_grid = seq(0, 6, 0.5),
                            lambda = 0.2, m0 = 15)
  expect_equal(result$metadata$depths, depths)
  expect_equal(result$metadata$n_traits, 5)
  expect_equal(result$metadata$params$lambda, 0.2)
  expect_equal(result$metadata$params$m0, 15)
  expect_equal(result$metadata$method, "threshold_sweep")
})

test_that("sweep_threshold works with skewed dependency architecture", {
  # Skewed: many shallow traits, few deep
  depths_skewed <- c(0, 0, 0, 1, 5, 5)
  result <- sweep_threshold(depths = depths_skewed, theta_grid = seq(0, 6, 0.5))
  expect_true(validate_result(result))
  # Gate should still open and close
  expect_gt(result$values$peak_biphasicity, 0.99)
  expect_lt(result$values$sweep$threshold_biphasicity[[1]], 0.01)
  expect_lt(result$values$sweep$threshold_biphasicity[[nrow(result$values$sweep)]], 0.01)
})

# === plot_threshold_gate ===

test_that("plot_threshold_gate returns ggplot object", {
  result <- sweep_threshold(depths = c(0, 1, 2, 3, 5), theta_grid = seq(0, 6, 0.5))
  p <- plot_threshold_gate(result)
  expect_s3_class(p, "ggplot")
})

test_that("plot_threshold_gate maps theta to x and biphasicity to y", {
  result <- sweep_threshold(depths = c(0, 1, 2, 3, 5), theta_grid = seq(0, 6, 0.5))
  p <- plot_threshold_gate(result)
  # Check the axis labels (the plot uses .data$ pronoun, so check labels
  # rather than the mapping expression)
  expect_true(grepl("threshold", p$labels$x, ignore.case = TRUE))
  expect_true(grepl("biphasicity", p$labels$y, ignore.case = TRUE))
})

test_that("plot_threshold_gate handles single-point sweep gracefully", {
  result <- sweep_threshold(depths = c(0, 1, 2, 3, 5), theta_grid = c(2.5))
  expect_error(plot_threshold_gate(result), NA)
})

# === hysteresis_loop_area ===

.cusp_cv <- seq(-2, 2, length.out = 100)

.cusp_a_neg1 <- make_cusp_equilibrium_fn(a = -1)
.cusp_a_pos1 <- make_cusp_equilibrium_fn(a = 1)

test_that("hysteresis_loop_area returns A6 proof object", {
  result <- hysteresis_loop_area(.cusp_cv, .cusp_a_neg1)
  expect_true(validate_result(result))
  expect_true("loop_area" %in% names(result$values))
  expect_true("max_difference" %in% names(result$values))
  expect_true("has_hysteresis" %in% names(result$values))
})

test_that("hysteresis_loop_area is 0 for a=1 (no bifurcation)", {
  result <- hysteresis_loop_area(.cusp_cv, .cusp_a_pos1)
  expect_equal(result$values$loop_area, 0, tolerance = 1e-10)
  expect_false(result$values$has_hysteresis)
})

test_that("hysteresis_loop_area is > 0 for a=-1 (cusp region)", {
  result <- hysteresis_loop_area(.cusp_cv, .cusp_a_neg1)
  expect_gt(result$values$loop_area, 0.5)
  expect_true(result$values$has_hysteresis)
})

test_that("hysteresis_loop_area is deterministic (A2)", {
  r1 <- hysteresis_loop_area(.cusp_cv, .cusp_a_neg1)
  r2 <- hysteresis_loop_area(.cusp_cv, .cusp_a_neg1)
  expect_equal(r1$values, r2$values)
})

test_that("hysteresis_loop_area is robust to initial_state", {
  # The loop area is the same regardless of which branch you start on
  r0 <- hysteresis_loop_area(.cusp_cv, .cusp_a_neg1, initial_state = 0)
  r1 <- hysteresis_loop_area(.cusp_cv, .cusp_a_neg1, initial_state = 1.0)
  r2 <- hysteresis_loop_area(.cusp_cv, .cusp_a_neg1, initial_state = -1.0)
  expect_equal(r0$values$loop_area, r1$values$loop_area, tolerance = 1e-6)
  expect_equal(r0$values$loop_area, r2$values$loop_area, tolerance = 1e-6)
})

# === sweep_cusp_irreversibility ===

test_that("sweep_cusp_irreversibility returns A6 proof object", {
  result <- sweep_cusp_irreversibility(
    a_grid = seq(1, -2, by = -0.5),
    control_values = .cusp_cv
  )
  expect_true(validate_result(result))
  expect_true("sweep" %in% names(result$values))
  expect_true("peak_loop_area" %in% names(result$values))
  expect_true("bifurcation_a" %in% names(result$values))
})

test_that("sweep_cusp_irreversibility produces one row per a value", {
  a_grid <- seq(1, -2, by = -0.5)
  result <- sweep_cusp_irreversibility(a_grid = a_grid, control_values = .cusp_cv)
  expect_equal(nrow(result$values$sweep), length(a_grid))
  expect_equal(result$values$sweep$a, a_grid)
})

test_that("sweep shows loop area = 0 for a >= 0 (no bifurcation)", {
  result <- sweep_cusp_irreversibility(
    a_grid = c(1, 0.5, 0),
    control_values = .cusp_cv
  )
  expect_true(all(result$values$sweep$loop_area < 1e-10))
  expect_false(any(result$values$sweep$has_hysteresis))
})

test_that("sweep shows loop area rising for a < 0 (cusp region)", {
  result <- sweep_cusp_irreversibility(
    a_grid = seq(1, -2, by = -0.25),
    control_values = .cusp_cv
  )
  df <- result$values$sweep
  # The peak loop area should be at the most negative a
  expect_lt(result$values$peak_a, -1.5)
  # Some a < 0 values should have loop area > 0
  cusp_rows <- df[df$a < -0.5, ]
  expect_true(any(cusp_rows$loop_area > 0.1))
})

test_that("loop area is monotonic in |a| for a < 0", {
  result <- sweep_cusp_irreversibility(
    a_grid = seq(-0.1, -2, by = -0.1),
    control_values = .cusp_cv
  )
  df <- result$values$sweep
  # As a becomes more negative (|a| increases), loop area should be
  # monotonically non-decreasing
  expect_true(all(diff(df$loop_area) >= -1e-10))
})

test_that("sweep_cusp_irreversibility is deterministic (A2)", {
  r1 <- sweep_cusp_irreversibility(a_grid = seq(1, -1, by = -0.5),
                                    control_values = .cusp_cv)
  r2 <- sweep_cusp_irreversibility(a_grid = seq(1, -1, by = -0.5),
                                    control_values = .cusp_cv)
  expect_equal(r1$values$sweep, r2$values$sweep)
})

# === plot_irreversibility_sweep ===

test_that("plot_irreversibility_sweep returns ggplot object", {
  result <- sweep_cusp_irreversibility(
    a_grid = seq(1, -2, by = -0.5),
    control_values = .cusp_cv
  )
  p <- plot_irreversibility_sweep(result)
  expect_s3_class(p, "ggplot")
})

test_that("plot_irreversibility_sweep maps a to x and loop_area to y", {
  result <- sweep_cusp_irreversibility(
    a_grid = seq(1, -2, by = -0.5),
    control_values = .cusp_cv
  )
  p <- plot_irreversibility_sweep(result)
  expect_true(grepl("a", p$labels$x, ignore.case = TRUE))
  expect_true(grepl("area", p$labels$y, ignore.case = TRUE))
})
