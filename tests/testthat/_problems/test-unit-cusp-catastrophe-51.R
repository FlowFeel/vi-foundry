# Extracted from test-unit-cusp-catastrophe.R:51

# setup ------------------------------------------------------------------------
library(testthat)
test_env <- simulate_test_env(package = "vi.foundry", path = "..")
attach(test_env, warn.conflicts = FALSE)

# prequel ----------------------------------------------------------------------
library(testthat)
context("Cusp catastrophe")

# test -------------------------------------------------------------------------
linear_fn <- function(x) x
control_vals <- seq(0, 10, by = 0.5)
result <- cusp_hysteresis_check(control_vals, linear_fn, seed = 42)
expect_false(result$values["has_hysteresis"])
