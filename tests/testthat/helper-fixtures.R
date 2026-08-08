# helper-fixtures.R — Shared test fixtures for VI foundry
#
# DFT A5: Real in-process fakes, not mocks.
# fake_data_loader returns real dataframes from in-memory fixtures.

library(testthat)

# Small deterministic fixtures for unit tests
.fixture_orobanchaceae <- data.frame(
  species = c("Lindenbergia", "Schwalbea", "Orobanche", "Phelipanche", "Conopholis"),
  plastome_size_kb = c(150.0, 120.0, 100.0, 75.0, 50.0),
  parasitism_score = c(0L, 1L, 2L, 3L, 4L),
  family = rep("Orobanchaceae", 5),
  stringsAsFactors = FALSE
)

.fixture_gene_categories <- data.frame(
  category = c("ndh", "rpo", "psa", "psb", "atp", "rpl_rps"),
  dependency_score = c(0, 1, 1, 2, 3, 5),
  orobanchaceae_loss_rank = c(1, 2, 2, 2, 3, 4),
  cuscuta_loss_rank = c(1, 2, 3, 4, 5, 6),
  stringsAsFactors = FALSE
)

.fixture_bird_morphology <- data.frame(
  structure = c(
    "wing_prop", "pectoral_muscle", "sternal_keel",
    "wing_bones", "hindlimb", "pelvic_girdle",
    "feather_asymmetry", "feather_structure"
  ),
  dependency_score = c(0.0, 0.5, 1.0, 1.5, 4.0, 3.0, 1.0, 5.0),
  observed_rank = c(1, 3, 2, 4, 5, 6, 7, 8),
  stringsAsFactors = FALSE
)

# fake_data_loader — returns real dataframes, not mock recordings
fake_data_loader <- R6::R6Class(
  "fake_data_loader",
  public = list(
    load = function(name) {
      switch(name,
        orobanchaceae = .fixture_orobanchaceae,
        gene_categories = .fixture_gene_categories,
        bird_morphology = .fixture_bird_morphology,
        stop("Unknown fixture: ", name, call. = FALSE)
      )
    },
    list_available = function() {
      c("orobanchaceae", "gene_categories", "bird_morphology")
    }
  )
)$new()
