#!/usr/bin/env Rscript
# run_bgsh_replication.R — Foundry replication of Ritch-Frel & Phillips (2026)
# "Body-part reflexives and body-zone classification"
# Bayesian GLMM: HEAD→SELF clustering in the Caucasus
#
# Requires: Grambank CLDF at data/glottobank/grambank/grambank_extracted/
#           brms, rstan, tidyverse
#
# Usage: Rscript vi-foundry/scripts/run_bgsh_replication.R

library(bayesplot)
library(ggplot2)
library(ape)
library(dplyr)
library(tidyr)

# ── Config ──────────────────────────────────────────────────────────────
GB_DIR <- "/home/node/.openclaw/workspace/data/glottobank/grambank/grambank_extracted/grambank-grambank-7ae000c/cldf"
OUT_DIR <- "/home/node/.openclaw/workspace/vi-foundry/data/output/bgsh-replication"
dir.create(OUT_DIR, showWarnings = FALSE, recursive = TRUE)

# ── 1. Load Grambank CLDF ──────────────────────────────────────────────
cat("=== BGSH Foundry Replication ===\n\n")
cat("Reading Grambank CLDF...\n")

langs <- read.csv(file.path(GB_DIR, "languages.csv"), stringsAsFactors = FALSE)
fams <- read.csv(file.path(GB_DIR, "families.csv"), stringsAsFactors = FALSE)
params <- read.csv(file.path(GB_DIR, "parameters.csv"), stringsAsFactors = FALSE)
values <- read.csv(file.path(GB_DIR, "values.csv"), stringsAsFactors = FALSE)

cat(sprintf("  Languages: %d\n", nrow(langs)))
cat(sprintf("  Families:  %d\n", nrow(fams)))
cat(sprintf("  Features:  %d\n", nrow(params)))
cat(sprintf("  Values:    %d\n", nrow(values)))

# ── 2. Extract GB305 (independent reflexive pronoun) ──────────────────
# GB305: "Is there a phonologically independent reflexive pronoun?"
gb305 <- values %>% filter(Parameter_ID == "GB305")
cat(sprintf("\nGB305 (independent reflexive pronoun): %d values\n", nrow(gb305)))
table(gb305$Value) %>% print()

# ── 3. Build family-level dataset ──────────────────────────────────────
# Each language belongs to a Glottolog family (Family_level_ID in Grambank)

# Merge language → family
lang_fam <- langs %>%
  filter(Family_level_ID != "") %>%
  select(Language_ID = ID, Family_level_ID, Name, 
         Latitude, Longitude)

# Merge GB305 into family-level: does the family have any language
# with independent reflexive (GB305=1)?
fam_data <- lang_fam %>%
  left_join(gb305 %>% select(Language_ID, GB305_val = Value), by = "Language_ID") %>%
  mutate(has_reflexive = GB305_val == "1") %>%
  group_by(Family_level_ID) %>%
  summarise(
    n_langs = n(),
    n_reflexive = sum(has_reflexive, na.rm = TRUE),
    pct_reflexive = mean(has_reflexive, na.rm = TRUE),
    avg_lat = mean(Latitude, na.rm = TRUE),
    avg_lon = mean(Longitude, na.rm = TRUE),
    .groups = "drop"
  )

fam_data <- fam_data %>% filter(n_langs > 0)
cat(sprintf("\nFamilies with GB305 data: %d\n", nrow(fam_data)))

# ── 4. Caucasus families ──────────────────────────────────────────────
# Grambank codes 7 families with members in Caucasus
# These are identified by the paper from Grambank.
# Map Glottolog family IDs to the paper's family names
fams_lookup <- read.csv(file.path(GB_DIR, "families.csv"), stringsAsFactors = FALSE)

# From the paper: 7 Grambank families covering Caucasus area
# We identify Caucasus families as those whose average member lat/lon
# falls within Caucasus region (lat 38-46°N, lon 36-50°E)
caucasus_langs <- lang_fam %>%
  filter(Latitude >= 38, Latitude <= 46, 
         Longitude >= 36, Longitude <= 50)

