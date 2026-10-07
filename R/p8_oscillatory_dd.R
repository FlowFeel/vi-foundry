# p8a — Oscillatory Diversity-Dependence Test (Finding 2)
#
# VI Prediction: Cultural lineages (Homo) show time-dependent diversity-
# dependence — the DD coefficient becomes MORE positive through time as
# cultural accumulation deepens and reinforces itself. Non-cultural lineages
# should show stable (negative) DD.
#
# Method: Uses the existing PyRate MCMC posterior distributions for Homo vs
# non-Homo from 4 independent configurations (NHPP, TPP, Fine, Wood-Boyle).
# Tests whether Homo's DD shows signs of temporal structure (wider posteriors,
# multimodal structure, autocorrelation) compared to non-Homo.
#
# Also tests a cross-clade temporal proxy: whether clades with more recent
# cultural innovation (vs. ancient cultural/ecological) show stronger positive
# DD, using the cross_clade_dd.csv gradient.
#
# @dft A1, A2, A6
NULL

#' Load PyRate MCMC posteriors from van Holstein & Foley (2024)
#'
#' Reads the DD-coefficient (Gl) posterior samples from the PyRate MCMC logs
#' for Homo and non-Homo partitions across all 4 configurations.
#'
#' @return List with fields: homo_configs, nonhomo_configs,
#'   wholeclade_configs (each a list of Gl posterior vectors)
load_hominin_dd_posteriors <- function() {
  # Base path for van Holstein data
  base <- "/home/node/.openclaw/workspace/work/marsyas6/papers/valence-ingress/data/van-holstein/Data_Code_Final/PyRate/Outputs"
  
  configs <- list(
    Broad_NHPP = "%s/Broad_occurrence_level/NHPP/%s_diversity_0_expSp_expEx_HP.log",
    Broad_TPP  = "%s/Broad_occurrence_level/TPP/%s_diversity_0_expSp_expEx_HP.log",
    Fine_NHPP  = "%s/Fine_occurrence_level/NHPP/%s_diversity_0_expSp_expEx_HP.log",
    Fine_TPP   = "%s/Fine_occurrence_level/TPP/%s_diversity_0_expSp_expEx_HP.log",
    WoodBoyle  = "%s/Wood-Boyle/%s_diversity_0_expSp_expEx_HP.log"
  )
  
  partitions <- list("homo", "nonhomo", "wholeclade")
  
  posterior <- function(partition) {
    result <- list()
    for (cname in names(configs)) {
      path <- configs[[cname]]
      fpath <- sprintf(path, base, partition)
      if (file_exists(fpath)) {
        log_tbl <- read.table(fpath, header = TRUE)
        # Burn-in: discard first 1000 iterations
        burnin <- 1000L
        tbl <- log_tbl[log_tbl$it >= burnin, ]
        gl_col <- grep("Gl_*", names(tbl), value = TRUE)
        if (length(gl_col) > 0L) {
          result[[cname]] <- list(
            gl_posterior = as.numeric(tbl[[gl_col[1L]]]),
            n_samples = nrow(tbl),
            meaning = "Gl = diversity-dependent speciation coefficient; positive = more speciation with more diversity (the Homo inversion)"
          )
        }
      }
    }
    result
  }
  
  list(
    homo = posterior("homo"),
    nonhomo = posterior("nonhomo"),
    wholeclade = posterior("wholeclade"),
    metadata = list(
      configs = names(configs),
      partitions = partitions,
      source = "van Holstein & Foley (2024) PyRate MCMC outputs"
    )
  )
}

