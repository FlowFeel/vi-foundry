# test-unit-fit-biexp.R — Unit tests for bi-exponential relaxation fitter
# DFT A1: pure math, deterministic, no I/O
# DFT A2: seeded via withr::with_seed() for reproducibility
#
# Rewritten 2026-09-03 (monograph review, Ed/Jam): the original suite was
# flaky because its fixture undersampled the fast phase (linear grid over
# [0,10] with k1 = 17.7 gives ~1 point per fast half-life), its assertions
# were permissive (5/10 recovery accepted, "mono loses by <2" accepted),
# and it silently accepted degradation (raw-scale fit at t_max = 56500 fell
# back to "linear" without flagging non-convergence).
#
# Contract under test (fit_biexp):
#   C1. On data that resolves both timescales, bi-exponential is selected
#       decisively over mono-exponential and linear.
#   C2. On mono-exponential data, mono wins or is within the 2-parameter
#       penalty (never a spurious decisive bi win).
#   C3. Parameters are recoverable: k1 > k2 (fast/slow hierarchy),
#       k1/k2 ratio and half-lives within tolerance of truth.
#   C4. Normalization is a numerical-stability device, not a model selector:
#       normalized and raw fits agree on well-conditioned data at any
#       timescale.
#   C5. Insufficient data errors loudly (n < 6).
#   C6. Return structure is complete and named (A6 contract).
#
# Known gaps (skipped, tied to register):
#   G1. n-floor degeneracy (6 params on 6 points overfits, ΔAIC ~36) — E10.
#   G2. Competitor models (switch-train, power law, stretched exponential)
#       absent from model comparison — E10/O12.
#   G3. No uncertainty on ΔAIC (single fit, no bootstrap/CI) — O12.
#   G4. k1 > k2 not enforced (label-swap protection absent) — E10.
#   G5. rate-proportionality consequence (rate ∝ remaining) not
#       implemented/tested — O12.

library(testthat)

# ---- C1: bi-exponential wins decisively on well-resolved bi data ----

test_that("fit_biexp: selects bi-exponential on resolved bi-exponential data", {
  d <- .make_biexp_data(n = 80, log_grid = TRUE, noise_sd = 0.001)
  fits <- fit_biexp(d$t, d$rho)

  expect_equal(fits$best_model, "biexponential")
  expect_true(fits$biexponential$converged)
  expect_gt(fits$delta_aic_bi_mono, 10)    # decisive, not marginal
  expect_gt(fits$delta_aic_bi_linear, 20)  # linear clearly loses
})


# ---- C2: mono-exponential data must not produce a spurious bi win ----

test_that("fit_biexp: mono data yields mono win or within 2-param penalty", {
  d <- .make_monoexp_data(n = 80, noise_sd = 0.001)
  fits <- fit_biexp(d$t, d$rho)

  # bi pays 2 extra parameters (ΔAIC penalty = 4); a mono-generating process
  # must never be selected decisively (delta < 2 is the competitive regime)
  expect_true(fits$best_model != "biexponential" ||
                fits$delta_aic_bi_mono < 2)
})


# ---- C3: parameter recovery on clean, well-resolved data ----

test_that("fit_biexp: recovers k1, k2 hierarchy and half-lives", {
  d <- .make_biexp_data(n = 120, log_grid = TRUE, noise_sd = 1e-6)
  fits <- fit_biexp(d$t, d$rho)

  expect_true(fits$biexponential$converged)

  # True values: k1 = 17.7 (half-life 0.0392), k2 = 0.47 (half-life 1.475)
  expect_gt(fits$metadata$k1_k2_ratio, 25)                    # true ~37.7
  expect_lt(fits$metadata$k1_k2_ratio, 55)
  expect_equal(fits$metadata$k1_halflife, 0.0392, tolerance = 0.15)
  expect_equal(fits$metadata$k2_halflife, 1.475, tolerance = 0.15)

  # Fast phase dominates early: A1 > A2
  expect_gt(fits$metadata$A1_frac, 0.5)
})


# ---- C4: normalization makes the default path timescale-invariant ----

