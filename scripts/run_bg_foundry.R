#!/usr/bin/env Rscript
# Body-Grammar Foundry Pipeline Runner
# Runs all P4 (HEAD→SELF) analyses through vi-foundry infrastructure.
#
# Usage: Rscript scripts/run_bg_foundry.R
#
# DFT A3: manifest conformance — pipeline.yml declares these stages

suppressPackageStartupMessages({
  library(ape)
  library(lme4)
  library(brms)
  library(rstan)
})

source("vi-foundry/R/body_grammar_loaders.R")
source("vi-foundry/R/body_grammar.R")

SEED <- 42L

cat("=== Body-Grammar Foundry Pipeline ===\n")
cat("Seed:", SEED, "\n\n")

# ──────────────────────────────────────────────────────────
# Stage: Load reflexives
# ──────────────────────────────────────────────────────────
cat("[bg_load_reflexives] Loading S_source_typed_reflexives...\n")
reflex <- load_reflexive_sources()
cat("  N:", reflex$n, "| HEAD:", reflex$n_head, "| BODY:", reflex$n_body, "\n")

# ──────────────────────────────────────────────────────────
# Stage: Load GB305
# ──────────────────────────────────────────────────────────
cat("[bg_load_gb305] Loading GramBank GB305...\n")
gb305 <- load_grambank_gb305()
cat("  N:", gb305$n, "\n")

# ──────────────────────────────────────────────────────────
# Stage: Build analysis dataframe
# ──────────────────────────────────────────────────────────
cat("[bg_build_dataframe] Merging reflexives × GB305...\n")
analysis_df <- build_p4_analysis_dataframe(reflex, gb305, remove_contaminated = TRUE)
cat("  N:", nrow(analysis_df), "| P4=1:", sum(analysis_df$p4 == 1), "\n")

# ──────────────────────────────────────────────────────────
# Stage: B5 — Ancestral State Reconstruction
# ──────────────────────────────────────────────────────────
cat("\n[B5: Ancestral Reconstruction] Building family trees...\n")
# Load Glottolog families
families_csv <- file.path("data", "glottobank", "grambank",
                           "grambank_extracted", "grambank-grambank-7ae000c",
                           "cldf", "families.csv")
if (file.exists(families_csv)) {
  families_raw <- read.csv(families_csv, stringsAsFactors = FALSE)
  family_trees <- list()
  for (i in seq_len(nrow(families_raw))) {
    tree_text <- families_raw$Newick[i]
    valid_tree <- !is.na(tree_text) && length(tree_text) > 0 && nchar(trimws(as.character(tree_text))) > 0 && !grepl("Not Found", trimws(as.character(tree_text)))
    if (!valid_tree) next
    fam_name <- families_raw$ID[i]; if (is.na(fam_name) || nchar(fam_name) == 0) fam_name <- paste("Unknown_", i, sep="")
    tree_parsed <- tryCatch(ape::read.tree(text = tree_text), error = function(e) NULL)
    if (!is.null(tree_parsed)) {
      family_trees[[fam_name]] <- tree_parsed
    }
  }
  cat("  Parsed", length(family_trees), "family trees\n")

  # Map to families via Glottolog language-level IDs
  languages_csv <- file.path("data", "glottobank", "grambank",
                              "grambank_extracted", "grambank-grambank-7ae000c",
                              "cldf", "languages.csv")
  languages <- read.csv(languages_csv, stringsAsFactors = FALSE)

  # Map tree names (family glottocodes) to family names used in trait_matrix
  fam_id_to_name <- setNames(languages$Family_name, languages$Family_level_ID)
  names(family_trees) <- ifelse(is.na(fam_id_to_name[names(family_trees)]),
                                 names(family_trees),
                                 fam_id_to_name[names(family_trees)])
  family_trees <- family_trees[!duplicated(names(family_trees))]

  # Prepare trait matrix from reflexive data
  reflex_df <- reflex$data
  reflex_df$p4 <- as.integer(reflex_df$source_type == "HEAD")
  contaminated <- c("oloo1241", "kaba1281", "shee1238",
                     "kuna1268", "bamu1253", "marg1265", "huuu1240")
  reflex_df <- reflex_df[!reflex_df$glottocode %in% contaminated, ]

  lang_family <- languages[, c("ID", "Family_name")]
  colnames(lang_family) <- c("glottocode", "family")

  trait_matrix <- merge(reflex_df[, c("glottocode", "p4")],
                         lang_family, by = "glottocode", all.x = TRUE)
  colnames(trait_matrix)[1] <- "taxon"
  names(trait_matrix)[names(trait_matrix) == "p4"] <- "trait"
  trait_matrix$family[is.na(trait_matrix$family) | trait_matrix$family == ""] <- "Isolate"

  b5 <- p4_ancestral_reconstruction(trait_matrix, family_trees, seed = SEED)
  cat("  Families with ace:", b5$metadata$n_ace_run, "\n")
  cat("  Ancestral (>50% root):", b5$metadata$n_ancestral, "\n")
  cat("  Families with P4:", length(unique(trait_matrix$family[trait_matrix$trait == 1])), "\n")
  saveRDS(b5, file.path("vi-foundry", "results", "bg_p4_ancestral.rds"))
} else {
  cat("  No families.csv — skipping B5\n")
}

