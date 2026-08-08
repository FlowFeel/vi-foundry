# test-unit-contracts.R — Unit tests for contract validators
# DFT A1: pure functions, no I/O, deterministic
# Tests: valid input → TRUE, invalid input → specific error

library(testthat)

context("Contract validators")

# === validate_phylo_tree ===

test_that("validate_phylo_tree accepts valid Newick string", {
  tree <- "(A:0.1,(B:0.2,C:0.3):0.1);"
  expect_invisible(validate_phylo_tree(tree))
  expect_true(validate_phylo_tree(tree))
})

test_that("validate_phylo_tree rejects non-character input", {
  expect_error(validate_phylo_tree(123), "must be a single character")
  expect_error(validate_phylo_tree(NULL), "must be a single character")
  expect_error(validate_phylo_tree(c("a", "b")), "must be a single character")
})

test_that("validate_phylo_tree rejects empty string", {
  expect_error(validate_phylo_tree(""), "must not be empty")
})

test_that("validate_phylo_tree rejects non-Newick format", {
  expect_error(validate_phylo_tree("not a tree"), "must start with '\\('")
  expect_error(validate_phylo_tree("(A, B, C)", ), "must end with ';'")
})

test_that("validate_phylo_tree enforces minimum taxa", {
  # 2 taxa — should fail with min_taxa=3
  expect_error(
    validate_phylo_tree("(A:0.1,B:0.2);", min_taxa = 3L),
    "need >= 3"
  )
})

# === validate_plastome_data ===

test_that("validate_plastome_data accepts valid data frame", {
  data <- data.frame(
    species = c("A", "B", "C"),
    plastome_size_kb = c(150.0, 100.0, 50.0),
    parasitism_score = c(0, 1, 2)
  )
  expect_true(validate_plastome_data(data))
})

test_that("validate_plastome_data rejects missing columns", {
  data <- data.frame(species = c("A"), size = c(100))
  expect_error(validate_plastome_data(data), "missing required columns")
})

test_that("validate_plastome_data rejects negative values", {
  data <- data.frame(
    species = c("A", "B", "C"),
    plastome_size_kb = c(-10, 100, 50),
    parasitism_score = c(0, 1, 2)
  )
  expect_error(validate_plastome_data(data), "non-negative")
})

test_that("validate_plastome_data rejects too few rows", {
  data <- data.frame(
    species = c("A", "B"),
    plastome_size_kb = c(100, 50),
    parasitism_score = c(0, 1)
  )
  expect_error(validate_plastome_data(data), "need >= 3")
})

# === validate_parasitism_scores ===

test_that("validate_parasitism_scores accepts valid scores", {
  expect_true(validate_parasitism_scores(c(0, 1, 2, 3, 4)))
})

test_that("validate_parasitism_scores rejects out-of-range values", {
  expect_error(validate_parasitism_scores(c(-1, 2)), "range")
  expect_error(validate_parasitism_scores(c(0, 5)), "range")
})

test_that("validate_parasitism_scores rejects non-integers", {
  expect_error(validate_parasitism_scores(c(0, 1.5, 2)), "integers")
})

# === validate_endosymbiont_data ===

test_that("validate_endosymbiont_data accepts valid data", {
  data <- data.frame(
    species = c("A", "B"),
    genome_bp = c(500000, 400000),
    aa_pathways_retained = c(10, 8),
    symbiosis_age_mya = c(100, 200)
  )
  expect_true(validate_endosymbiont_data(data))
})

test_that("validate_endosymbiont_data rejects missing columns", {
  data <- data.frame(species = c("A"), genome_bp = c(100))
  expect_error(validate_endosymbiont_data(data), "missing required columns")
})

test_that("validate_endosymbiont_data rejects non-positive genome sizes", {
  data <- data.frame(
    species = c("A"),
    genome_bp = c(0),
    aa_pathways_retained = c(10),
    symbiosis_age_mya = c(100)
  )
  expect_error(validate_endosymbiont_data(data), "positive")
})

# === validate_gene_categories ===

