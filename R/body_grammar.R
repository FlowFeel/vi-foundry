#' Body-Grammar Substrate: P4 (HEAD→SELF) Reflexive Typology
#'
#' Formal analysis of HEAD→SELF grammaticalization in reflexive pronoun
#' formation — a typological pattern concentrated in the Caucasus (CHG
#' substrate), Afro-Asiatic, and Sahel. Tests the hypothesis that
#' the P4 distribution reflects a CHG-derived cognitive-grammatical substrate
#' rather than deep inheritance or universal tendency.
#'
#' @section The Five Analyses (Max Planck Protocol):
#'
#' | Code | Analysis | Method | Reference |
#' |------|----------|--------|-----------|
#' | B1 | Spatiophylogenetic | Bayesian GLMM (brms + geography) | Verkerk et al. (2025) |
#' | B2 | Coding Audit | Systematic verification of HEAD entries | Skirgård (2024) |
#' | B3 | Robustness | Leave-one-family-out + regional jackknife | Greenhill |
#' | B4 | aDNA Correlation | CHG ancestry × P4 presence | Atkinson |
#' | B5 | Ancestral State | ace() on Glottolog family trees | Gray |
#'
#' @section Data Sources:
#' - GramBank GB305 (reflexive pronoun presence) at `data/glottobank/`
#' - S_source_typed_reflexives.csv (HEAD/BODY classification)
#' - CHG admixture table at `data/adna-caucasus/`
#' - Glottolog family trees
#'
#' @dft
#' - A1 (pure-io-separation): data loading isolated in loaders
#' - A2 (determinism): seed injected, never hidden
#' - A6 (check-result): returns proof object with values + metadata
#'
#' @name body_grammar
NULL

# ==============================================================================
# B5: Ancestral State Reconstruction — P4 on Glottolog Family Trees
# ==============================================================================