test_that("fit_biexp: normalize_t = TRUE recovers bi across timescales", {
  # Rates rescaled so both phases are visible on each domain (k1*t_max ≈ 20,
  # k2*t_max ≈ 2). The default normalized path must be timescale-invariant:
  # same model family, same halflives (in original time units).
  for (t_max in c(10, 1000, 56500)) {
    k1 <- 20 / t_max
    k2 <- 2 / t_max
    d <- .make_biexp_data(n = 100, t_max = t_max, k1 = k1, k2 = k2,
                          log_grid = TRUE, noise_sd = 0.001)
    fits <- fit_biexp(d$t, d$rho, normalize_t = TRUE)

    expect_equal(fits$best_model, "biexponential",
                 info = paste("t_max =", t_max))
    expect_true(fits$biexponential$converged,
                info = paste("t_max =", t_max))
    # halflife in original units: ln(2)/k, tolerance 25% (fit noise)
    expect_equal(fits$metadata$k1_halflife, log(2) / k1,
                 tolerance = 0.25, info = paste("t_max =", t_max))
    expect_equal(fits$metadata$k2_halflife, log(2) / k2,
                 tolerance = 0.25, info = paste("t_max =", t_max))
  }
})


test_that("fit_biexp: normalized and raw agree at well-conditioned scale", {
  # At t_max = 10 both paths are well-conditioned; they must agree on model
  # family and both must converge. (Parameter recovery is guaranteed on the
  # normalized path; the raw path's scale-blind start grid can land in local
  # minima — see G7. Extreme scales: see G6.)
  d <- .make_biexp_data(n = 100, log_grid = TRUE, noise_sd = 0.001)
  fits_norm <- fit_biexp(d$t, d$rho, normalize_t = TRUE)
  fits_raw  <- fit_biexp(d$t, d$rho, normalize_t = FALSE)

  expect_equal(fits_norm$best_model, fits_raw$best_model)
  expect_true(fits_norm$biexponential$converged)
  expect_true(fits_raw$biexponential$converged)
  # Normalized path recovers true halflives (k1: 0.0392, k2: 1.475)
  expect_equal(fits_norm$metadata$k1_halflife, 0.0392, tolerance = 0.25)
  expect_equal(fits_norm$metadata$k2_halflife, 1.475, tolerance = 0.25)
})


# ---- C5: insufficient data errors loudly ----

test_that("fit_biexp: errors on fewer than 6 data points", {
  expect_error(fit_biexp(1:5, runif(5)))
})


# ---- C6: return structure is complete ----

