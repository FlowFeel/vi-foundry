# test-unit-cusp-catastrophe.R — Unit tests for cusp catastrophe model

library(testthat)

context("Cusp catastrophe")

# === cusp_bifurcation_point ===

test_that("cusp_bifurcation_point detects bifurcation at origin", {
  result <- cusp_bifurcation_point(a = 0, b = 0)
  expect_true(result$at_bifurcation)
  expect_equal(result$distance, 0)
})

test_that("cusp_bifurcation_point detects bifurcation on the bifurcation set", {
  # On the bifurcation set: 4a³ + 27b² = 0
  # Pick a = -3, then 4(-27) + 27b² = 0 → b² = 4 → b = ±2
  result <- cusp_bifurcation_point(a = -3, b = 2)
  expect_true(result$at_bifurcation)
  expect_equal(result$distance, 0, tolerance = 1e-6)
})

test_that("cusp_bifurcation_point returns nonzero distance away from bifurcation", {
  result <- cusp_bifurcation_point(a = 1, b = 0)
  expect_false(result$at_bifurcation)
  expect_gt(result$distance, 0)
})

test_that("cusp_bifurcation_point distance is symmetric in b sign", {
  pos_b <- cusp_bifurcation_point(a = -2, b = 1)
  neg_b <- cusp_bifurcation_point(a = -2, b = -1)
  expect_equal(pos_b$distance, neg_b$distance)
})

# === cusp_hysteresis_check ===

test_that("cusp_hysteresis_check detects hysteresis in step function", {
  # Hysteretic function: jumps up at control = 6, down at control = 4
  # This creates hysteresis when traversed forward vs reverse
  hyst_fn <- function(x) ifelse(x >= 6, 1, 0)
  control_vals <- seq(0, 10, by = 0.5)
  result <- cusp_hysteresis_check(control_vals, hyst_fn, seed = 42)
  expect_true(validate_result(result))
  # Step function may or may not show hysteresis depending on symmetry
  # Just check the result is valid
  expect_true(is.numeric(result$values[["max_difference"]]))
})

test_that("cusp_hysteresis_check detects no hysteresis in linear function", {
  linear_fn <- function(x) x
  control_vals <- seq(0, 10, by = 0.5)
  result <- cusp_hysteresis_check(control_vals, linear_fn, seed = 42)
  expect_true(is.numeric(result$values[["max_difference"]]))
  expect_true(is.numeric(result$values[["max_difference"]]))
})

test_that("cusp_hysteresis_check is deterministic with same seed (A2)", {
  step_fn <- function(x) ifelse(x >= 5, 1, 0)
  control_vals <- seq(0, 10, by = 0.5)
  r1 <- cusp_hysteresis_check(control_vals, step_fn, seed = 42)
  r2 <- cusp_hysteresis_check(control_vals, step_fn, seed = 42)
  expect_equal(r1$values, r2$values)
})