# ──────────────────────────────────────────────────────────
# Stage: B3 — GLMM Robustness Jackknife
# ──────────────────────────────────────────────────────────
cat("\n[B3: Robustness] Leave-one-family-out jackknife...\n")
p4_glmm_data <- analysis_df[, c("language_id", "p4", "Family_name")]
names(p4_glmm_data)[names(p4_glmm_data) == "Family_name"] <- "family"
p4_glmm_data$family <- as.factor(p4_glmm_data$family)
p4_families <- unique(p4_glmm_data$family[p4_glmm_data$p4 == 1])
cat("  Families with P4:", length(p4_families), "\n")

b3 <- p4_robustness_jackknife(p4_glmm_data, seed = SEED)
cat("  Scenarios:", b3$metadata$n_scenarios, "\n")
cat("  Survived:", b3$metadata$n_survived, "\n")
saveRDS(b3, file.path("vi-foundry", "results", "bg_p4_robustness.rds"))

# ──────────────────────────────────────────────────────────
# Stage: B4 — aDNA Correlation
# ──────────────────────────────────────────────────────────
cat("\n[B4: aDNA Correlation] CHG × P4...\n")
chg <- load_chg_admixture()
cat("  Populations:", chg$n, "\n")

b4 <- p4_adna_correlation(chg$data, seed = SEED)
cat("  CHG coefficient:", b4$values$logistic_fit$chg_coefficient, "\n")
cat("  CHG p-value:", b4$values$logistic_fit$chg_p, "\n")
saveRDS(b4, file.path("vi-foundry", "results", "bg_p4_adna.rds"))

# ──────────────────────────────────────────────────────────
# Stage: B1 — Spatiophylogenetic GLMM
# ──────────────────────────────────────────────────────────
cat("\n[B1: Spatiophylogenetic] Bayesian GLMM (brms)...\n")
p4_spatial_data <- analysis_df[complete.cases(analysis_df$Latitude, analysis_df$Longitude), ]
names(p4_spatial_data)[names(p4_spatial_data) == "Family_name"] <- "family"
p4_spatial_data$macroarea <- p4_spatial_data$Macroarea
names(p4_spatial_data)[names(p4_spatial_data) == "Latitude"] <- "latitude"
names(p4_spatial_data)[names(p4_spatial_data) == "Longitude"] <- "longitude"
cat("  Languages with coordinates:", nrow(p4_spatial_data), "\n")
cat("  P4=1:", sum(p4_spatial_data$p4 == 1), "\n")
cat("  Families:", length(unique(p4_spatial_data$family)), "\n")

# Stage 1: fit model1 only, save immediately (crash-safe)
cat("  Fitting Model 1 (phylogeny only)...\n")
p4_spatial_data$family <- as.factor(p4_spatial_data$family)
p4_spatial_data$macroarea <- as.factor(p4_spatial_data$macroarea)
p4_spatial_data <- p4_spatial_data[complete.cases(p4_spatial_data$latitude, p4_spatial_data$longitude), ]
coords <- as.matrix(p4_spatial_data[, c("longitude", "latitude")])
dist_km <- geosphere::distm(coords) / 1000
weights <- 1 / dist_km
weights[dist_km > 2000 | dist_km == 0] <- 0
diag(weights) <- 0
row_norm <- weights / rowSums(weights, na.rm = TRUE)
row_norm[is.nan(row_norm)] <- 0
p4_spatial_data$spatial_lag <- as.vector(row_norm %*% p4_spatial_data$p4)

