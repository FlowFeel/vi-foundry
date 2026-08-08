# generate_cross_kingdom.R — Simulacrum synthetic data generator
#
# Generates synthetic plant (Orobanchaceae) and bird (island flight-loss)
# morphology data with a KNOWN shared slope for cross-kingdom parameter
# transfer recovery tests (Simulacrum 5).
#
# DFT Axioms:
#   A1 (pure-io-separation): pure function, no file I/O
#   A2 (deterministic): uses withr::with_seed() for full reproducibility
#   A6 (check-result): validates output structure before returning
#
# @name generate_cross_kingdom_data
NULL

#' Generate synthetic cross-kingdom data with known shared slope
#'
#' Creates synthetic plant gene-category data and bird morphological-change
#' data sharing a known slope parameter. The plant data has 6 categories
#' with dependency scores [0, 1, 1, 2, 3, 5]; the bird data has 8 structures
#' with dependency scores [0, 0.5, 1, 1.5, 2, 3, 4, 5]. Both are generated
#' as \code{true_slope * dependency_score + rnorm(n, 0, noise_sd)}, then
#' rank-transformed.
#'
#' For null-control tests, pass a different \code{bird_slope} to break the
#' shared-slope assumption.
#'
#' @param seed Integer. Seed for reproducibility (A2). Default: 42.
#' @param true_slope Numeric. The shared slope generating both plant and
#'   bird orderings. Default: 0.6.
#' @param plant_noise_sd Numeric. Standard deviation of Gaussian noise
#'   added to plant loss ranks. Default: 0.5.
#' @param bird_noise_sd Numeric. Standard deviation of Gaussian noise
#'   added to bird observed ranks. Default: 0.5.
#' @param bird_slope Numeric. Optional separate slope for bird data.
#'   If \code{NULL} (default), uses \code{true_slope} (shared slope).
#'   Set to a different value for null-control tests where the two
#'   kingdoms have independent slopes.
#'
#' @return List (A6) with elements:
#'   \describe{
#'     \item{plant}{Data frame with columns \code{category},
#'       \code{dependency_score}, and \code{simulacrum_loss_rank}.}
#'     \item{bird}{Data frame with columns \code{structure},
#'       \code{dependency_score}, and \code{observed_rank}.}
#'     \item{true_slope}{The shared slope parameter.}
#'     \item{metadata}{List with seed, true_slope, bird_slope, noise SDs,
#'       and sample sizes.}
#'   }
#'
#' @examples
#' \dontrun{
#' d <- generate_cross_kingdom_data(seed = 42, true_slope = 0.6)
#' # Shared slope → transfer_test should recover bird_rho > 0.7
#' result <- transfer_test(d$plant, d$bird, seed = 42)
#'
#' # Null control: independent slopes
#' d_null <- generate_cross_kingdom_data(seed = 42, true_slope = 0.6,
#'                                        bird_slope = -0.3)
#' result_null <- transfer_test(d_null$plant, d_null$bird, seed = 42)
#' # bird_rho should be near 0
#' }
#'
#' @dft A1, A2, A6
#'
#' @export
generate_cross_kingdom_data <- function(
  seed = 42L,
  true_slope = 0.6,
  plant_noise_sd = 0.5,
  bird_noise_sd = 0.5,
  bird_slope = NULL
) {
  withr::with_seed(
    seed = seed,
    code = {
      # ---- Plant data (Orobanchaceae gene categories) ----
      plant_categories <- c("ndh", "rpo", "psa", "psb", "atp", "rpl_rps")
      plant_dep <- c(0, 1, 1, 2, 3, 5)
      n_plant <- length(plant_categories)

      # loss_rank = true_slope * dep + noise, then rank-transformed
      plant_raw <- true_slope * plant_dep + rnorm(n_plant, 0, plant_noise_sd)
      plant_loss_rank <- rank(plant_raw, ties.method = "average")

      # ---- Bird data (island flight-loss morphology) ----
      bird_structures <- c(
        "wing_prop", "pectoral_muscle", "sternal_keel",
        "wing_bones", "hindlimb", "pelvic_girdle",
        "feather_asymmetry", "feather_structure"
      )
      bird_dep <- c(0, 0.5, 1, 1.5, 2, 3, 4, 5)
      n_bird <- length(bird_structures)

      bird_slope_use <- if (is.null(bird_slope)) true_slope else bird_slope
      bird_raw <- bird_slope_use * bird_dep + rnorm(n_bird, 0, bird_noise_sd)
      bird_observed_rank <- rank(bird_raw, ties.method = "average")

      # ---- Assemble data frames ----
      plant_data <- data.frame(
        category = plant_categories,
        dependency_score = plant_dep,
        simulacrum_loss_rank = plant_loss_rank,
        stringsAsFactors = FALSE
      )

      bird_data <- data.frame(
        structure = bird_structures,
        dependency_score = bird_dep,
        observed_rank = bird_observed_rank,
        stringsAsFactors = FALSE
      )

      # ---- Build result list ----
      result <- list(
        plant = plant_data,
        bird = bird_data,
        true_slope = true_slope,
        metadata = list(
          seed = seed,
          true_slope = true_slope,
          bird_slope = bird_slope_use,
          plant_noise_sd = plant_noise_sd,
          bird_noise_sd = bird_noise_sd,
          n_plant = n_plant,
          n_bird = n_bird
        )
      )

      # A6: validate internal structure before returning
      validate_result(list(
        values = c(true_slope = true_slope),
        metadata = result$metadata
      ))

      result
    }
  )
}