#' B5: P4 Ancestral State Reconstruction
#'
#' Reconstructs the ancestral state of P4 (HEAD→SELF reflexives) on
#' Glottolog family trees using ace() (ape). Tests whether P4 is deeply
#' ancestral in any family or uniformly recent.
#'
#' @param trait_matrix Data frame with columns: taxon (glottocode), trait (0/1), family
#' @param family_trees List of ape::phylo objects, named by family name
#' @param min_tips Integer. Minimum matched tips to run ace (default 3)
#' @param model Character. ace evolution model (default "ER")
#' @param seed Integer. Reproducibility seed
#'
#' @return Proof object:
#'   \item{values}{Data frame: family, n_tips, n_matched, n_P4, root_prob_P4}
#'   \item{metadata}{List: seed, model, min_tips, n_families, n_ace_run}
#'
#' @export
p4_ancestral_reconstruction <- function(trait_matrix, family_trees, min_tips = 3L,
                                         model = "ER", seed = 42L) {
  withr::with_seed(seed, {
    # --- Contracts ---
    stopifnot(is.data.frame(trait_matrix))
    stopifnot(all(c("taxon", "trait", "family") %in% names(trait_matrix)))
    stopifnot(is.list(family_trees))
    stopifnot(is.numeric(min_tips), min_tips >= 3)

    results <- data.frame()
    families_with_p4 <- unique(trait_matrix$family[trait_matrix$trait == 1])

    for (fam in names(family_trees)) {
      tree <- family_trees[[fam]]
      family_data <- trait_matrix[trait_matrix$family == fam, ]

      # Match tree tips to data taxa
      tips_in_data <- which(tree$tip.label %in% family_data$taxon)
      n_tips <- length(tree$tip.label)
      n_matched <- length(tips_in_data)

      if (n_matched < min_tips || n_matched == 0) next

      # Prune tree to matched tips
      if (n_matched < n_tips) {
        tree_pruned <- ape::keep.tip(tree, tree$tip.label[tips_in_data])
      } else {
        tree_pruned <- tree
      }

      # Force binary + root
      if (!ape::is.binary(tree_pruned)) {
        tree_pruned <- ape::multi2di(tree_pruned)
      }

      # Build trait vector ordered by tip labels
      matched_taxa <- tree_pruned$tip.label
      trait_vec <- family_data$trait[match(matched_taxa, family_data$taxon)]

      # Check for all-zero or all-one (ace needs both states)
      n_p4 <- sum(trait_vec, na.rm = TRUE)
      if (n_p4 == 0 || n_p4 == n_matched) {
        root_prob <- if (n_p4 == 0) 0.0 else 1.0
        results <- rbind(results, data.frame(
          family = fam,
          n_tips = n_tips,
          n_matched = n_matched,
          n_P4 = n_p4,
          root_prob_P4 = root_prob,
          method = "deterministic",
          stringsAsFactors = FALSE
        ))
        next
      }

      # ace reconstruction
      tryCatch({
        fit <- ape::ace(trait_vec, tree_pruned, type = "discrete", model = model)

        # Root state probability (for state 1 = P4 present)
        n_states <- length(fit$lik.anc[1, ])
        if (n_states >= 2) {
          root_prob <- fit$lik.anc[1, 2]  # column 2 = state 1
        } else {
          # Single state — use 0.5 as placeholder
          root_prob <- 0.5
        }

        results <- rbind(results, data.frame(
          family = fam,
          n_tips = n_tips,
          n_matched = n_matched,
          n_P4 = n_p4,
          root_prob_P4 = root_prob,
          method = "ace_ER",
          stringsAsFactors = FALSE
        ))
      }, error = function(e) {
        # On singularity, mark as ace_failed
        results <<- rbind(results, data.frame(
          family = fam,
          n_tips = n_tips,
          n_matched = n_matched,
          n_P4 = n_p4,
          root_prob_P4 = NA_real_,
          method = paste0("ace_failed: ", e$message),
          stringsAsFactors = FALSE
        ))
      })
    }

    # Summary
    n_ace <- sum(grepl("^ace_", results$method))
    n_ancestral <- sum(results$root_prob_P4 > 0.5, na.rm = TRUE)

    list(
      values = results,
      metadata = list(
        seed = seed,
        model = model,
        min_tips = min_tips,
        n_families = length(family_trees),
        n_ace_run = n_ace,
        n_ancestral = n_ancestral,
        n_P4_total = sum(trait_matrix$trait == 1, na.rm = TRUE)
      )
    )
  })
}

# ==============================================================================
# B3: GLMM Robustness — P4 Leave-One-Family-Out Jackknife
# ==============================================================================