test_that("validate_gene_categories accepts valid data", {
  data <- data.frame(
    category = c("ndh", "rpo", "psa"),
    dependency_score = c(0, 1, 1),
    orobanchaceae_loss_rank = c(1, 2, 2)
  )
  expect_true(validate_gene_categories(data))
})

test_that("validate_gene_categories rejects missing loss rank column", {
  data <- data.frame(
    category = c("ndh"),
    dependency_score = c(0)
  )
  expect_error(validate_gene_categories(data), "loss_rank")
})

test_that("validate_gene_categories rejects negative dependency scores", {
  data <- data.frame(
    category = c("ndh"),
    dependency_score = c(-1),
    orobanchaceae_loss_rank = c(1)
  )
  expect_error(validate_gene_categories(data), "non-negative")
})

# === validate_bird_morphology ===

test_that("validate_bird_morphology accepts valid data", {
  data <- data.frame(
    structure = c(
      "wing", "keel", "pectoral", "hindlimb", "pelvis",
      "feathers", "wing_bones", "asymmetry"
    ),
    dependency_score = c(0, 1, 0.5, 4, 3, 5, 1.5, 1),
    observed_rank = c(1, 2, 3, 4, 5, 6, 7, 8)
  )
  expect_true(validate_bird_morphology(data))
})

test_that("validate_bird_morphology rejects too few structures", {
  data <- data.frame(
    structure = c("a", "b"),
    dependency_score = c(0, 1),
    observed_rank = c(1, 2)
  )
  expect_error(validate_bird_morphology(data), "need >= 5")
})

test_that("validate_bird_morphology rejects ranks < 1", {
  data <- data.frame(
    structure = c("a", "b", "c", "d", "e"),
    dependency_score = c(0, 1, 2, 3, 4),
    observed_rank = c(0, 1, 2, 3, 4)
  )
  expect_error(validate_bird_morphology(data), ">= 1")
})

# === validate_niche_data ===

test_that("validate_niche_data accepts valid data", {
  data <- data.frame(
    Species = rep("A", 15),
    Ne = rnorm(15, 1e6, 1e5),
    Lifestyle = rep("Free", 15)
  )
  expect_true(validate_niche_data(data))
})

test_that("validate_niche_data rejects missing Ne column", {
  data <- data.frame(species = 1:15, lifestyle = rep("x", 15))
  expect_error(validate_niche_data(data), "Ne")
})

test_that("validate_niche_data rejects too few rows", {
  data <- data.frame(Ne = 1:5, Lifestyle = rep("x", 5))
  expect_error(validate_niche_data(data), ">= 10")
})

# === validate_pangenome_data ===

test_that("validate_pangenome_data accepts valid data", {
  data <- data.frame(
    pangenome_fluidity = c(0.1, 0.2, 0.3),
    Host_or_free = c("Host", "Free", "Both")
  )
  expect_true(validate_pangenome_data(data))
})

test_that("validate_pangenome_data rejects out-of-range fluidity", {
  data <- data.frame(
    pangenome_fluidity = c(1.5, 0.2, 0.3),
    Host_or_free = c("Host", "Free", "Both")
  )
  expect_error(validate_pangenome_data(data), "\\[0, 1\\]")
})

test_that("validate_pangenome_data rejects missing fluidity column", {
  data <- data.frame(Host_or_free = c("Host", "Free"))
  expect_error(validate_pangenome_data(data), "pangenome_fluidity")
})

# === validate_result ===

test_that("validate_result accepts valid result object", {
  result <- list(
    values = c(beta = -23.5, r_squared = 0.652),
    metadata = list(seed = 42L, n = 12L)
  )
  expect_true(validate_result(result))
})

test_that("validate_result rejects missing values", {
  expect_error(
    validate_result(list(metadata = list())),
    "must contain 'values'"
  )
})

test_that("validate_result rejects missing metadata", {
  expect_error(
    validate_result(list(values = c(1, 2))),
    "must contain 'metadata'"
  )
})

test_that("validate_result warns on missing seed", {
  result <- list(values = c(1), metadata = list(n = 10))
  expect_warning(validate_result(result), "seed")
})

test_that("validate_result warns on missing n", {
  result <- list(values = c(1), metadata = list(seed = 42L))
  expect_warning(validate_result(result), "n")
})