caucasus_fams <- unique(caucasus_langs$Family_level_ID)
cat(sprintf("Caucasus languages in GramBank: %d\n", nrow(caucasus_langs)))
cat(sprintf("Caucasus families: %d\n", length(caucasus_fams)))
cat(sprintf("  -> %s\n", paste(caucasus_fams, collapse = ", ")))

fam_data <- fam_data %>%
  mutate(
    caucasus = Family_level_ID %in% caucasus_fams
  )

cat(sprintf("\nCaucasus families in dataset: %d\n", sum(fam_data$caucasus)))
cat("Families:\n")
fam_data %>% filter(caucasus) %>% select(Family_level_ID, n_langs, n_reflexive, pct_reflexive) %>% print()

# ── 5. HEAD→SELF (body-part-derived reflexive) family coding ──────────
cat("\n── HEAD→SELF (bpdr) family coding ──\n")
cat("Paper identifies these families with head-body-part-derived reflexives:\n")
cat("  Kartvelian, Northwest Caucasian, (Nakh-Daghestanian via Batsbi contact),\n")
cat("  Afro-Asiatic (all branches), plus Basque isolate, and others from\n")
cat("  Evseeva & Salaberri (2018) catalog (75 languages, 27/196 families globally).\n")
cat("\nThe Evseeva & Salaberri 2018 catalog is referenced as Supplementary Data\n")
cat("tables S1-S3 (v4 preprint) but is NOT present on disk at this path.\n")
cat("The bpdr variable requires: 27 family-level entries from the catalog\n")
cat("cross-referenced with Grambank Glottolog family IDs.\n")
cat("\nUsing GramBank GB305 (independent reflexive) as a proxy variable for\n")
cat("demonstration purposes. GB305 is coarser: it captures ANY independent\n")
cat("reflexive pronoun, not specifically body-part-derived ones.\n")

# Proxy: family has at least one language with GB305 = 1
fam_data <- fam_data %>%
  mutate(bpdr_proxy = n_reflexive > 0)

# Fisher's exact test on proxy
ct_proxy <- table(fam_data$bpdr_proxy, fam_data$caucasus)
cat("\n── Fisher's exact test (GB305 proxy) ──\n")
cat(sprintf("Contingency table:\n"))
print(ct_proxy)
ft_proxy <- fisher.test(ct_proxy, alternative = "two.sided")
cat(sprintf("OR = %.2f; p = %.4f\n", ft_proxy$estimate, ft_proxy$p.value))
cat(sprintf("95 CI: [%.2f, %.2f]\n", ft_proxy$conf.int[1], ft_proxy$conf.int[2]))

# ── 6. Bayesian GLMM ─────────────────────────────────────────────────
cat("\n── Bayesian GLMM (brms/rstan) ──\n")
cat("Formula: bpdr_proxy ~ caucasus + lat_c + lon_c + (1|Family_level_ID)\n")
cat("Family: Bernoulli(link=logit)\n")
cat("Priors: Normal(0, 1.5) for betas; Exponential(1) for sigma\n")
cat("4 chains x 500 tuning + 1000 draws\n\n")

# Prepare data for model
model_data <- fam_data %>%
  mutate(
    lat_c = as.numeric(scale(avg_lat)),
    lon_c = as.numeric(scale(avg_lon)),
    caucasus_num = as.numeric(caucasus),
    family = Family_level_ID
  )

# Standardize response
library(brms)
options(mc.cores = 4)

cat("Compiling and sampling (this takes ~2-5 min)...\n")
flush.console()

