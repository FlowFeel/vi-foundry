# Extracted from test-unit-empirical-tests.R:19

# setup ------------------------------------------------------------------------
library(testthat)
test_env <- simulate_test_env(package = "vi.foundry", path = "..")
attach(test_env, warn.conflicts = FALSE)

# prequel ----------------------------------------------------------------------
library(testthat)
context("Empirical tests (T1–T7)")

# test -------------------------------------------------------------------------
data <- data.frame(
    category = c("ndh", "rpo", "psa", "psb", "atp", "rpl_rps"),
    dependency_score = c(0, 1, 1, 2, 3, 5),
    orobanchaceae_loss_rank = c(1, 2, 3, 4, 5, 6) # Perfectly ordered
  )
result <- gene_loss_ordering(data, seed = 42)
expect_true(validate_result(result))
expect_equal(result$values[["spearman_rho"]], 1)
