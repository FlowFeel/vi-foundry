# test-unit-assemblage-diversity.R — Unit tests for Diachenko & Gronenborn 2026
# DFT A1: pure functions, deterministic math
# Tests: known input → known output (verified against S1 Table in-session)

library(testthat)

context("Assemblage diversity (Diachenko & Gronenborn 2026)")

# === Eq 2 — Shannon diversity ===

test_that("dg_diversity: uniform types give effective count = n", {
  expect_equal(dg_diversity(c(0.5, 0.5)), 2.0, tolerance = 1e-12)
  expect_equal(dg_diversity(c(1 / 3, 1 / 3, 1 / 3)), 3.0, tolerance = 1e-12)
})

test_that("dg_diversity: matches S1 Fig 7 values (exp(H) = D)", {
  # S1 Fig 7 row 1: entropy 1.93 -> diversity 6.889510241
  expect_equal(exp(1.93), 6.889510241, tolerance = 1e-6)
})

test_that("dg_diversity: single type has diversity 1 (zero entropy)", {
  expect_equal(dg_diversity(c(1, 0, 0)), 1.0)
})

# === Eq 6 — stability threshold ===

test_that("dg_stability_threshold: matches S1 Fig 5A values", {
  # S1 Fig 5A: k=1.1, p=0.25 -> 1.423529411764706
  expect_equal(dg_stability_threshold(p = 0.25, k = 1.1, C = 1),
    1.423529411764706, tolerance = 1e-9)
  # k=1.1, p=0.75 -> 3.457142857142857
  expect_equal(dg_stability_threshold(p = 0.75, k = 1.1, C = 1),
    3.457142857142857, tolerance = 1e-9)
})

# === Eq 7 — maximal proportion ===

test_that("dg_max_proportion: matches S1 Fig 3 values", {
  # S1 Fig 3: k=1 -> 0.75; k=1.1 -> 0.7975; k=1.4 -> 0.91; k=2 -> 1.0
  expect_equal(dg_max_proportion(k = 1.0, C = 1, r_stab = 4), 0.75, tolerance = 1e-12)
  expect_equal(dg_max_proportion(k = 1.1, C = 1, r_stab = 4), 0.7975, tolerance = 1e-12)
  expect_equal(dg_max_proportion(k = 1.4, C = 1, r_stab = 4), 0.91, tolerance = 1e-12)
  expect_equal(dg_max_proportion(k = 2.0, C = 1, r_stab = 4), 1.0, tolerance = 1e-12)
  expect_equal(dg_max_proportion(k = 0.5, C = 1, r_stab = 4), 0.4375, tolerance = 1e-12)
})

# === Eq 4 — update rule ===

test_that("dg_update: reproduces S1 Fig 4 worked example", {
  # Paper Fig 4: A,B,C at 0.8/0.1/0.1; k=1.1; r_alpha=3.6; r_n=1.73
  # Result: A -> 0.714, B,C -> 0.143
  p <- c(A = 0.8, B = 0.1, C = 0.1)
  r <- c(A = 3.6, B = 1.73, C = 1.73)
  out <- dg_update(p, r, k = 1.1, C = 1)
  expect_equal(unname(out["A"]), 0.7140495868, tolerance = 1e-9)
  expect_equal(unname(out["B"]), 0.1429752066, tolerance = 1e-9)
  expect_equal(unname(out["C"]), 0.1429752066, tolerance = 1e-9)
  expect_equal(sum(out), 1.0, tolerance = 1e-12)
})

test_that("dg_update: stability threshold keeps proportion flat", {
  # At r_alpha = r_stab and with r_B = 4 (the model's maximum, which satisfies
  # Eq 3's sum-to-1 constraint for a 3:1 secondary assemblage), the primary
  # unit's proportion is unchanged.
  p <- c(A = 0.25, B = 0.75)
  r_stab <- dg_stability_threshold(p = 0.25, k = 1.0, C = 1)
  r <- c(A = r_stab, B = 4)
  out <- dg_update(p, r, k = 1.0, C = 1)
  expect_equal(unname(out["A"]), 0.25, tolerance = 1e-9)
  expect_equal(sum(out), 1.0, tolerance = 1e-12)
})

test_that("dg_diversity of Fig 6 time-1 proportions matches S1", {
  # S1 Fig 6 t1: 0.1, 0.8, 0.05, 0.05 -> diversity 2.0306309908905886
  expect_equal(dg_diversity(c(0.1, 0.8, 0.05, 0.05)),
    2.0306309908905886, tolerance = 1e-9)
})

test_that("dg_diversity of Fig 6 time-2 proportions matches S1", {
  # S1 Fig 6 t2: 0.18, 0.64, 0.09, 0.09 -> diversity 2.794680174400643
  expect_equal(dg_diversity(c(0.18, 0.64, 0.09, 0.09)),
    2.794680174400643, tolerance = 1e-9)
})