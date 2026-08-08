# Extracted from test-unit-data-loaders.R:41

# setup ------------------------------------------------------------------------
library(testthat)
test_env <- simulate_test_env(package = "vi.foundry", path = "..")
attach(test_env, warn.conflicts = FALSE)

# prequel ----------------------------------------------------------------------
library(testthat)
context("Data loaders")

# test -------------------------------------------------------------------------
loader <- fake_data_loader
available <- loader$list_available()