m1 <- brms::brm(
  brms::brmsformula(p4 ~ macroarea + (1 | family)),
  data = p4_spatial_data, family = brms::bernoulli(link = "logit"),
  prior = c(brms::set_prior("normal(-4, 2)", class = "Intercept"),
            brms::set_prior("normal(0, 2)", class = "b"),
            brms::set_prior("student_t(3, 0, 2.5)", class = "sd")),
  chains = 4L, iter = 2000L, warmup = 1000L, seed = SEED, refresh = 100,
  control = list(adapt_delta = 0.95), silent = 0, backend = "rstan"
)
saveRDS(m1, file.path("vi-foundry", "results", "bg_p4_m1.rds"))
cat("  Model 1 saved.\n")

# Stage 2: model2 with spatial lag, save immediately
cat("  Fitting Model 2 (+ spatial lag)...\n")
m2 <- brms::brm(
  brms::brmsformula(p4 ~ macroarea + spatial_lag + (1 | family)),
  data = p4_spatial_data, family = brms::bernoulli(link = "logit"),
  prior = c(brms::set_prior("normal(-4, 2)", class = "Intercept"),
            brms::set_prior("normal(0, 2)", class = "b"),
            brms::set_prior("student_t(3, 0, 2.5)", class = "sd")),
  chains = 4L, iter = 2000L, warmup = 1000L, seed = SEED + 1L, refresh = 100,
  control = list(adapt_delta = 0.95), silent = 0, backend = "rstan"
)
saveRDS(m2, file.path("vi-foundry", "results", "bg_p4_m2.rds"))
cat("  Model 2 saved.\n")

# Assemble B1 proof object from staged fits
var_family1 <- as.numeric(brms::VarCorr(m1)$family$sd[1])^2
var_family2 <- as.numeric(brms::VarCorr(m2)$family$sd[1])^2
spat_fix <- brms::fixef(m2)["spatial_lag", ]
b1 <- list(
  values = list(
    model1 = list(family_var = var_family1,
                  icc_family = var_family1 / (var_family1 + pi^2/3)),
    model2 = list(family_var = var_family2,
                  icc_family = var_family2 / (var_family2 + pi^2/3),
                  spatial_lag_beta = spat_fix[["Estimate"]],
                  spatial_lag_ci = c(spat_fix[["Q2.5"]], spat_fix[["Q97.5"]])),
    variance_decomposition = list(
      phylogeny = var_family2 / (var_family2 + pi^2/3),
      geography = var_family1/(var_family1 + pi^2/3) - var_family2/(var_family2 + pi^2/3),
      residual = 1 - var_family1/(var_family1 + pi^2/3),
      family_var_reduction_pct = (var_family1 - var_family2) / var_family1 * 100)
  ),
  metadata = list(seed = SEED, n_languages = nrow(p4_spatial_data),
                  n_p4 = sum(p4_spatial_data$p4 == 1),
                  n_families = length(unique(p4_spatial_data$family)),
                  spatial_cutoff_km = 2000, iter = 2000L, warmup = 1000L,
                  converged = all(rstan::summary(m1)$summary[, "Rhat"] < 1.05, na.rm = TRUE) &&
                               all(rstan::summary(m2)$summary[, "Rhat"] < 1.05, na.rm = TRUE),
                  timestamp = format(Sys.time(), "%Y-%m-%d %H:%M:%S UTC"))
)
cat("  Family var reduction:", round(b1$values$variance_decomposition$family_var_reduction_pct, 1), "%\n")
cat("  Spatial lag β:", round(b1$values$model2$spatial_lag_beta, 4), "\n")
cat("  Moran's I:", round(b1$values$spatial$i, 4), "\n")
cat("  Converged:", b1$metadata$converged, "\n")
saveRDS(b1, file.path("vi-foundry", "results", "bg_p4_spatiophylo.rds"))

# ──────────────────────────────────────────────────────────
# Summary
# ──────────────────────────────────────────────────────────
cat("\n=== Pipeline Complete ===\n")
cat("Outputs:\n")
for (f in c("bg_p4_ancestral.rds", "bg_p4_robustness.rds",
            "bg_p4_adna.rds", "bg_p4_spatiophylo.rds")) {
  fp <- file.path("results", f)
  if (file.exists(fp)) cat("  ✓", fp, "\n") else cat("  ✗", fp, "\n")
}
cat("Timestamp:", format(Sys.time(), "%Y-%m-%d %H:%M:%S UTC"), "\n")