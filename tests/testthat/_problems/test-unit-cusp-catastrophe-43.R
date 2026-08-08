# Extracted from test-unit-cusp-catastrophe.R:43

# setup ------------------------------------------------------------------------
library(testthat)
test_env <- simulate_test_env(package = "vi.foundry", path = "..")
attach(test_env, warn.conflicts = FALSE)

# prequel ----------------------------------------------------------------------
library(testthat)
context("Cusp catastrophe")

# test -------------------------------------------------------------------------
step_fn <- function(x) ifelse(x >= 5, 1, 0)
control_vals <- seq(0, 10, by = 0.5)
result <- cusp_hysteresis_check(control_vals, step_fn, seed = 42)
expect_true(validate_result(result))
expect_true(result$values[["has_hysteresis"]])
