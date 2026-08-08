# Extracted from test-unit-cross-kingdom.R:78

# setup ------------------------------------------------------------------------
library(testthat)
test_env <- simulate_test_env(package = "vi.foundry", path = "..")
attach(test_env, warn.conflicts = FALSE)

# prequel ----------------------------------------------------------------------
library(testthat)
context("Cross-kingdom transfer")

# test -------------------------------------------------------------------------
plant_data <- data.frame(
    category = c("ndh", "rpo", "psa", "psb", "atp", "rpl_rps"),
    dependency_score = c(0, 1, 1, 2, 3, 5),
    orobanchaceae_loss_rank = c(1, 2, 3, 4, 5, 6)
  )
bird_data <- data.frame(
    structure = c(
      "wing", "keel", "pectoral", "hindlimb", "pelvis",
      "feathers", "wing_bones", "asymmetry"
    ),
    dependency_score = c(0.0, 1.0, 0.5, 4.0, 3.0, 5.0, 1.5, 1.0),
    observed_rank = c(1, 3, 2, 4, 5, 6, 7, 8)
  )
result <- transfer_test(plant_data, bird_data, seed = 42)
