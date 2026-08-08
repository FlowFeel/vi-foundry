# test-unit-simulacra-viz.R — Tests for logging and visualization
# Tests: mark creation, reading, and plot generation

library(testthat)

context("Simulacra logging and viz")

# === init_mark_log ===

test_that("init_mark_log creates YAML file with header", {
  tmp_dir <- tempfile()
  dir.create(tmp_dir)
  path <- init_mark_log("test_sim", tmp_dir)
  expect_true(file.exists(path))
  content <- readLines(path)
  expect_true(grepl("test_sim", content[1]))
  expect_true(any(grepl("^marks:", content)))
  unlink(tmp_dir, recursive = TRUE)
})

# === mark and read_marks ===

test_that("mark appends entry to log", {
  tmp_dir <- tempfile()
  dir.create(tmp_dir)
  path <- init_mark_log("test_sim", tmp_dir)

  mark(path, sim_index = 1L,
       true_params = c(lambda = 0.15, theta = 2.5),
       recovered_params = c(lambda = 0.14, theta = 2.4),
       within_ci = TRUE,
       null_result = 0.1,
       seed = 42L)

  marks <- read_marks(path)
  expect_length(marks, 1)
  expect_equal(marks[[1]]$sim_index, 1)
  expect_equal(marks[[1]]$seed, 42)
  expect_true(marks[[1]]$within_ci)

  unlink(tmp_dir, recursive = TRUE)
})

test_that("mark logs multiple entries correctly", {
  tmp_dir <- tempfile()
  dir.create(tmp_dir)
  path <- init_mark_log("multi_sim", tmp_dir)

  for (i in 1:5) {
    mark(path, sim_index = i,
         true_params = c(lambda = 0.15),
         recovered_params = c(lambda = 0.15 + rnorm(1, 0, 0.01)),
         within_ci = TRUE,
         null_result = NA,
         seed = 42L + i)
  }

  marks <- read_marks(path)
  expect_length(marks, 5)
  expect_equal(marks[[3]]$sim_index, 3)

  unlink(tmp_dir, recursive = TRUE)
})

# === read_all_marks ===

test_that("read_all_marks reads all simulacrum logs", {
  tmp_dir <- tempfile()
  dir.create(tmp_dir)

  path1 <- init_mark_log("sim_alpha", tmp_dir)
  path2 <- init_mark_log("sim_beta", tmp_dir)

  mark(path1, 1L, c(a = 1), c(a = 1.01), TRUE, NA, 42L)
  mark(path2, 1L, c(b = 2), c(b = 1.98), TRUE, NA, 42L)

  all_marks <- read_all_marks(tmp_dir)
  expect_true("sim_alpha" %in% names(all_marks))
  expect_true("sim_beta" %in% names(all_marks))
  expect_length(all_marks$sim_alpha, 1)

  unlink(tmp_dir, recursive = TRUE)
})

# === plot_true_vs_recovered ===

test_that("plot_true_vs_recovered returns ggplot object", {
  skip_if_not(requireNamespace("ggplot2", quietly = TRUE), "ggplot2 not installed")

  marks <- list(
    list(true_params = list(lambda = 0.15),
         recovered_params = list(lambda = 0.14),
         within_ci = TRUE),
    list(true_params = list(lambda = 0.15),
         recovered_params = list(lambda = 0.16),
         within_ci = TRUE),
    list(true_params = list(lambda = 0.15),
         recovered_params = list(lambda = 0.05),
         within_ci = FALSE)
  )

  p <- plot_true_vs_recovered(marks, "lambda", "test")
  expect_s3_class(p, "ggplot")
})

# === plot_recovery_trajectory ===

test_that("plot_recovery_trajectory returns ggplot object", {
  skip_if_not(requireNamespace("ggplot2", quietly = TRUE), "ggplot2 not installed")

  marks <- lapply(1:10, function(i) {
    list(
      true_params = list(lambda = 0.15),
      recovered_params = list(lambda = 0.15 + rnorm(1, 0, 0.01)),
      within_ci = TRUE,
      null_result = runif(1, 0, 0.3)
    )
  })

  p <- plot_recovery_trajectory(marks, "lambda", "test")
  expect_s3_class(p, "ggplot")
})

# === plot_param_space_projection ===

test_that("plot_param_space_projection returns ggplot for 2 params", {
  skip_if_not(requireNamespace("ggplot2", quietly = TRUE), "ggplot2 not installed")

  marks <- lapply(1:10, function(i) {
    list(
      true_params = list(lambda = 0.15, theta = 2.5),
      recovered_params = list(lambda = 0.15 + rnorm(1, 0, 0.01),
                              theta = 2.5 + rnorm(1, 0, 0.1)),
      within_ci = i %% 2 == 0
    )
  })

  p <- plot_param_space_projection(marks, "lambda", "theta", "test")
  expect_s3_class(p, "ggplot")
})

# === plot_recovery_rate ===

test_that("plot_recovery_rate returns ggplot object", {
  skip_if_not(requireNamespace("ggplot2", quietly = TRUE), "ggplot2 not installed")

  marks <- lapply(1:20, function(i) {
    list(within_ci = rnorm(1, 0.9, 0.1) > 0.85)
  })

  p <- plot_recovery_rate(marks, window = 5L, simulacrum_id = "test")
  expect_s3_class(p, "ggplot")
})

# === render_simulacra_report ===

test_that("render_simulacra_report produces PDF", {
  skip_if_not(requireNamespace("ggplot2", quietly = TRUE), "ggplot2 not installed")

  tmp_dir <- tempfile()
  dir.create(tmp_dir)
  pdf_path <- file.path(tmp_dir, "report.pdf")

  path <- init_mark_log("viz_test", tmp_dir)
  for (i in 1:5) {
    mark(path, i,
         c(lambda = 0.15, theta = 2.5),
         c(lambda = 0.15 + rnorm(1, 0, 0.01),
           theta = 2.5 + rnorm(1, 0, 0.1)),
         within_ci = TRUE,
         null_result = runif(1, 0, 0.2),
         seed = 42L + i)
  }

  result <- render_simulacra_report(tmp_dir, pdf_path)
  expect_true(result)
  expect_true(file.exists(pdf_path))

  unlink(tmp_dir, recursive = TRUE)
})