t0 <- Sys.time()
fit <- brm(
  bpdr_proxy ~ caucasus + lat_c + lon_c + (1 | family),
  data = model_data,
  family = bernoulli(link = "logit"),
  prior = c(
    prior(normal(0, 1.5), class = "b"),
    prior(exponential(1), class = "sd")
  ),
  chains = 4,
  iter = 1000 + 500,  # 500 warmup, 1000 sampling
  warmup = 500,
  refresh = 0,
  seed = 2026
)
elapsed <- as.numeric(difftime(Sys.time(), t0, units = "secs"))

cat(sprintf("\nFit complete: %.0fs\n", elapsed))
cat("Summary:\n")
s <- summary(fit)
print(s)

# Extract ORs
fixef_df <- as.data.frame(s$fixed)
fixef_df$OR <- exp(fixef_df$Estimate)
fixef_df$OR_lower <- exp(fixef_df$`l-95% CI`)
fixef_df$OR_upper <- exp(fixef_df$`u-95% CI`)

cat("\n── Odds Ratios ──\n")
cat(sprintf("Intercept (baseline): OR = %.2f [%.2f, %.2f]\n",
            fixef_df["Intercept","OR"], fixef_df["Intercept","OR_lower"], fixef_df["Intercept","OR_upper"]))
cat(sprintf("Caucasus: OR = %.2f [%.2f, %.2f]\n",
            fixef_df["caucasusTRUE","OR"], fixef_df["caucasusTRUE","OR_lower"], fixef_df["caucasusTRUE","OR_upper"]))

# Posterior probability that caucasus > 0
post <- as_draws_df(fit)
caucasus_draws <- post$b_caucasusTRUE
p_pos <- mean(caucasus_draws > 0)
cat(sprintf("P(Caucasus effect > 0) = %.3f (%.1f%%)\n", p_pos, p_pos * 100))

cat(sprintf("min ESS = %.0f; max Rhat = %.3f\n", 
            min(s$fit_summary[,"n_eff"], na.rm = TRUE),
            max(s$fit_summary[,"Rhat"], na.rm = TRUE)))

# Save
png(file.path(OUT_DIR, "caucasus_effect.png"), width = 8, height = 6, units = "in", res = 150)
  mcmc_areas(post, pars = c("b_caucasusTRUE"), prob = 0.95) +
    ggtitle("Caucasus effect on independent reflexive pronoun (GB305 proxy)\nPosterior distribution") +
    xlab("Log-odds (caucasusTRUE)") +
    geom_vline(xintercept = 0, linetype = "dashed", alpha = 0.5)
dev.off()
cat("Saved: caucasus_effect.png\n")

# ── 7. Summary vs paper ──────────────────────────────────────────────
cat("\n── Comparison with published results ──\n")
cat("Paper (lt-submission):\n")
cat("  Model: Bayesian GLMM brms/rstan, Bernoulli(link=logit)\n")
cat("  Formula: bpdr ~ caucasus + lat_c + lon_c + (1|family)\n")
cat("  OR = 10.30, 95% CI [1.82, 55.86]\n")
cat("  P(Caucasus > 0) = 0.994\n")
cat("  min ESS = 1067, max Rhat = 1.00\n\n")
cat("Foundry run (GB305 proxy):\n")
cat(sprintf("  OR = %.2f, 95%% CI [%.2f, %.2f]\n",
            fixef_df["caucasusTRUE","OR"], fixef_df["caucasusTRUE","OR_lower"], fixef_df["caucasusTRUE","OR_upper"]))
cat(sprintf("  P(Caucasus > 0) = %.3f\n", p_pos))

cat("\n── Required: Evseeva & Salaberri (2018) catalog ──\n")
cat("The bpdr variable (27/196 families with HEAD→SELF) requires\n")
cat("cross-referencing the Evseeva-Salaberri 75-language catalog\n")
cat("with Grambank family classifications. File not found on disk.\n")
cat("GB305 (independent reflexive pronoun) is used as a proxy above.\n")
cat("With the actual bpdr data, the GLMM should reproduce OR=10.30.\n\n")

cat("=== BGSH Foundry Replication Complete ===\n")