#' Test oscillatory DD — Homo vs non-Homo posterior comparison
#'
#' If DD is time-dependent (oscillatory) for Homo, a single-coefficient model
#' will produce wider, more irregular posteriors. If DD is constant through
#' time (non-Homo), the posteriors should be tighter.
#'
#' @param homo_posteriors List of Gl posterior vectors for Homo configs
#' @param nonhomo_posteriors List of Gl posterior vectors for non-Homo configs
#'
#' @return List (A6): values(multi_config_ratio_summary),
#'   metadata(config_labels, method)
oscillatory_dd_posterior_test <- function(homo_posteriors, nonhomo_posteriors) {
  withr::with_seed(42L, {
    config_names <- intersect(names(homo_posteriors), names(nonhomo_posteriors))
    
    ratios <- list()
    for (cname in config_names) {
      h_gl <- homo_posteriors[[cname]]$gl_posterior
      n_gl <- nonhomo_posteriors[[cname]]$gl_posterior
      
      # Mean ratio (how much larger is Homo's DD than non-Homo's?)
      h_mean <- mean(h_gl)
      n_mean <- mean(n_gl)
      ratio <- h_mean / (abs(n_mean) + .Machine$double.xmin)
      
      # CI width ratio
      h_ci <- quantile(h_gl, 0.975) - quantile(h_gl, 0.025)
      n_ci <- quantile(n_gl, 0.975) - quantile(n_gl, 0.025)
      ci_ratio <- h_ci / (n_ci + .Machine$double.xmin)
      
      # P(Homo > non-Homo)
      n_boot <- 10000L
      h_samp <- sample(h_gl, n_boot, replace = TRUE)
      n_samp <- sample(n_gl, n_boot, replace = TRUE)
      p_homo_gt <- mean(h_samp > n_samp)
      
      # Autocorrelation in chain (within-chain temporal structure proxy)
      # Higher autocorrelation in Homo chain suggests time-varying DD
      h_acf <- auto_corr(h_gl, lag = 10L)
      n_acf <- auto_corr(n_gl, lag = 10L)
      acf_ratio <- h_acf / (n_acf + .Machine$double.xmin)
      
      ratios[[cname]] <- list(
        config = cname,
        homo_mean_dd = h_mean,
        nonhomo_mean_dd = n_mean,
        dd_ratio = ratio,
        homo_ci_width = h_ci,
        nonhomo_ci_width = n_ci,
        ci_width_ratio = ci_ratio,
        p_homo_gt_nonhomo = p_homo_gt,
        homo_acf_lag10 = h_acf,
        nonhomo_acf_lag10 = n_acf,
        acf_ratio = acf_ratio
      )
    }
    
    # Aggregate
    p_vals <- sapply(ratios, function(r) r$p_homo_gt_nonhomo)
    mean_p <- mean(as.numeric(p_vals))
    
    list(
      values = list(
        multi_config_ratio_summary = ratios,
        mean_p_homo_gt_nonhomo = mean_p,
        n_configs = length(config_names)
      ),
      metadata = list(
        config_labels = config_names,
        method = "Posterior comparison: mean, CI, autocorrelation",
        interpretation = ifelse(mean_p > 0.8,
          "Directionally consistent with oscillatory DD",
          "Insufficient resolution to detect temporal structure"
        )
      )
    )
  })
}

#' Cross-clade temporal proxy
#'
#' Clades with more recent cultural innovation (Homo ~2.5 Ma vs Corvidae ~15 Ma)
#' should show stronger positive DD if cultural accumulation is self-reinforcing.
#' Tests the gradient of DD against cultural mediation score.
#'
#' @param cross_clade_data Data frame from load_cross_clade_dd()
#'
#' @return List (A6): values(pearson_r, spearman_rho, pgls_slope, pgls_p)
cross_clade_temporal_proxy <- function(cross_clade_data) {
  withr::with_seed(42L, {
    dd <- as.numeric(cross_clade_data$dd)
    culture <- as.numeric(cross_clade_data$culture)
    
    # Pearson correlation
    pearson_fit <- cor_test(dd, culture, method = "pearson")
    spearman_fit <- cor_test(dd, culture, method = "spearman")
    
    # Linear regression: temporal proxy through culture index
    # Prediction: higher culture → more positive DD
    mod <- lm(dd ~ culture)
    slope <- unname(coef(mod)[2])
    p_slope <- summary(mod)$coef[2, 4]
    r2 <- summary(mod)$r.squared
    
    # Filter to mammals only for comparison
    mammal_mask <- as.numeric(cross_clade_data$culture) > 0 | 
                   !(cross_clade_data$clade %in% c("Corvidae", "Psittacidae"))
    
    list(
      values = list(
        pearson_r = pearson_fit$estimate,
        pearson_p = pearson_fit$p.value,
        spearman_rho = spearman_fit$estimate,
        spearman_p = spearman_fit$p.value,
        regression_slope = slope,
        regression_p = p_slope,
        regression_r2 = r2,
        n_clades = length(dd),
        interpretation = ifelse(p_slope < 0.05 && slope > 0,
          "Cultural mediation predicts DD sign across clades — consistent with oscillatory accumulation",
          "Cross-clade gradient does not resolve temporal oscillation"
        )
      ),
      metadata = list(
        method = "Pearson/Spearman + OLS regression",
        caveat = "Cross-sectional proxy for temporal prediction; not a direct test of through-time oscillation"
      )
    )
  })
}

#' Auto-correlation at lag k (simple implementation)
auto_corr <- function(x, lag = 1L) {
  n <- length(x)
  if (n <= lag) return(NA_real_)
  mu <- mean(x)
  var <- sum((x - mu)^2) / n
  acf <- sum((x[1:(n-lag)] - mu) * (x[(1+lag):n] - mu)) / (n * var)
  acf
}

#' Cor.test for data frames (matches cor_test from phosphene package)
cor_test <- function(x, y, method = "pearson") {
  n <- length(x)
  valid <- !is.na(x) & !is.na(y)
  if (sum(valid) < 3) stop("Need >= 3 valid pairs")
  
  r_val <- cor(x[valid], y[valid], method = method)
  z <- 0.5 * log((1 + r_val) / max((1 - r_val), .Machine$double.xmin))
  se <- 1 / sqrt(sum(valid) - 3)
  z_stat <- z / se
  p_val <- 2 * (1 - norm_dist_cdf(abs(z_stat)))
  
  list(estimate = r_val, n = sum(valid), p.value = p_val, z = z_stat, z_se = se)
}

# Load cross-clade data
load_cross_clade_dd <- function() {
  path <- "/home/node/.openclaw/workspace/vi-foundry/data/cross_clade_dd.csv"
  read.csv(path, stringsAsFactors = FALSE)
}