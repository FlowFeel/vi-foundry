# Extracted from test-unit-autocatalytic.R:74

# setup ------------------------------------------------------------------------
library(testthat)
test_env <- simulate_test_env(package = "vi.foundry", path = "..")
attach(test_env, warn.conflicts = FALSE)

# prequel ----------------------------------------------------------------------
library(testthat)
context("Autocatalytic set")

# test -------------------------------------------------------------------------
counts <- c(1, 4, 9, 16, 25, 36)
result <- diversity_dependence_sign(counts, seed = 42)
expect_true(result$values["is_superlinear"])
