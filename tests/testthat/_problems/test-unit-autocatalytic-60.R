# Extracted from test-unit-autocatalytic.R:60

# setup ------------------------------------------------------------------------
library(testthat)
test_env <- simulate_test_env(package = "vi.foundry", path = "..")
attach(test_env, warn.conflicts = FALSE)

# prequel ----------------------------------------------------------------------
library(testthat)
context("Autocatalytic set")

# test -------------------------------------------------------------------------
counts <- c(10, 20, 30, 40, 50)
result <- diversity_dependence_sign(counts, seed = 42)
expect_true(validate_result(result))
expect_equal(result$values[["sign"]], "positive")
