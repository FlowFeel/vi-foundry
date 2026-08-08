# Extracted from test-unit-economics.R:78

# setup ------------------------------------------------------------------------
library(testthat)
test_env <- simulate_test_env(package = "vi.foundry", path = "..")
attach(test_env, warn.conflicts = FALSE)

# prequel ----------------------------------------------------------------------
library(testthat)
context("Economics extension (Phase 6)")
.make_test_data <- function() {
  data.frame(
    system = rep(c("news", "taxi"), each = 20),
    year = rep(1990:2009, 2),
    capacity = c(
      100 * exp(-0.02 * 0:19), # news:  slow decay
      100 * exp(-0.10 * 0:19) # taxi: fast decay
    )
  )
}
.make_threshold_data <- function() {
  data.frame(
    system = rep(c("news", "taxi"), each = 20),
    year = rep(1990:2009, 2),
    capacity = c(
      c(100, 95, 90, 85, 80, 75, 70, 65, 60, 30, 15, 8, 4, 2, 1, 1, 1, 1, 1, 1),
      c(100, 98, 95, 90, 85, 80, 75, 70, 60, 50, 20, 8, 3, 1, 1, 1, 1, 1, 1, 1)
    ),
    trigger_year = c(rep(1998, 20), rep(2000, 20))
  )
}

# test -------------------------------------------------------------------------
dat <- .make_test_data()
result <- cdi_economics(dat, seed = 42)
expect_equal(result$values["n_systems"], c(n_systems = 2))
