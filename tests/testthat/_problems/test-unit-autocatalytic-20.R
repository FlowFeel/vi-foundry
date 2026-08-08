# Extracted from test-unit-autocatalytic.R:20

# setup ------------------------------------------------------------------------
library(testthat)
test_env <- simulate_test_env(package = "vi.foundry", path = "..")
attach(test_env, warn.conflicts = FALSE)

# prequel ----------------------------------------------------------------------
library(testthat)
context("Autocatalytic set")

# test -------------------------------------------------------------------------
innovations <- c("A", "B", "C")
catalyst_matrix <- matrix(c(
    FALSE, TRUE, FALSE,
    FALSE, FALSE, TRUE,
    TRUE, FALSE, FALSE
  ), nrow = 3, byrow = TRUE)
result <- autocatalytic_closure(innovations, catalyst_matrix)
expect_true(validate_result(result))
expect_true(result$values["achieves_closure"])
expect_equal(result$values["n_catalyzed"], 3)
