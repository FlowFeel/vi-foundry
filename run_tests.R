#!/usr/bin/env Rscript
# run_tests.R — Test runner for vi.foundry
#
# Usage:
#   Rscript run_tests.R           # Run all tests
#   Rscript run_tests.R unit      # Unit tests only
#   Rscript run_tests.R integration # Integration tests only
#   Rscript run_tests.R simulacra  # Simulacrum tests only

library(testthat)
library(vi.foundry)

filter <- if (length(commandArgs(trailingOnly = TRUE)) > 0) {
  commandArgs(trailingOnly = TRUE)[1]
} else {
  NULL
}

cat("=== VI Foundry Test Runner ===\n")
cat(sprintf("Filter: %s\n", if (is.null(filter)) "all" else filter))
cat(sprintf("R version: %s\n", R.version.string))
cat(sprintf("Timestamp: %s\n\n", format(Sys.time(), "%Y-%m-%d %H:%M:%S UTC", tz = "UTC")))

results <- test_local(".", filter = filter, reporter = CheckReporter)

cat(sprintf("\n=== Results: %d passed, %d failed, %d skipped ===\n",
           sum(sapply(results, function(x) sum(x$passed))),
           sum(sapply(results, function(x) sum(x$failed))),
           sum(sapply(results, function(x) sum(x$skipped)))))

# Coverage check
if (requireNamespace("covr", quietly = TRUE)) {
  cov <- covr::package_coverage()
  pct <- covr::percent_coverage(cov)
  cat(sprintf("Coverage: %.2f%%\n", pct))
  if (pct < 80) {
    stop("Coverage below 80% threshold: ", round(pct, 2), "%")
  }
}
