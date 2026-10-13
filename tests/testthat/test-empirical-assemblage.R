# test-empirical-assemblage.R — Empirical tests on the DG2026 published series
#
# Tests the paper's two empirical claims against the S1 Table data:
#  C3: LBK assemblage diversity leads population (Fig 7)
#  C4: WTC decoration-class richness declines as population rises (Fig 10)

library(testthat)

context("Empirical: Diachenko & Gronenborn LBK / WTC series")

test_that("L1: LBK data is bundled and well-formed", {
  dat <- dg_load_empirical("fig7")
  skip_if(is.null(dat), "LBK data not bundled")
  expect_equal(nrow(dat), 10)
  # Columns: Time, Population proxy, Entropy band, Diversity band, Entropy motifs, Diversity motifs
  expect_true(all(is.numeric(dat[[2]])))
  expect_true(all(is.numeric(dat[[4]]))) # band-type diversity col 4
})

test_that("C3: LBK band-type diversity peaks before population peak", {
  dat <- dg_load_empirical("fig7")
  skip_if(is.null(dat), "LBK data not bundled")
  diversity <- as.numeric(dat[[4]]) # Diversity (band types)
  population <- as.numeric(dat[[2]])
  # Diversity peak at row 6 (5150 BCE), population peak at row 9 (5065 BCE)
  expect_equal(which.max(diversity), 6)
  expect_equal(which.max(population), 9)
  expect_lt(which.max(diversity), which.max(population))
})

test_that("C3b: LBK lead-lag test runs and returns A6 proof object", {
  dat <- dg_load_empirical("fig7")
  skip_if(is.null(dat), "LBK data not bundled")
  res <- dg_lbk_lead_lag(lag_max = 3, n_perm = 999, seed = 42)
  expect_true("values" %in% names(res))
  expect_true("metadata" %in% names(res))
  expect_equal(res$metadata$seed, 42)
  expect_gt(res$values[["best_lag"]], 0) # diversity leads population
})

test_that("L1: WTC data is bundled and well-formed", {
  dat <- dg_load_empirical("fig10")
  skip_if(is.null(dat), "WTC data not bundled")
  expect_equal(nrow(dat), 10)
  expect_true(all(is.numeric(dat[[2]])))
  # Forms diversity has two '-' missing cells (4000, 3950 BCE) -> NA after as.numeric
  forms <- suppressWarnings(as.numeric(dat[[3]]))
  expect_equal(sum(is.na(forms)), 2)
})

test_that("C4: WTC decoration-class richness declines 6 -> 1", {
  dat <- dg_load_empirical("fig10")
  skip_if(is.null(dat), "WTC data not bundled")
  richness <- as.numeric(dat[[4]])
  expect_equal(richness[1], 6)
  expect_equal(richness[10], 1)
  # Monotone non-increasing
  expect_true(all(diff(richness) <= 0))
})

test_that("C4b: WTC standardization test returns negative rho (richness vs pop)", {
  dat <- dg_load_empirical("fig10")
  skip_if(is.null(dat), "WTC data not bundled")
  res <- dg_wtc_standardization(n_perm = 999, seed = 42)
  expect_true("values" %in% names(res))
  expect_lt(res$values[["rho"]], 0) # standardization: richness falls as pop rises
})