# Extracted from test-unit-empirical-tests.R:78

# setup ------------------------------------------------------------------------
library(testthat)
test_env <- simulate_test_env(package = "vi.foundry", path = "..")
attach(test_env, warn.conflicts = FALSE)

# prequel ----------------------------------------------------------------------
library(testthat)
context("Empirical tests (T1–T7)")

# test -------------------------------------------------------------------------
result <- ltee_cosegregation(seed = 42)
expect_true(validate_result(result))
expect_equal(result$values[["observed_pct"]], c(observed_pct = 36.4))
expect_equal(result$values[["expected_pct"]], c(expected_pct = 61.7))
