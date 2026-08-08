# Extracted from test-unit-simulacra-viz.R:190

# setup ------------------------------------------------------------------------
library(testthat)
test_env <- simulate_test_env(package = "vi.foundry", path = "..")
attach(test_env, warn.conflicts = FALSE)

# prequel ----------------------------------------------------------------------
library(testthat)
context("Simulacra logging and viz")

# test -------------------------------------------------------------------------
skip_if_not(requireNamespace("ggplot2", quietly = TRUE), "ggplot2 not installed")
tmp_dir <- tempfile()
dir.create(tmp_dir)
pdf_path <- file.path(tmp_dir, "report.pdf")
path <- init_mark_log("viz_test", tmp_dir)
for (i in 1:5) {
    mark(path, i,
      c(lambda = 0.15, theta = 2.5),
      c(
        lambda = 0.15 + rnorm(1, 0, 0.01),
        theta = 2.5 + rnorm(1, 0, 0.1)
      ),
      within_ci = TRUE,
      null_result = runif(1, 0, 0.2),
      seed = 42L + i
    )
  }
result <- render_simulacra_report(tmp_dir, pdf_path)
