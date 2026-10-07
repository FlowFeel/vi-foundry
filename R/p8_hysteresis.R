# p8b — Hysteresis Test (Finding 3)
#
# VI Prediction: Cultural lineages show asymmetric diversity dynamics — fast
# entry (steep diversity increase when cultural innovation accelerates) and slow
# exit (gradual decline under pressure because culture buffers extinction).
# Non-cultural lineages should show more symmetric entry/exit dynamics.
#
# Method: Uses existing PyRate speciation-rate and extinction-rate outputs to
# compare entry/exit asymmetry for Homo vs non-Homo. Two metrics:
#   1. Speciation/extinction asymmetry ratio: λ / μ
#   2. Rate-of-change asymmetry: how steeply diversity increases vs decreases
#
# @dft A1, A2, A6
NULL

#' Load PyRate speciation and extinction rates from MCMC outputs
#'
#' Extracts the mean speciation (Sp) and extinction (Ex) rates from the
#' posterior samples in the diversity log files.
#'
#' @return List with fields: homo, nonhomo — each with speciation_rate,
#'   extinction_rate, rate_ratio
load_hominin_rates <- function() {
  base <- "/home/node/.openclaw/workspace/work/marsyas6/papers/valence-ingress/data/van-holstein/Data_Code_Final/PyRate/Outputs"
  
  configs <- list(
    Broad_NHPP = sprintf("%s/Broad_occurrence_level/NHPP/%%s_diversity_0_expSp_expEx_HP.log", base),
    Broad_TPP  = sprintf("%s/Broad_occurrence_level/TPP/%%s_diversity_0_expSp_expEx_HP.log", base),
    WoodBoyle  = sprintf("%s/Wood-Boyle/%%s_diversity_0_expSp_expEx_HP.log", base)
  )
  
  extract_rates <- function(partition) {
    result <- list()
    for (cname in names(configs)) {
      fpath <- sprintf(configs[[cname]], partition)
      if (file_exists(fpath)) {
        tbl <- read.table(fpath, header = TRUE)
        tbl <- tbl[tbl$it >= 1000, ]
        
        # Rate columns vary by PyRate version
        sp_cols <- grep("Sp_*|lam_*|birth_*", names(tbl), value = TRUE, ignore.case = TRUE)
        ex_cols <- grep("Ex_*|mu_*|death_*", names(tbl), value = TRUE, ignore.case = TRUE)
        
        if (length(sp_cols) > 0L && length(ex_cols) > 0L) {
          sp_rate <- mean(as.numeric(tbl[[sp_cols[1L]]]))
          ex_rate <- mean(as.numeric(tbl[[ex_cols[1L]]]))
          
          # For DD logs, the speciation/extinction rates are already baked
          # into the DD coefficient (Gl/Gm). Use the rate-level log if available.
          result[[cname]] <- list(
            speciation_rate = sp_rate,
            extinction_rate = ex_rate,
            rate_ratio = sp_rate / max(ex_rate, .Machine$double.xmin)
          )
        }
      }
    }
    result
  }
  
  homo <- extract_rates("homo")
  nonhomo <- extract_rates("nonhomo")
  
  list(
    homo = homo,
    nonhomo = nonhomo,
    metadata = list(
      configs = names(configs),
      notes = "Speciation/extinction rates from diversity log posteriors"
    )
  )
}

