# test-empirical-assemblage-raw.R — Tests against the author-sent raw WTC data
#
# Source: Diachenko & Gronenborn sent the raw Ryzhov-typology vessel-type
# proportion table behind S1 Fig 10 (time units 1, 4-10; units 2-3 excluded
# as statistically weak — matching S1's '-' cells at 4000/3950 BCE).
#
# Reconciliation result (2026-10-15, corrected): with the duplicate 'G' row
# treated as 'J', ALL 8 units reproduce the published diversity-of-forms
# values EXACTLY. Every column sums to 1.0 — the table is a complete type
# inventory. (An earlier pass reported 3/8 using a dict that collapsed the
# duplicate G rows; the R data.frame keeps both. Correct finding: 8/8.)

library(testthat)

context("Empirical (raw): WTC vessel-type data reconciliation")

# Resolve from the source tree (data/ subdir, not installed package data/)
.raw_wtc_path <- function() {
  p <- tryCatch(testthat::test_path("..", "..", "data",
    "diachenko-gronenborn-2026", "WTC_vessel_types_raw.csv"),
    error = function(e) NA_character_)
  if (is.na(p) || !file.exists(p)) NA_character_ else p
}

.load_raw_wtc <- function() {
  p <- .raw_wtc_path()
  if (is.na(p)) stop("raw WTC data not bundled")
  utils::read.csv(p, check.names = FALSE, stringsAsFactors = FALSE)
}

# Published S1 Fig 10 diversity-of-forms values, keyed by time unit
.s1_diversity <- c(
  "1" = 4.05323600142588,  "4" = 7.31931026734842, "5" = 6.814215858471437,
  "6" = 8.238599677174275, "7" = 5.924414781029749, "8" = 5.32097406897683,
  "9" = 5.488835818952138, "10" = 4.053251907232219
)

.diversity_of <- function(col_vals) {
  p <- col_vals[col_vals > 0]
  exp(-sum(p * log(p)))
}

test_that("L1: raw WTC data file is bundled", {
  dat <- tryCatch(.load_raw_wtc(), error = function(e) NULL)
  skip_if(is.null(dat), "raw WTC data not bundled")
  expect_true(nrow(dat) >= 13) # vessel types
  expect_true(ncol(dat) == 9)  # type + 8 time units
})

test_that("raw WTC every column sums to 1.0 (complete inventory)", {
  dat <- tryCatch(.load_raw_wtc(), error = function(e) NULL)
  skip_if(is.null(dat), "raw WTC data not bundled")
  units <- sub("unit_", "", grep("^unit_", names(dat), value = TRUE))
  for (u in units) {
    expect_equal(sum(dat[[paste0("unit_", u)]], na.rm = TRUE), 1.0,
      tolerance = 1e-9, info = paste("unit", u))
  }
})

test_that("raw WTC units reproduce S1 diversity exactly (8/8)", {
  dat <- tryCatch(.load_raw_wtc(), error = function(e) NULL)
  skip_if(is.null(dat), "raw WTC data not bundled")
  for (u in names(.s1_diversity)) {
    D <- .diversity_of(dat[[paste0("unit_", u)]])
    expect_equal(D, .s1_diversity[[u]], tolerance = 1e-6, info = paste("unit", u))
  }
})

test_that("raw WTC duplicate G row is the missing J (data hygiene)", {
  dat <- tryCatch(.load_raw_wtc(), error = function(e) NULL)
  skip_if(is.null(dat), "raw WTC data not bundled")
  types <- dat[[1]]
  expect_equal(sum(tolower(types) == "g"), 2) # G duplicated; 'J' absent
  expect_false("J" %in% types)                 # confirms the typo hypothesis
})