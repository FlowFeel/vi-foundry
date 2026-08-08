# Extracted from test-unit-cross-kingdom.R:96

# setup ------------------------------------------------------------------------
library(testthat)
test_env <- simulate_test_env(package = "vi.foundry", path = "..")
attach(test_env, warn.conflicts = FALSE)

# prequel ----------------------------------------------------------------------
library(testthat)
context("Cross-kingdom transfer")

# test -------------------------------------------------------------------------
plant_data <- data.frame(
    category = c("a", "b", "c", "d", "e", "f"),
    dependency_score = c(0, 1, 2, 3, 4, 5),
    lineage1_loss_rank = c(1, 2, 3, 4, 5, 6)
  )
bird_data <- data.frame(
    structure = c("a", "b", "c", "d", "e", "f", "g", "h"),
    dependency_score = c(0, 0.5, 1, 1.5, 2, 3, 4, 5),
    observed_rank = c(1, 2, 3, 4, 5, 6, 7, 8)
  )
r1 <- transfer_test(plant_data, bird_data, seed = 42)
