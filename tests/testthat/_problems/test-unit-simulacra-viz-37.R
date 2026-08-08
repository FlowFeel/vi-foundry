# Extracted from test-unit-simulacra-viz.R:37

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
path <- init_mark_log("test_sim", tmp_dir)
mark(path,
    sim_index = 1L,
    true_params = c(lambda = 0.15, theta = 2.5),
    recovered_params = c(lambda = 0.14, theta = 2.4),
    within_ci = TRUE,
    null_result = 0.1,
    seed = 42L
  )
marks <- read_marks(path)
