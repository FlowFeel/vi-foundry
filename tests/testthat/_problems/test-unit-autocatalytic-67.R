# Extracted from test-unit-autocatalytic.R:67

# setup ------------------------------------------------------------------------
library(testthat)
test_env <- simulate_test_env(package = "vi.foundry", path = "..")
attach(test_env, warn.conflicts = FALSE)

# prequel ----------------------------------------------------------------------
library(testthat)
context("Autocatalytic set")

# test -------------------------------------------------------------------------
counts <- c(50, 40, 30, 20, 10)
result <- diversity_dependence_sign(counts, seed = 42)
expect_equal(result$values[["sign"]], "negative")
