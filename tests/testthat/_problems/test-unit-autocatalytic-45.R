# Extracted from test-unit-autocatalytic.R:45

# setup ------------------------------------------------------------------------
library(testthat)
test_env <- simulate_test_env(package = "vi.foundry", path = "..")
attach(test_env, warn.conflicts = FALSE)

# prequel ----------------------------------------------------------------------
library(testthat)
context("Autocatalytic set")

# test -------------------------------------------------------------------------
innovations <- c("A", "B", "C", "D")
catalyst_matrix <- matrix(c(
    FALSE, TRUE, FALSE, FALSE,
    FALSE, FALSE, TRUE, FALSE,
    TRUE, FALSE, FALSE, FALSE,
    FALSE, FALSE, FALSE, FALSE
  ), nrow = 4, byrow = TRUE)
result <- autocatalytic_closure(innovations, catalyst_matrix)
expect_equal(result$values["closure_fraction"], 0.75)
