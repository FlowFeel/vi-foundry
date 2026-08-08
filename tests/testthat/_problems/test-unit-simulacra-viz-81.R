# Extracted from test-unit-simulacra-viz.R:81

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
path1 <- init_mark_log("sim_alpha", tmp_dir)
path2 <- init_mark_log("sim_beta", tmp_dir)
mark(path1, 1L, c(a = 1), c(a = 1.01), TRUE, NA, 42L)
mark(path2, 1L, c(b = 2), c(b = 1.98), TRUE, NA, 42L)
all_marks <- read_all_marks(tmp_dir)
