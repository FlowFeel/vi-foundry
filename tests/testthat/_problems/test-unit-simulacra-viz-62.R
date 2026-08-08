# Extracted from test-unit-simulacra-viz.R:62

# setup ------------------------------------------------------------------------
library(testthat)
test_env <- simulate_test_env(package = "vi.foundry", path = "..")
attach(test_env, warn.conflicts = FALSE)

# prequel ----------------------------------------------------------------------
library(testthat)
context("Simulacra logging and viz")

# test -------------------------------------------------------------------------
tmp_dir <- tempfile()
dir.create(tmp_dir)
path <- init_mark_log("multi_sim", tmp_dir)
for (i in 1:5) {
    mark(path,
      sim_index = i,
      true_params = c(lambda = 0.15),
      recovered_params = c(lambda = 0.15 + rnorm(1, 0, 0.01)),
      within_ci = TRUE,
      null_result = NA,
      seed = 42L + i
    )
  }
marks <- read_marks(path)
