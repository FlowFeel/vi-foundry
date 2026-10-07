#!/usr/bin/env Rscript
# Assemble B1 proof object from staged M1/M2 fits (crash-safe reassembly)
suppressPackageStartupMessages({library(brms); library(rstan)})
m1 <- readRDS("vi-foundry/results/bg_p4_m1.rds")
m2 <- readRDS("vi-foundry/results/bg_p4_m2.rds")

p1 <- brms::posterior_summary(m1); p2 <- brms::posterior_summary(m2)
rh1 <- brms::rhat(m1); rh2 <- brms::rhat(m2)

vf1 <- p1["sd_family__Intercept", "Estimate"]^2
vf2 <- p2["sd_family__Intercept", "Estimate"]^2
icc1 <- vf1/(vf1+pi^2/3); icc2 <- vf2/(vf2+pi^2/3)
sp <- p2["b_spatial_lag", ]

b1 <- list(
  values = list(
    model1 = list(family_var = vf1, icc_family = icc1),
    model2 = list(family_var = vf2, icc_family = icc2,
                  spatial_lag_beta = sp[["Estimate"]],
                  spatial_lag_ci = c(sp[["Q2.5"]], sp[["Q97.5"]])),
    variance_decomposition = list(
      phylogeny = icc2,
      geography = icc1 - icc2,
      residual = 1 - icc1,
      family_var_reduction_pct = (vf1 - vf2)/vf1 * 100)
  ),
  metadata = list(seed = 42L, n_languages = 2187L, n_p4 = 26L, n_families = 196L,
                  spatial_cutoff_km = 2000, iter = 2000L, warmup = 1000L,
                  rhat_max_m1 = round(max(rh1, na.rm=TRUE), 4),
                  rhat_max_m2 = round(max(rh2, na.rm=TRUE), 4),
                  converged = max(rh1, na.rm=TRUE) < 1.05 && max(rh2, na.rm=TRUE) < 1.05,
                  timestamp = format(Sys.time(), "%Y-%m-%d %H:%M:%S UTC"))
)
saveRDS(b1, "vi-foundry/results/bg_p4_spatiophylo.rds")

# Human-readable summary to file (file-first)
con <- file("vi-foundry/results/bg_p4_b1_summary.txt", "w")
writeLines(c(
  "B1 Spatiophylogenetic (brms, seed=42, 2187 langs, 26 P4, 196 families)",
  sprintf("Model1 family var=%.3f  ICC=%.3f", vf1, icc1),
  sprintf("Model2 family var=%.3f  ICC=%.3f", vf2, icc2),
  sprintf("Family-variance reduction: %.1f%%", (vf1-vf2)/vf1*100),
  sprintf("Spatial lag beta=%.3f [%.3f, %.3f]", sp[["Estimate"]], sp[["Q2.5"]], sp[["Q97.5"]]),
  sprintf("Decomposition: phylogeny=%.3f geography=%.3f residual=%.3f",
          icc2, icc1-icc2, 1-icc1),
  sprintf("Converged: %s (Rhat max m1=%.4f m2=%.4f)", b1$metadata$converged,
          b1$metadata$rhat_max_m1, b1$metadata$rhat_max_m2)), con)
close(con)
cat(readLines("vi-foundry/results/bg_p4_b1_summary.txt"), sep="\n")