test_that("fit_biexp: return structure is complete", {
  d <- .make_biexp_data(n = 60, log_grid = TRUE, noise_sd = 0.001)
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


# ---- Stability: multi-seed recovery on resolved data ----

test_that("fit_biexp: consistent recovery across multiple seeds", {
  seeds <- 1:10
  results <- vapply(seeds, function(s) {
    d <- .make_biexp_data(seed = s, n = 80, log_grid = TRUE, noise_sd = 0.002)
    fits <- fit_biexp(d$t, d$rho)
    fits$best_model
  }, character(1))

  # Resolved data: nearly all seeds must recover bi-exp (was >5 of 10;
  # the old fixture undersampled the fast phase and hid the failures)
  bi_count <- sum(results == "biexponential")
  expect_gte(bi_count, 8)
})


# ---- Stability: normalization must not flip model choice ----

test_that("fit_biexp: normalization does not flip model choice", {
  d <- .make_biexp_data(n = 80, log_grid = TRUE, noise_sd = 0.001)
  fits_norm <- fit_biexp(d$t, d$rho, normalize_t = TRUE)
  fits_raw  <- fit_biexp(d$t, d$rho, normalize_t = FALSE)

  expect_equal(fits_norm$best_model, fits_raw$best_model)
  expect_true(fits_norm$biexponential$converged ||
                fits_raw$biexponential$converged)
})


# ---- Zero noise: near-perfect recovery ----

test_that("fit_biexp: near-perfect recovery with zero noise", {
  d <- .make_biexp_data(n = 100, log_grid = TRUE, noise_sd = 0)
  fits <- fit_biexp(d$t, d$rho)

  expect_true(fits$biexponential$converged)
  expect_equal(fits$best_model, "biexponential")
  expect_gt(fits$delta_aic_bi_mono, 50)
})


# ============================================================================
# Known gaps — skipped with register references. These document what the
# implementation must add; they go green when the gaps are closed.
# ============================================================================

test_that("G1: n-floor rejects degenerate 6-param-on-6-point fits", {
  skip("GAP-E10: n-floor not enforced — 6 params on 6 points overfits (ΔAIC ~36); floor should be n >= 3*params")
  t <- seq(0, 5, length.out = 6)
  rho <- 0.05 + 0.03 * exp(-2 * t) + 0.01 * exp(-0.3 * t) + rnorm(6, 0, 1e-4)
  fits <- fit_biexp(t, rho)
  expect_false(fits$biexponential$converged)  # must not report a degenerate win
})

test_that("G2: competitor models participate in model comparison", {
  skip("GAP-E10/O12: only bi/mono/linear compared — switch-train, power law, stretched exponential absent")
  d <- .make_biexp_data(n = 80, log_grid = TRUE, noise_sd = 0.001)
  fits <- fit_biexp(d$t, d$rho)
  expect_true("switch_train" %in% names(fits))   # competitor AICs reported
  expect_true("power_law" %in% names(fits))
  expect_true("stretched_exp" %in% names(fits))
})

test_that("G3: ΔAIC carries uncertainty (bootstrap/CI)", {
  skip("GAP-O12: single fit, no bootstrap — the headline ΔAIC has no error bar")
  d <- .make_biexp_data(n = 80, log_grid = TRUE, noise_sd = 0.002)
  fits <- fit_biexp(d$t, d$rho)
  expect_true(!is.null(fits$delta_aic_bi_mono_ci))
  expect_length(fits$delta_aic_bi_mono_ci, 2)
})

test_that("G4: k1 > k2 enforced (label-swap protection)", {
  skip("GAP-E10: no constraint/parameterization enforces fast/slow ordering — k1 and k2 can silently swap")
  # Near-degenerate timescales (k1 ≈ k2) are where label swaps happen
  d <- .make_biexp_data(n = 100, k1 = 1.1, k2 = 1.0, log_grid = TRUE, noise_sd = 0.001)
  fits <- fit_biexp(d$t, d$rho)
  if (fits$biexponential$converged) {
    expect_gt(fits$biexponential$coefficients$k1,
              fits$biexponential$coefficients$k2)
  }
})

test_that("G5: rate-proportionality consequence is tested", {
  skip("GAP-O12: rate ∝ remaining (the simplest two-rate consequence, 1/4 LTEE pops) not implemented")
  d <- .make_biexp_data(n = 80, log_grid = TRUE, noise_sd = 0.001)
  fits <- fit_biexp(d$t, d$rho)
  expect_true(!is.null(fits$rate_proportionality))
})

test_that("G6: raw-scale fit at extreme timescales fails loudly, not silently", {
  skip("GAP-E10: normalize_t = FALSE at t_max = 56500 silently degrades to mono (start values k=1.0 kill the Jacobian; bi never converges; code filters Inf AIC and reports mono without warning)")
  k1 <- 20 / 56500
  k2 <- 2 / 56500
  d <- .make_biexp_data(n = 100, t_max = 56500, k1 = k1, k2 = k2,
                        log_grid = TRUE, noise_sd = 0.001)
  fits_raw <- fit_biexp(d$t, d$rho, normalize_t = FALSE)
  expect_warning(fits_raw)  # must warn when a candidate family fails to converge
})

test_that("G7: multi-start grid is scale-aware (no local minima on raw path)", {
  skip("GAP-E10: start grid k1 ∈ {2,5,10,1,20,3} is scale-blind — at t_max = 10, true k1 = 17.7, raw path lands at k1 ≈ 1.7 (local min); grid should be derived from data scale (e.g., from a mono fit or spectral estimate)")
  d <- .make_biexp_data(n = 100, log_grid = TRUE, noise_sd = 0.001)
  fits_raw <- fit_biexp(d$t, d$rho, normalize_t = FALSE)
  expect_equal(fits_raw$metadata$k1_halflife, 0.0392, tolerance = 0.25)
})