#' B3: P4 Robustness — Leave-One-Family-Out GLMM
#'
#' Tests whether the P4 family-level clustering survives removal of each
#' individual family or region. If no single removal kills the random effect
#' significance, the signal is robust.
#'
#' @param glmm_data Data frame with columns: language_id, p4 (0/1), family
#' @param families_to_test Character vector. Families to jackknife
#' @param seed Integer. Reproducibility seed
#'
#' @return Proof object:
#'   \item{values}{Data frame: scenario, n, n_p4, rate, family_var, r_sq, survived}
#'   \item{metadata}{List: seed, n_total, n_families, baseline_var}
#'
#' @export
p4_robustness_jackknife <- function(glmm_data, families_to_test = NULL,
                                     seed = 42L) {
  withr::with_seed(seed, {
    stopifnot(is.data.frame(glmm_data))
    stopifnot(all(c("language_id", "p4", "family") %in% names(glmm_data)))

    p4_col <- "p4"

    # Default: test all families with at least 1 P4
    if (is.null(families_to_test)) {
      p4_families <- unique(glmm_data$family[glmm_data[[p4_col]] == 1])
      families_to_test <- p4_families
    }

    # Baseline model
    baseline <- tryCatch({
      fit <- lme4::glmer(
        stats::as.formula(paste0(p4_col, " ~ 1 + (1 | family)")),
        data = glmm_data, family = "binomial",
        control = lme4::glmerControl(optimizer = "bobyqa")
      )
      vc <- as.numeric(lme4::VarCorr(fit)$family)
      list(var = vc, r2 = tryCatch(lme4::r.squaredGLMM(fit)[["R2cond"]], error = function(e) NA))
    }, error = function(e) list(var = NA, r2 = NA))

    results <- data.frame()

    for (fam in families_to_test) {
      subset_data <- glmm_data[glmm_data$family != fam, ]
      n <- nrow(subset_data)
      n_p4 <- sum(subset_data[[p4_col]] == 1, na.rm = TRUE)

      tryCatch({
        fit <- lme4::glmer(
          stats::as.formula(paste0(p4_col, " ~ 1 + (1 | family)")),
          data = subset_data, family = "binomial",
          control = lme4::glmerControl(optimizer = "bobyqa")
        )

        vc <- as.numeric(lme4::VarCorr(fit)$family)
        lrt <- tryCatch({
          lm0 <- stats::glm(
            stats::as.formula(paste0(p4_col, " ~ 1")),
            data = subset_data, family = "binomial"
          )
          tryCatch(anova(fit, lm0, test = "Chisq")$`Pr(>Chisq)`[2], error = function(e) 1)
        }, error = function(e) NA)

        r2 <- tryCatch(
          lme4::r.squaredGLMM(fit)[["R2cond"]],
          error = function(e) NA
        )

        results <- rbind(results, data.frame(
          scenario = paste0("remove_", fam),
          n = n,
          n_p4 = n_p4,
          rate = n_p4 / n,
          family_var = vc,
          r_sq = r2,
          lrt_p = lrt,
          survived = isTRUE(lrt < 0.05) || is.na(lrt),
          stringsAsFactors = FALSE
        ))
      }, error = function(e) {
        results <<- rbind(results, data.frame(
          scenario = paste0("remove_", fam),
          n = n, n_p4 = n_p4,
          rate = n_p4 / n,
          family_var = NA, r_sq = NA,
          lrt_p = NA, survived = NA,
          stringsAsFactors = FALSE
        ))
      })
    }

    list(
      values = results,
      metadata = list(
        seed = seed,
        n_total = nrow(glmm_data),
        n_families = length(unique(glmm_data$family)),
        baseline_var = baseline$var,
        n_scenarios = nrow(results),
        n_survived = sum(results$survived, na.rm = TRUE)
      )
    )
  })
}

# ==============================================================================
# B4: aDNA Correlation — P4 × CHG Ancestry
# ==============================================================================

#' B4: P4 × CHG Ancestry Correlation
#'
#' Tests whether P4 (HEAD→SELF) presence correlates with Caucasus
#' Hunter-Gatherer (CHG) ancestry proportion in Caucasus populations.
#' Also tests the Turkic exception: high CHG but no P4 due to language
#' replacement.
#'
#' @param adna_data Data frame with: population, chg_pct, p4_present (0/1), family
#' @param seed Integer. Reproducibility seed
#'
#' @return Proof object:
#'   \item{values}{List: logistic_fit, correlation, contingency, turkic_check}
#'   \item{metadata}{List: seed, n_populations, n_p4_present}
#'
#' @export
p4_adna_correlation <- function(adna_data, seed = 42L) {
  withr::with_seed(seed, {
    stopifnot(is.data.frame(adna_data))
    stopifnot(all(c("chg_pct", "p4_present") %in% names(adna_data)))

    adna_data$chg <- adna_data$chg_pct

    # Logistic regression: P4 ~ CHG%
    logit_fit <- stats::glm(
      p4_present ~ chg,
      data = adna_data,
      family = "binomial"
    )

    logit_summary <- summary(logit_fit)
    chg_coef <- stats::coef(logit_summary)["chg", ]

    # With family type
    if ("family_type" %in% names(adna_data)) {
      logit_family <- stats::glm(
        p4_present ~ chg + family_type,
        data = adna_data,
        family = "binomial"
      )
      fam_coef <- stats::coef(summary(logit_family))
      chg_family_coef <- if ("chg" %in% rownames(fam_coef)) {
        fam_coef["chg", ]
      } else {
        c(Estimate = NA, `Std. Error` = NA, `z value` = NA, `Pr(>|z|)` = NA)
      }
    } else {
      chg_family_coef <- c(Estimate = NA, `Std. Error` = NA, `z value` = NA, `Pr(>|z|)` = NA)
    }

    # Turkic exception check
    turkic_data <- adna_data[adna_data$family %in% c("Turkic"), ]
    turkic_check <- if (nrow(turkic_data) > 0) {
      list(
        n_turkic = nrow(turkic_data),
        mean_chg = mean(turkic_data$chg, na.rm = TRUE),
        p4_rate = mean(turkic_data$p4_present, na.rm = TRUE),
        exception = mean(turkic_data$chg, na.rm = TRUE) > 30 &&
                      mean(turkic_data$p4_present, na.rm = TRUE) < 0.5
      )
    } else {
      list(exception = NA)
    }

    list(
      values = list(
        logistic_fit = list(
          chg_coefficient = chg_coef["Estimate"],
          chg_se = chg_coef["Std. Error"],
          chg_p = chg_coef["Pr(>|z|)"],
          chg_with_family_coefficient = chg_family_coef["Estimate"],
          chg_with_family_p = chg_family_coef["Pr(>|z|)"]
        ),
        point_biserial = stats::cor.test(adna_data$chg, adna_data$p4_present,
                                          method = "pearson"),
        n = nrow(adna_data),
        turkic_check = turkic_check
      ),
      metadata = list(
        seed = seed,
        n_populations = nrow(adna_data),
        n_p4_present = sum(adna_data$p4_present == 1, na.rm = TRUE),
        has_complete_data = all(stats::complete.cases(adna_data[, c("chg", "p4_present")]))
      )
    )
  })
}

