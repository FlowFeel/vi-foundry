#' Cross-kingdom parameter transfer (L3 test)
#'
#' The strongest test in the monograph: fit the integration-depth model
#' on plant (Orobanchaceae) data, then apply the same parameters to predict
#' bird (island bird flight-loss) morphological change ordering WITHOUT
#' refitting. If the ordering transfers across kingdoms, the principle is
#' substrate-independent.
#'
#' @section Theoretical Context:
#'
#' VI Prediction: integration-depth parameters transfer across kingdoms.
#' Competitor: substrates are independent — no parameter transfer.
#' DOES distinguish VI. This is the strongest test.
#'
#' @dft A1, A2, A6
#'
#' @name cross_kingdom_transfer
NULL

#' Fit the plant model (dependency score → loss rank)
#'
#' Fits a linear model: loss_rank ~ dependency_score using Orobanchaceae
#' gene-loss data. Returns the slope for cross-kingdom transfer.
#'
#' @param plant_data Data frame with dependency_score and loss_rank columns.
#' @param seed Integer. Seed for reproducibility.
#'
#' @return List (A6): values (slope, intercept, r_squared, p_value), metadata.
#'
#' @dft A1, A2, A6
#'
#' @export
fit_plant_model <- function(plant_data, seed = 42L) {
  withr::with_seed(seed, {
    validate_gene_categories(plant_data)

    # Use first available loss rank column
    loss_col <- grep("_loss_rank$", names(plant_data), value = TRUE)[1]

    fit <- lm(plant_data[[loss_col]] ~ plant_data$dependency_score)
    s <- summary(fit)

    result <- list(
      values = c(
        slope = unname(coef(fit)[2]),
        intercept = unname(coef(fit)[1]),
        r_squared = unname(s$r.squared),
        p_value = unname(s$coefficients[2, 4])
      ),
      metadata = list(
        seed = seed,
        n = nrow(plant_data),
        loss_col = loss_col,
        converged = TRUE
      )
    )

    validate_result(result)
    result
  })
}

#' Predict bird morphological change ordering from plant-derived slope
#'
#' Uses the plant-derived slope ( WITHOUT refitting) to predict
#' the ordering of bird morphological changes.
#'
#' @param bird_data Data frame with structure, dependency_score, observed_rank.
#' @param plant_slope Numeric. Slope from fit_plant_model()$values["slope"].
#'
#' @return Numeric vector. Predicted ranks for each bird structure.
#'
#' @dft A1
#'
#' @export
predict_bird_ordering <- function(bird_data, plant_slope) {
  validate_bird_morphology(bird_data)

  # Predict: rank = intercept + slope × dependency_score
  # We only use the slope (ordering), not the intercept (rate)
  predicted <- plant_slope * bird_data$dependency_score

  # Convert to ranks (1 = first to change)
  rank(predicted, ties.method = "average")
}

#' Full cross-kingdom transfer test
#'
#' Fits on plant data, predicts bird ordering, computes Spearman ρ between
#' predicted and observed bird ranks. Also runs null control (random slope).
#'
#' @param plant_data Data frame with dependency_score and loss_rank.
#' @param bird_data Data frame with structure, dependency_score, observed_rank.
#' @param seed Integer. Seed for reproducibility.
#'
#' @return List (A6): values (plant_slope, bird_rho, bird_p, null_rho), metadata.
#'
#' @dft A1, A2, A6
#'
#' @export
transfer_test <- function(plant_data, bird_data, seed = 42L) {
  withr::with_seed(seed, {
    # Fit plant model
    plant_fit <- fit_plant_model(plant_data, seed = seed)
    plant_slope <- plant_fit$values["slope"]

    # Predict bird ordering using plant slope
    predicted_ranks <- predict_bird_ordering(bird_data, plant_slope)

    # Compare to observed
    observed_ranks <- bird_data$observed_rank
    cor_result <- cor.test(predicted_ranks, observed_ranks, method = "spearman")

    # Null control: random slope
    random_slope <- runif(1, -1, 1)
    null_predicted <- random_slope * bird_data$dependency_score
    null_ranks <- rank(null_predicted, ties.method = "average")
    null_cor <- cor.test(null_ranks, observed_ranks, method = "spearman")

    result <- list(
      values = c(
        plant_slope = unname(plant_slope),
        bird_rho = unname(cor_result$estimate),
        bird_p = unname(cor_result$p.value),
        null_rho = unname(null_cor$estimate)
      ),
      metadata = list(
        seed = seed,
        n_plant = nrow(plant_data),
        n_bird = nrow(bird_data),
        n_bird_structures = length(unique(bird_data$structure)),
        converged = TRUE
      )
    )

    validate_result(result)
    result
  })
}
