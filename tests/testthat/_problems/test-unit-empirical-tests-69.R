# Extracted from test-unit-empirical-tests.R:69

# setup ------------------------------------------------------------------------
library(testthat)
test_env <- simulate_test_env(package = "vi.foundry", path = "..")
attach(test_env, warn.conflicts = FALSE)

# prequel ----------------------------------------------------------------------
library(testthat)
context("Empirical tests (T1–T7)")

# test -------------------------------------------------------------------------
data <- data.frame(
    category = c("a", "b", "c", "d", "e", "f"),
    dependency_score = c(0, 1, 2, 3, 4, 5),
    orobanchaceae_loss_rank = c(1, 2, 3, 4, 5, 6),
    cuscuta_loss_rank = c(1, 2, 3, 4, 5, 6)
  )
result <- gene_loss_ordering(data, seed = 42)
expect_true(!is.na(result$values[["cross_family_concordance"]]))
expect_equal(result$values[["cross_family_concordance"]], c(cross_family_concordance = 1))