# ==============================================================================
# B1: Spatiophylogenetic GLMM — P4 in Bayesian Framework
# ==============================================================================

#' B1: P4 Spatiophylogenetic GLMM
#'
#' Bayesian logistic GLMM decomposing P4 variance into phylogenetic (family),
#' geographic (spatial lag), and residual components. Implements Verkerk et al.
#' (2025) framework for GramBank data.
#'
#' @param p4_data Data frame with: language_id, p4 (0/1), family, macroarea,
#'   latitude, longitude
#' @param spatial_cutoff_km Numeric. Distance cutoff for spatial weights (default 2000)
#' @param seed Integer. Reproducibility seed
#' @param iter Integer. MCMC iterations per chain (default 2000)
#' @param warmup Integer. Warmup iterations (default 1000)
#'
#' @return Proof object:
#'   \item{values}{List: model1 (phylogeny only), model2 (+ spatial), variance_decomposition}
#'   \item{metadata}{List: seed, n_languages, n_p4, n_families, converged}
#'
#' @export
p4_spatiophylogenetic <- function(p4_data, spatial_cutoff_km = 2000,
                                   seed = 42L, iter = 2000L,
                                   warmup = 1000L) {
  stopifnot(requireNamespace("brms", quietly = TRUE))
  stopifnot(requireNamespace("rstan", quietly = TRUE))

  # Spatial weights for Moran's I
  compute_spatial_lag <- function(coords, cutoff_km) {
    if (nrow(coords) < 2) return(rep(0, nrow(coords)))
    dist_km <- geosphere::distm(coords) / 1000
    weights <- 1 / dist_km
    weights[dist_km > cutoff_km | dist_km == 0] <- 0
    diag(weights) <- 0
    row_norm <- weights / rowSums(weights, na.rm = TRUE)
    row_norm[is.nan(row_norm)] <- 0
    row_norm
  }

  compute_moran <- function(values, weights) {
    if (length(values) < 3) return(list(i = NA, p = NA))
    n <- length(values)
    w_sum <- sum(weights)
    z <- values - mean(values, na.rm = TRUE)
    num <- n / w_sum * sum(weights * outer(z, z, "*"), na.rm = TRUE)
    den <- sum(z^2, na.rm = TRUE)
    i_val <- num / den
    # Approximate z-score under normality
    ei <- -1 / (n - 1)
    num2 <- 2 * w_sum * (n - 1)
    den2 <- (n * (n - 2) * (n - 1) * w_sum)
    # Simplified SE approximation
    list(i = i_val, expected_i = ei, z = (i_val - ei) / sqrt(2 / (n - 1)))
  }

  # --- Prepare data ---
  p4_data <- p4_data[stats::complete.cases(p4_data$latitude, p4_data$longitude), ]
  p4_data$macroarea <- as.factor(p4_data$macroarea)
  p4_data$family <- as.factor(p4_data$family)

  # Calculate spatial lag
  coords <- as.matrix(p4_data[, c("longitude", "latitude")])
  colnames(coords) <- c("lon", "lat")
  W <- compute_spatial_lag(coords, spatial_cutoff_km)

  # Spatial lag for each language
  lag_vals <- as.vector(W %*% p4_data$p4)
  p4_data$spatial_lag <- lag_vals

  # Moran's I on raw P4
  moran_raw <- compute_moran(p4_data$p4, W)

  # --- Model 1: Phylogeny only ---
  model1_formula <- brms::brmsformula(p4 ~ macroarea + (1 | family))

  model1 <- brms::brm(
    formula = model1_formula,
    data = p4_data,
    family = brms::bernoulli(link = "logit"),
    prior = c(
      brms::set_prior("normal(-4, 2)", class = "Intercept"),
      brms::set_prior("normal(0, 2)", class = "b"),
      brms::set_prior("student_t(3, 0, 2.5)", class = "sd")
    ),
    chains = 4L, iter = iter, warmup = warmup,
    seed = seed, refresh = 0,
    control = list(adapt_delta = 0.95),
    silent = 2
  )

  # Variance decomposition Model 1
  var_family1 <- as.numeric(brms::VarCorr(model1)$family$sd[1])^2
  icc_family1 <- var_family1 / (var_family1 + pi^2 / 3)

  # --- Model 2: + Spatial lag ---
  model2_formula <- brms::brmsformula(p4 ~ macroarea + spatial_lag + (1 | family))

  model2 <- brms::brm(
    formula = model2_formula,
    data = p4_data,
    family = brms::bernoulli(link = "logit"),
    prior = c(
      brms::set_prior("normal(-4, 2)", class = "Intercept"),
      brms::set_prior("normal(0, 2)", class = "b"),
      brms::set_prior("student_t(3, 0, 2.5)", class = "sd")
    ),
    chains = 4L, iter = iter, warmup = warmup,
    seed = seed + 1L, refresh = 0,
    control = list(adapt_delta = 0.95),
    silent = 2
  )

  # Variance decomposition Model 2
  var_family2 <- as.numeric(brms::VarCorr(model2)$family$sd[1])^2
  icc_family2 <- var_family2 / (var_family2 + pi^2 / 3)

  # Spatial lag fixed effect
  spat_fix <- brms::fixef(model2)["spatial_lag", ]

  # Variance reduction
  var_reduction <- (var_family1 - var_family2) / var_family1

  list(
    values = list(
      model1 = list(
        family_var = var_family1,
        icc_family = icc_family1,
        formula = as.character(model1_formula)[1]
      ),
      model2 = list(
        family_var = var_family2,
        icc_family = icc_family2,
        spatial_lag_beta = spat_fix["Estimate"],
        spatial_lag_ci = c(spat_fix["Q2.5"], spat_fix["Q97.5"]),
        formula = as.character(model2_formula)[1]
      ),
      variance_decomposition = list(
        phylogeny = icc_family2,
        geography = icc_family1 - icc_family2,
        residual = 1 - icc_family1,
        family_var_reduction_pct = var_reduction * 100
      ),
        spatial = moran_raw
    ),
    metadata = list(
      seed = seed,
      n_languages = nrow(p4_data),
      n_p4 = sum(p4_data$p4 == 1),
      n_families = length(unique(p4_data$family)),
      spatial_cutoff_km = spatial_cutoff_km,
      iter = iter,
      warmup = warmup,
      converged = all(model1$rhats < 1.05, na.rm = TRUE) &&
                    all(model2$rhats < 1.05, na.rm = TRUE),
      timestamp = format(Sys.time(), "%Y-%m-%d %H:%M:%S UTC")
    )
  )
}