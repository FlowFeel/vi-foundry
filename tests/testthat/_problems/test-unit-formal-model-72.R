# Extracted from test-unit-formal-model.R:72

# setup ------------------------------------------------------------------------
library(testthat)
test_env <- simulate_test_env(package = "vi.foundry", path = "..")
attach(test_env, warn.conflicts = FALSE)

# prequel ----------------------------------------------------------------------
library(testthat)
context("Formal model")

# test -------------------------------------------------------------------------
depths <- c(0, 1, 2, 3, 5)
result <- threshold_model(
    depths = depths, lambda = 0.15, theta = 2.5,
    m0 = 10, alpha = 0.05, time = 100
  )
retention <- result$values[grep("final_retention", names(result$values))]
expect_equal(length(retention), 5)
