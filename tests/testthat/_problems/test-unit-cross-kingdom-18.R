# Extracted from test-unit-cross-kingdom.R:18

# setup ------------------------------------------------------------------------
library(testthat)
test_env <- simulate_test_env(package = "vi.foundry", path = "..")
attach(test_env, warn.conflicts = FALSE)

# prequel ----------------------------------------------------------------------
library(testthat)
context("Cross-kingdom transfer")

# test -------------------------------------------------------------------------
data <- data.frame(
    category = c("ndh", "rpo", "psa", "psb", "atp", "rpl_rps"),
    dependency_score = c(0, 1, 1, 2, 3, 5),
    orobanchaceae_loss_rank = c(1, 2, 3, 4, 5, 6)
  )
result <- fit_plant_model(data, seed = 42)
expect_true(validate_result(result))
expect_gt(result$values[["slope"]], 0)
expect_equal(result$values[["r_squared"]], 1, tolerance = 0.01)
