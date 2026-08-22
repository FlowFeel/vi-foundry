# test-cultural-growth-curve.R — H5: growth curve and VI ODE fit
#
# Tests that cultural accumulation shows:
#   1. Positive acceleration (quadratic coefficient > 0)
#   2. VI ODE confirms generative regime (r_eff > 0)
#   3. VI ODE beats quadratic (Gabora) model
#
# @dft A1, A6

library(testthat)

context("Cultural: H5 growth curve (USPTO)")

test_that("H5: quadratic coefficient is positive", {
  data <- load_uspto_patents()$data
  result <- growth_curve_test(data)

  expect_true(result$values$quadratic_positive)
  expect_gt(result$values$quadratic_coefficient, 0)
})

test_that("H5: quadratic model beats linear by ΔAIC > 2", {
  data <- load_uspto_patents()$data
  result <- growth_curve_test(data)

  expect_gt(result$values$delta_aic_quad_vs_linear, 2)
})

test_that("H5: data covers at least 150 years", {
  data <- load_uspto_patents()$data
  expect_gte(nrow(data), 150)
})

test_that("H5: VI ODE confirms generative regime (r_eff > 0)", {
  data <- load_uspto_patents()$data
  t <- data$year - min(data$year)
  B <- data$cumulative_patents
  result <- fit_vi_ode_models(t, B)

  expect_true(result$values$r_eff_positive)
  expect_gt(result$values$vi_r_eff, 0)
})

test_that("H5: VI ODE beats quadratic (Gabora) model", {
  data <- load_uspto_patents()$data
  t <- data$year - min(data$year)
  B <- data$cumulative_patents
  result <- fit_vi_ode_models(t, B)

  expect_lt(result$values$vi_aic, result$values$quad_aic)
})

test_that("H5: USPTO is far from saturation (exponential regime)", {
  data <- load_uspto_patents()$data
  t <- data$year - min(data$year)
  B <- data$cumulative_patents
  result <- fit_vi_ode_models(t, B)

  # USPTO should be < 5% of K (far from saturation)
  expect_lt(result$values$pct_of_K, 5)
})
