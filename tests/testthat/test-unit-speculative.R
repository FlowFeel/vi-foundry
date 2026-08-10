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