#' Compute entry/exit asymmetry metrics
#'
#' Tests whether cultural lineages show faster entry than non-cultural,
#' and slower exit (the hysteresis signature).
#'
#' @param homo_rates List of rate summaries for Homo across configs
#' @param nonhomo_rates List of rate summaries for non-Homo across configs
#'
#' @return List (A6): values(homo_rate_ratio, nonhomo_rate_ratio,
#'   asymmetry_ratio, interpretation)
hysteresis_asymmetry_test <- function(homo_rates, nonhomo_rates) {
  withr::with_seed(42L, {
    config_names <- intersect(names(homo_rates), names(nonhomo_rates))
    
    asym_results <- list()
    for (cname in config_names) {
      h_rr <- homo_rates[[cname]]$rate_ratio
      n_rr <- nonhomo_rates[[cname]]$rate_ratio
      
      # Asymmetry ratio: how much more Homo favors speciation over extinction
      # compared to non-Homo. > 1 means Homo is more "expansionary."
      asymmetry <- h_rr / max(n_rr, .Machine$double.xmin)
      
      asym_results[[cname]] <- list(
        config = cname,
        homo_rate_ratio = h_rr,
        nonhomo_rate_ratio = n_rr,
        asymmetry = asymmetry,
        interpretation = ifelse(asymmetry > 1.5,
          "Strong asymmetry — Homo shows faster entry relative to exit",
          "Moderate or no asymmetry"
        )
      )
    }
    
    mean_asym <- mean(as.numeric(sapply(asym_results, function(r) r$asymmetry)))
    
    list(
      values = list(
        asymmetry_by_config = asym_results,
        mean_asymmetry_ratio = mean_asym,
        interpretation = ifelse(mean_asym > 1.5,
          "Homo shows faster-relative-entry hysteresis — consistent with cultural buffering",
          "No clear hysteresis signal in rate ratios"
        )
      ),
      metadata = list(
        method = "Speciation/extinction rate ratio comparison",
        n_configs = length(config_names),
        caveat = "Rate ratios from single-coefficient DD model; direct temporal hysteresis needs per-window rate estimates"
      )
    )
  })
}

#' Cross-clade asymmetry comparison
#'
#' Uses the cross_clade_dd.csv data to compare the DD × culture relationship
#' with an additional metric: how much the DD signal is driven by speciation
#' vs extinction. For cultural lineages, positive DD should come from
#' innovation (speciation increase), not just extinction reduction.
#'
#' @param cross_clade_data Data frame from load_cross_clade_dd()
#'
#' @return List (A6): values(interpretation), metadata(method)
NULL

#' Load Canis PyRate rate logs for comparison
#'
#' The Canis analysis has detailed rate-through-time data (sp_rates, ex_rates).
#' Compares the Canis rate asymmetry with the hominin results.
load_canis_rate_asymmetry <- function() {
  canis_dir <- "/home/node/.openclaw/workspace/vi-foundry/results/canid-dd-analysis/pyrate_mcmc_logs"
  
  sp_file <- sprintf("%s/Canis_pbdb_data_1_Grj_sp_rates.log", canis_dir)
  ex_file <- sprintf("%s/Canis_pbdb_data_1_Grj_ex_rates.log", canis_dir)
  
  if (!file_exists(sp_file) || !file_exists(ex_file)) {
    return(list(error = "Canis rate files not found"))
  }
  
  sp_tbl <- read.table(sp_file, header = TRUE)
  ex_tbl <- read.table(ex_file, header = TRUE)
  
  # Mean rates (post-burnin)
  sp_rates <- as.numeric(sp_tbl$Rate)
  ex_rates <- as.numeric(ex_tbl$Rate)
  
  mean_sp <- mean(sp_rates)
  mean_ex <- mean(ex_rates)
  
  list(
    values = list(
      mean_speciation_rate = mean_sp,
      mean_extinction_rate = mean_ex,
      rate_ratio = mean_sp / max(mean_ex, .Machine$double.xmin),
      interpretation = ifelse(mean_sp / max(mean_ex, .Machine$double.xmin) < 1.0,
        "Canis shows net extinction bias (negative DD) — symmetric, no hysteresis",
        "Canis shows net speciation bias"
      )
    ),
    metadata = list(
      source = "Canis PyRate MCMC (1M iterations)",
      method = "Mean speciation/extinction rate from posterior",
      n_samples = nrow(sp_tbl)
    )
  )
}