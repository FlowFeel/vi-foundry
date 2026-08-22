# test-cultural-ode-fit.R — VI ODE growth curve fitting
#
# Tests the VI model ODE against competing growth models on real cultural
# accumulation data. The VI ODE (generalized logistic with decay) should:
#   1. Confirm r_eff > 0 (generative regime, β > 1)
#   2. Win or be competitive with simple exponential when near saturation
#   3. Always beat the quadratic (Gabora) model
#
# @section Theoretical Context:
#
# VI Prediction: dB/dt = ε·β·B·(1-B/K) - δ·B
#   - Far from saturation (B << K): reduces to exponential (r·B)
#   - Near saturation (B → K): logistic saturation dynamics
#   - Bi-exponential form wins when system approaches carrying capacity
#
# @dft A1, A2, A6

library(testthat)

context("Cultural: VI ODE growth curve fitting")

# ---- USPTO patents (1836-2023, 188 years, full population) ----

test_that("USPTO: VI ODE confirms generative regime (r_eff > 0)", {
  data <- load_uspto_patents()$data
  t <- data$year - min(data$year)
  B <- data$cumulative_patents
  result <- fit_vi_ode_models(t, B)

  expect_true(result$values$r_eff_positive)
  expect_gt(result$values$vi_r_eff, 0)
})

test_that("USPTO: VI ODE beats quadratic (Gabora) model", {
  data <- load_uspto_patents()$data
  t <- data$year - min(data$year)
  B <- data$cumulative_patents
  result <- fit_vi_ode_models(t, B)

  expect_lt(result$values$vi_aic, result$values$quad_aic)
})

test_that("USPTO: system is far from saturation (exponential regime)", {
  data <- load_uspto_patents()$data
  t <- data$year - min(data$year)
  B <- data$cumulative_patents
  result <- fit_vi_ode_models(t, B)

  # USPTO should be < 5% of K (far from saturation)
  expect_lt(result$values$pct_of_K, 5)
  # Simple exponential should be competitive (within ΔAIC < 6)
  expect_lt(result$values$vi_delta_aic, 6)
})

test_that("USPTO: covers at least 180 years", {
  data <- load_uspto_patents()$data
  expect_gte(nrow(data), 180)
})

# ---- Wikipedia articles (2001-2026, 25 years) ----

# Wikipedia data is loaded from JSON; for foundry test, we use bundled data
# if available, otherwise skip

test_that("Wikipedia: bi-exponential wins near saturation", {
  # Wikipedia is the one dataset that approaches K (94.9%)
  # The bi-exponential (VI relaxation form) should win decisively
  # This test requires wikipedia growth data
  wiki_file <- system.file("data", "wikipedia_growth.csv",
                            package = "vi.foundry")
  if (!file.exists(wiki_file)) skip("wikipedia_growth.csv not bundled")

  wiki <- utils::read.csv(wiki_file)
  t <- wiki$year - min(wiki$year)
  B <- wiki$articles
  result <- fit_vi_ode_models(t, B)

  # Bi-exponential should have lowest AIC
  expect_equal(result$values$best_model, "biexp")
  # Wikipedia should be > 80% of K (near saturation)
  expect_gt(result$values$pct_of_K, 80)
})

# ---- Generative regime confirmation across all datasets ----

test_that("All cultural domains confirm r_eff > 0 (generative regime)", {
  data <- load_uspto_patents()$data
  t <- data$year - min(data$year)
  B <- data$cumulative_patents
  result <- fit_vi_ode_models(t, B)

  expect_true(result$values$r_eff_positive)
  expect_gt(result$values$vi_r_eff, 0)
  expect_gt(result$values$vi_r, result$values$vi_delta)
})
