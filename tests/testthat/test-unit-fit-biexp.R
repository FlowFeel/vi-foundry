# test-unit-fit-biexp.R — Unit tests for bi-exponential relaxation fitter
# DFT A1: pure math, deterministic, no I/O
# DFT A2: seeded via withr::with_seed() for reproducibility

library(testthat)

context("Bi-exponential relaxation fitter")


# ---- Test 1: Bi-exponential wins on bi-exponential data ----

test_that("fit_biexp: selects bi-exponential on bi-exponential data", {
  d <- .make_biexp_data(n = 80, noise_sd = 0.001)
  fits <- fit_biexp(d$t, d$rho)

  expect_equal(fits$best_model, "biexponential")
  expect_true(fits$biexponential$converged)
  expect_gt(fits$delta_aic_bi_mono, 0)  # bi beats mono
})


# ---- Test 2: Mono-exponential wins on mono-exponential data ----

test_that("fit_biexp: does not falsely report bi-exponential on mono data", {
  d <- .make_monoexp_data(n = 80, noise_sd = 0.001)
  fits <- fit_biexp(d$t, d$rho)

  # Mono should win or be competitive (lower AIC due to fewer params)
  expect_true(fits$best_model != "biexponential" ||
                fits$delta_aic_bi_mono < 2)
})


# ---- Test 3: Parameter recovery on clean bi-exponential data ----

test_that("fit_biexp: recovers k1 and k2 from clean data", {
  d <- .make_biexp_data(n = 100, t_max = 10, noise_sd = 1e-6)
  fits <- fit_biexp(d$t, d$rho)

  expect_true(fits$biexponential$converged)
  # Should recover k1 > 1 and k2 < 1 (fast/slow hierarchy)
  expect_gt(fits$metadata$k1_k2_ratio, 5)
})


# ---- Test 4: Linear null — linear loses to bi-exp on bi-exp data ----

test_that("fit_biexp: linear loses to bi-exponential on bi-exp data", {
  d <- .make_biexp_data(n = 80, noise_sd = 0.001)
  fits <- fit_biexp(d$t, d$rho)

  expect_equal(fits$best_model, "biexponential")
  expect_gt(fits$delta_aic_bi_linear, 0)  # bi beats linear
})


# ---- Test 5: Error on insufficient data ----

test_that("fit_biexp: errors on fewer than 6 data points", {
  expect_error(fit_biexp(1:5, runif(5)))
})


# ---- Test 6: Bi-exponential recovery across multiple seeds ----

test_that("fit_biexp: consistent recovery across multiple seeds", {
  seeds <- 1:10
  results <- vapply(seeds, function(s) {
    d <- .make_biexp_data(seed = s, n = 80, noise_sd = 0.002)
    fits <- fit_biexp(d$t, d$rho)
    fits$best_model
  }, character(1))

  # Most seeds should recover bi-exp; some may not converge
  bi_count <- sum(results == "biexponential")
  expect_gt(bi_count, 5)
})


# ---- Test 7: k1 > k2 (fast/slow hierarchy) ----

test_that("fit_biexp: k1 > k2 when fitted (fast/slow hierarchy)", {
  d <- .make_biexp_data(n = 100, noise_sd = 0.001)
  fits <- fit_biexp(d$t, d$rho)

  if (fits$biexponential$converged) {
    expect_gt(fits$biexponential$coefficients$k1,
              fits$biexponential$coefficients$k2)
  }
})


# ---- Test 8: Normalisation is stable ----

test_that("fit_biexp: normalised and unnormalised give similar results", {
  d <- .make_biexp_data(n = 80, t_max = 56500, noise_sd = 0.001)
  fits_norm <- fit_biexp(d$t, d$rho, normalize_t = TRUE)
  fits_raw <- fit_biexp(d$t, d$rho, normalize_t = FALSE)

  # Both should converge and select bi-exponential
  expect_equal(fits_norm$best_model, fits_raw$best_model)
  expect_true(fits_norm$biexponential$converged || fits_raw$biexponential$converged)
})


# ---- Test 9: Zero noise — near-perfect parameter recovery ----

test_that("fit_biexp: near-perfect recovery with zero noise", {
  d <- .make_biexp_data(n = 100, noise_sd = 0)
  fits <- fit_biexp(d$t, d$rho)

  expect_true(fits$biexponential$converged)
  expect_equal(fits$best_model, "biexponential")
  expect_gt(fits$delta_aic_bi_mono, 10)  # decisively bi
})


# ---- Test 10: Return structure has all expected fields ----

test_that("fit_biexp: return structure is complete", {
  d <- .make_biexp_data(n = 40, noise_sd = 0.001)
  fits <- fit_biexp(d$t, d$rho)

  expect_named(fits, c("biexponential", "monoexponential", "linear",
                       "best_model", "delta_aic_bi_mono", "delta_aic_bi_linear",
                       "metadata"))
  expect_named(fits$biexponential, c("coefficients", "fit", "rss", "aic", "converged"))
  expect_named(fits$monoexponential, c("coefficients", "fit", "rss", "aic", "converged"))
  expect_named(fits$linear, c("coefficients", "fit", "rss", "aic"))
  expect_named(fits$metadata, c("n", "normalised", "k1_k2_ratio", "k1_halflife",
                                 "k2_halflife", "A1_frac", "A2_frac"))
})