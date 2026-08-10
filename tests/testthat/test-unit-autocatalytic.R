# test-unit-autocatalytic.R — Unit tests for autocatalytic set

library(testthat)

context("Autocatalytic set")

# === autocatalytic_closure ===

test_that("autocatalytic_closure detects complete closure", {
  innovations <- c("A", "B", "C")
  # Each catalyzed by at least one other
  catalyst_matrix <- matrix(c(
    FALSE, TRUE, FALSE,
    FALSE, FALSE, TRUE,
    TRUE, FALSE, FALSE
  ), nrow = 3, byrow = TRUE)
  result <- autocatalytic_closure(innovations, catalyst_matrix)
  expect_true(validate_result(result))
  expect_true(result$values[["achieves_closure"]])
  expect_equal(result$values[["n_catalyzed"]], 3)
})

test_that("autocatalytic_closure detects incomplete closure", {
  innovations <- c("A", "B", "C")
  # C is not catalyzed by anyone
  catalyst_matrix <- matrix(c(
    FALSE, TRUE, FALSE,
    FALSE, FALSE, FALSE,
    TRUE, FALSE, FALSE
  ), nrow = 3, byrow = TRUE)
  result <- autocatalytic_closure(innovations, catalyst_matrix)
  expect_false(result$values[["achieves_closure"]])
  expect_equal(result$values[["n_catalyzed"]], 2)
})

test_that("autocatalytic_closure returns closure fraction", {
  innovations <- c("A", "B", "C", "D")
  catalyst_matrix <- matrix(c(
    FALSE, TRUE, FALSE, FALSE,
    FALSE, FALSE, TRUE, FALSE,
    TRUE, FALSE, FALSE, FALSE,
    FALSE, FALSE, FALSE, FALSE
  ), nrow = 4, byrow = TRUE)
  result <- autocatalytic_closure(innovations, catalyst_matrix)
  expect_equal(result$values[["closure_fraction"]], 0.75)
})

test_that("autocatalytic_closure errors on mismatched dimensions", {
  innovations <- c("A", "B")
  catalyst_matrix <- matrix(FALSE, nrow = 3, ncol = 3)
  expect_error(autocatalytic_closure(innovations, catalyst_matrix), "n×n")
})

# === diversity_dependence_sign ===

test_that("diversity_dependence_sign detects positive trend", {
  counts <- c(10, 20, 30, 40, 50)
  result <- diversity_dependence_sign(counts, seed = 42)
  expect_true(validate_result(result))
  expect_equal(result$values[["growth_direction"]], "positive")
  expect_gt(result$values[["growth_slope"]], 0)
})

test_that("diversity_dependence_sign detects negative trend", {
  counts <- c(50, 40, 30, 20, 10)
  result <- diversity_dependence_sign(counts, seed = 42)
  expect_equal(result$values[["growth_direction"]], "negative")
  expect_lt(result$values[["growth_slope"]], 0)
})

test_that("diversity_dependence_sign detects superlinear growth", {
  counts <- c(1, 4, 9, 16, 25, 36) # quadratic
  result <- diversity_dependence_sign(counts, seed = 42)
  expect_true(result$values[["is_superlinear"]])
})

test_that("diversity_dependence_sign computes genuine diversity-dependence", {
  # Linear growth: per-capita rate = k/N decreases with N -> negative DD
  lin <- 3 * seq_len(20)
  r_lin <- diversity_dependence_sign(lin, seed = 42)
  expect_equal(r_lin$values[["diversity_dependence_sign"]], "negative")
  # Exponential growth: per-capita rate constant -> DD slope ~ 0 (not positive)
  exp_counts <- round(exp(0.3 * seq_len(20)))
  r_exp <- diversity_dependence_sign(exp_counts, seed = 42)
  expect_true(r_exp$values[["diversity_dependence_slope"]] < 0.01)
})

test_that("diversity_dependence_sign is deterministic with same seed (A2)", {
  counts <- c(10, 20, 30, 40, 50)
  r1 <- diversity_dependence_sign(counts, seed = 42)
  r2 <- diversity_dependence_sign(counts, seed = 42)
  expect_equal(r1$values, r2$values)
})
