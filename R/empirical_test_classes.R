#' Empirical Test Result Classes (S3 three-layer pattern)
#'
#' S3 class hierarchy for empirical test results in the vi-foundry package.
#' Each class follows Phosphene R Standards §7: constructor → validator →
#' public helper, plus standard generics `print()`, `summary()`, and
#' `as.data.frame()`.
#'
#' The base class `vi_test_result` carries the fields common to every
#' empirical test:
#'
#' - `test_name`: character. Identifier of the test (e.g. "pgls_orobanchaceae").
#' - `statistic`: numeric. Scalar test statistic.
#' - `p_value`: numeric in [0, 1] (or `NA`). Test p-value.
#' - `vi_prediction`: character. Plain-language statement of what VI predicts.
#' - `discriminating`: logical. Whether the test distinguishes VI from
#'   competitors (as opposed to merely being consistent with VI).
#' - `status`: character. `"significant"`, `"not_significant"`, or `"n/a"`.
#' - `values`: list. Test-specific value fields (the raw result `values`).
#' - `metadata`: list. Provenance and bookkeeping fields.
#'
#' Subclasses extend the base with test-specific scalar fields:
#'
#' - `vi_pgls_result` (T1/T2): `beta`, `r_squared`, `aic`, `n`
#' - `vi_niche_ne_result` (T4): `niche_r_squared`, `ne_r_squared`, `delta_aic`
#' - `vi_fluidity_result` (T5): `lifestyle_r_squared`, `ne_r_squared`, `p_value`
#' - `vi_ordering_result` (T6): `rho`, `p_value`, `n_permutations`
#' - `vi_transfer_result` (L3): `rho`, `p_value`, `n_null_draws`
#' - `vi_cosegregation_result` (T7): `observed_pct`, `expected_pct`, `depletion_ratio`
#'
#' @section Theoretical Context:
#'
#' All constructors follow DFT A6 (check-result): they return a structured,
#' validated object whose shape downstream consumers can rely on. All accessor
#' methods are pure (A1): they return values and never mutate state.
#'
#' @name empirical_test_classes
NULL

# =============================================================================
# Internal helpers shared by all empirical result classes
# =============================================================================

#' Coerce NULL to NA (helper)
#'
#' Safely map a missing list element to `NA` so validators see a typed value.
#'
#' @param x Value possibly NULL.
#' @return `NA` if `x` is NULL, otherwise `x`.
#' @keywords internal
.vi_or_na <- function(x) {
  if (is.null(x)) NA else x
}

#' Significance stars from p-value (helper)
#'
#' @param p Numeric p-value.
#' @return character significance label.
#' @keywords internal
.vi_p_stars <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.001) "***" else if (p < 0.01) "**" else if (p < 0.05) "*" else ""
}

#' Status label from p-value (helper)
#'
#' @param p Numeric p-value.
#' @param alpha Numeric. Significance threshold (default 0.05).
#' @return "significant", "not_significant", or "n/a".
#' @keywords internal
.vi_status_of <- function(p, alpha = 0.05) {
  if (is.na(p)) return("n/a")
  if (p < alpha) "significant" else "not_significant"
}

#' Base summary data.frame (helper)
#'
#' Builds the six standard columns shared by every result class.
#'
#' @param x A vi_test_result (or subclass).
#' @return data.frame with one row and the six canonical columns.
#' @keywords internal
.vi_base_summary <- function(x) {
  data.frame(
    test_name = x$test_name,
    statistic = x$statistic,
    p_value = x$p_value,
    vi_prediction = x$vi_prediction,
    discriminating = x$discriminating,
    status = x$status,
    stringsAsFactors = FALSE
  )
}

#' Print the shared header block (helper)
#'
#' @param x A vi_test_result (or subclass).
#' @keywords internal
.vi_print_header <- function(x) {
  cls <- class(x)[1]
  cat(sprintf("%s\n", cls))
  cat(sprintf("%s\n", strrep("=", nchar(cls))))
  cat(sprintf("  Test:          %s\n", x$test_name))
  cat(sprintf("  Discriminating:%s\n",
              ifelse(isTRUE(x$discriminating), " yes (distinguishes VI)", " no (consistent w/ VI)")))
  cat(sprintf("  Status:        %s\n", x$status))
  if (!is.null(x$metadata$n)) {
    cat(sprintf("  n:             %s\n", x$metadata$n))
  }
  cat("  Statistic:     ", if (is.na(x$statistic)) "NA" else sprintf("%.4g", x$statistic),
      sprintf("  (p = %s %s)\n",
              if (is.na(x$p_value)) "NA" else sprintf("%.4g", x$p_value),
              .vi_p_stars(x$p_value)))
  if (!is.null(x$vi_prediction) && !is.na(x$vi_prediction) && nzchar(x$vi_prediction)) {
    cat(sprintf("  Prediction:    %s\n", x$vi_prediction))
  }
}

# =============================================================================
# VI_TEST_RESULT CLASS (base)
# =============================================================================

#' Create vi_test_result object (base constructor)
#'
#' Bare-metal constructor — assigns the base class without validation. Used
#' internally by the validator and public helper. No type checking.
#'
#' @param test_name Character. Test identifier.
#' @param statistic Numeric. Test statistic.
#' @param p_value Numeric. Test p-value (or NA).
#' @param vi_prediction Character. What VI predicts.
#' @param discriminating Logical. Whether the test distinguishes VI.
#' @param status Character. Significant / not_significant / n/a.
#' @param values List. Test-specific value fields.
#' @param metadata List. Provenance fields.
#'
#' @return vi_test_result object (unvalidated).
#' @keywords internal
new_vi_test_result <- function(test_name, statistic, p_value, vi_prediction,
                               discriminating, status, values, metadata) {
  structure(
    list(
      test_name = test_name,
      statistic = .vi_or_na(statistic),
      p_value = .vi_or_na(p_value),
      vi_prediction = .vi_or_na(vi_prediction),
      discriminating = .vi_or_na(discriminating),
      status = .vi_or_na(status),
      values = values,
      metadata = metadata
    ),
    class = "vi_test_result"
  )
}

#' Validate vi_test_result object
#'
#' Schema checks for the base class fields. Returns `invisible(x)` on success,
#' `stop()`s with a descriptive message on failure.
#'
#' @param x vi_test_result object.
#' @return Invisible `x` if valid.
#' @keywords internal
validate_vi_test_result <- function(x) {
  if (!is.list(x) || !inherits(x, "vi_test_result")) {
    stop("vi_test_result must be a list with class 'vi_test_result'", call. = FALSE)
  }
  required <- c("test_name", "statistic", "p_value", "vi_prediction",
                "discriminating", "status", "values", "metadata")
  missing <- setdiff(required, names(x))
  if (length(missing) > 0) {
    stop("Missing required fields: ", paste(missing, collapse = ", "), call. = FALSE)
  }
  if (!is.character(x$test_name) || length(x$test_name) != 1) {
    stop("test_name must be a single character", call. = FALSE)
  }
  if (!is.numeric(x$statistic) || length(x$statistic) != 1) {
    stop("statistic must be a single numeric (or NA)", call. = FALSE)
  }
  if (!is.numeric(x$p_value) || length(x$p_value) != 1 ||
      (!is.na(x$p_value) && (x$p_value < 0 || x$p_value > 1))) {
    stop("p_value must be a single numeric in [0, 1] (or NA)", call. = FALSE)
  }
  if (!is.character(x$vi_prediction)) {
    stop("vi_prediction must be character", call. = FALSE)
  }
  if (!is.logical(x$discriminating) || length(x$discriminating) != 1) {
    stop("discriminating must be a single logical", call. = FALSE)
  }
  if (!is.character(x$status) || !(x$status %in% c("significant", "not_significant", "n/a"))) {
    stop("status must be one of 'significant', 'not_significant', 'n/a'", call. = FALSE)
  }
  if (!is.list(x$values)) {
    stop("values must be a list", call. = FALSE)
  }
  if (!is.list(x$metadata)) {
    stop("metadata must be a list", call. = FALSE)
  }
  invisible(x)
}

#' Public helper for vi_test_result
#'
#' Combines constructor + validator. This is the public entry point for
#' constructing a base empirical result object.
#'
#' @param test_name See new_vi_test_result().
#' @param statistic See new_vi_test_result().
#' @param p_value See new_vi_test_result().
#' @param vi_prediction See new_vi_test_result().
#' @param discriminating See new_vi_test_result().
#' @param status See new_vi_test_result().
#' @param values See new_vi_test_result().
#' @param metadata See new_vi_test_result().
#'
#' @return Validated vi_test_result object.
#' @export
vi_test_result <- function(test_name, statistic = NA_real_, p_value = NA_real_,
                           vi_prediction = "", discriminating = FALSE,
                           status = .vi_status_of(p_value),
                           values = list(), metadata = list()) {
  res <- new_vi_test_result(test_name, statistic, p_value, vi_prediction,
                            discriminating, status, values, metadata)
  validate_vi_test_result(res)
}

#' Print vi_test_result Object
#'
#' @param x vi_test_result object.
#' @param ... Ignored.
#' @return Invisibly returns `x`.
#' @export
print.vi_test_result <- function(x, ...) {
  .vi_print_header(x)
  invisible(x)
}

#' Summary of vi_test_result Object
#'
#' @param object vi_test_result object.
#' @param ... Ignored.
#' @return data.frame with the six canonical columns.
#' @export
summary.vi_test_result <- function(object, ...) {
  .vi_base_summary(object)
}

#' Convert vi_test_result to Data Frame
#'
#' @param x vi_test_result object.
#' @param row.names Ignored.
#' @param optional Ignored.
#' @param ... Additional arguments.
#' @return data.frame with the six canonical columns.
#' @export
as.data.frame.vi_test_result <- function(x, row.names = NULL, optional = FALSE, ...) {
  .vi_base_summary(x)
}

# =============================================================================
# VI_PGLS_RESULT CLASS (T1 / T2)
# =============================================================================

#' Create vi_pgls_result object (constructor)
#'
#' Subclass of `vi_test_result` for PGLS comparative results. Extra scalar
#' fields: `beta`, `r_squared`, `aic`, `n`.
#'
#' @param test_name,statistic,p_value,vi_prediction,discriminating,status,values,metadata
#'   Base fields (see new_vi_test_result()).
#' @param beta Numeric. PGLS slope.
#' @param r_squared Numeric. Model R².
#' @param aic Numeric. Akaike information criterion (or NA).
#' @param n Integer. Number of observations.
#'
#' @return vi_pgls_result object (unvalidated).
#' @keywords internal
new_vi_pgls_result <- function(test_name, statistic, p_value, vi_prediction,
                               discriminating, status, values, metadata,
                               beta, r_squared, aic, n) {
  obj <- new_vi_test_result(test_name, statistic, p_value, vi_prediction,
                            discriminating, status, values, metadata)
  obj$beta <- .vi_or_na(beta)
  obj$r_squared <- .vi_or_na(r_squared)
  obj$aic <- .vi_or_na(aic)
  obj$n <- .vi_or_na(n)
  class(obj) <- c("vi_pgls_result", "vi_test_result")
  obj
}

#' Validate vi_pgls_result object
#'
#' @param x vi_pgls_result object.
#' @return Invisible `x` if valid.
#' @keywords internal
validate_vi_pgls_result <- function(x) {
  validate_vi_test_result(x)
  if (!is.numeric(x$beta) || length(x$beta) != 1) {
    stop("beta must be a single numeric (or NA)", call. = FALSE)
  }
  if (!is.numeric(x$r_squared) || length(x$r_squared) != 1) {
    stop("r_squared must be a single numeric (or NA)", call. = FALSE)
  }
  if (!is.numeric(x$aic) || length(x$aic) != 1) {
    stop("aic must be a single numeric (or NA)", call. = FALSE)
  }
  if (!is.numeric(x$n) || length(x$n) != 1) {
    stop("n must be a single numeric (or NA)", call. = FALSE)
  }
  invisible(x)
}

#' Public helper for vi_pgls_result
#'
#' @param test_name,statistic,p_value,vi_prediction,discriminating,status,values,metadata
#'   Base fields.
#' @param beta,r_squared,aic,n Extra PGLS fields.
#' @return Validated vi_pgls_result object.
#' @export
vi_pgls_result <- function(test_name, statistic = NA_real_, p_value = NA_real_,
                           vi_prediction = "", discriminating = FALSE,
                           status = .vi_status_of(p_value),
                           values = list(), metadata = list(),
                           beta = NA_real_, r_squared = NA_real_,
                           aic = NA_real_, n = NA_real_) {
  res <- new_vi_pgls_result(test_name, statistic, p_value, vi_prediction,
                            discriminating, status, values, metadata,
                            beta, r_squared, aic, n)
  validate_vi_pgls_result(res)
}

#' Print vi_pgls_result Object
#'
#' @param x vi_pgls_result object.
#' @param ... Ignored.
#' @return Invisibly returns `x`.
#' @export
print.vi_pgls_result <- function(x, ...) {
  .vi_print_header(x)
  cat("  beta:          ", if (is.na(x$beta)) "NA" else sprintf("%.4g", x$beta), "\n")
  cat("  R-squared:    ", if (is.na(x$r_squared)) "NA" else sprintf("%.4g", x$r_squared), "\n")
  cat("  AIC:           ", if (is.na(x$aic)) "NA" else sprintf("%.4g", x$aic), "\n")
  cat("  n:             ", x$n, "\n")
  invisible(x)
}

#' Summary of vi_pgls_result Object
#'
#' @param object vi_pgls_result object.
#' @param ... Ignored.
#' @return data.frame of canonical columns plus PGLS extras.
#' @export
summary.vi_pgls_result <- function(object, ...) {
  df <- .vi_base_summary(object)
  df$beta <- object$beta
  df$r_squared <- object$r_squared
  df$aic <- object$aic
  df$n <- object$n
  df
}

#' Convert vi_pgls_result to Data Frame
#'
#' @param x vi_pgls_result object.
#' @param row.names Ignored.
#' @param optional Ignored.
#' @param ... Additional arguments.
#' @return Tidy data.frame.
#' @export
as.data.frame.vi_pgls_result <- function(x, row.names = NULL, optional = FALSE, ...) {
  summary.vi_pgls_result(x)
}

# =============================================================================
# VI_NICHE_NE_RESULT CLASS (T4)
# =============================================================================

#' Create vi_niche_ne_result object (constructor)
#'
#' Subclass for T4 niche vs Ne comparison. Extra fields: `niche_r_squared`,
#' `ne_r_squared`, `delta_aic`.
#'
#' @param test_name,statistic,p_value,vi_prediction,discriminating,status,values,metadata
#'   Base fields.
#' @param niche_r_squared Numeric. R² of the niche model.
#' @param ne_r_squared Numeric. R² of the Ne model.
#' @param delta_aic Numeric. AIC(niche) - AIC(Ne) (or NA).
#'
#' @return vi_niche_ne_result object (unvalidated).
#' @keywords internal
new_vi_niche_ne_result <- function(test_name, statistic, p_value, vi_prediction,
                                   discriminating, status, values, metadata,
                                   niche_r_squared, ne_r_squared, delta_aic) {
  obj <- new_vi_test_result(test_name, statistic, p_value, vi_prediction,
                            discriminating, status, values, metadata)
  obj$niche_r_squared <- .vi_or_na(niche_r_squared)
  obj$ne_r_squared <- .vi_or_na(ne_r_squared)
  obj$delta_aic <- .vi_or_na(delta_aic)
  class(obj) <- c("vi_niche_ne_result", "vi_test_result")
  obj
}

#' Validate vi_niche_ne_result object
#'
#' @param x vi_niche_ne_result object.
#' @return Invisible `x` if valid.
#' @keywords internal
validate_vi_niche_ne_result <- function(x) {
  validate_vi_test_result(x)
  if (!is.numeric(x$niche_r_squared) || length(x$niche_r_squared) != 1) {
    stop("niche_r_squared must be a single numeric (or NA)", call. = FALSE)
  }
  if (!is.numeric(x$ne_r_squared) || length(x$ne_r_squared) != 1) {
    stop("ne_r_squared must be a single numeric (or NA)", call. = FALSE)
  }
  if (!is.numeric(x$delta_aic) || length(x$delta_aic) != 1) {
    stop("delta_aic must be a single numeric (or NA)", call. = FALSE)
  }
  invisible(x)
}

#' Public helper for vi_niche_ne_result
#'
#' @param test_name,statistic,p_value,vi_prediction,discriminating,status,values,metadata
#'   Base fields.
#' @param niche_r_squared,ne_r_squared,delta_aic Extra fields.
#' @return Validated vi_niche_ne_result object.
#' @export
vi_niche_ne_result <- function(test_name, statistic = NA_real_, p_value = NA_real_,
                               vi_prediction = "", discriminating = FALSE,
                               status = .vi_status_of(p_value),
                               values = list(), metadata = list(),
                               niche_r_squared = NA_real_, ne_r_squared = NA_real_,
                               delta_aic = NA_real_) {
  res <- new_vi_niche_ne_result(test_name, statistic, p_value, vi_prediction,
                                discriminating, status, values, metadata,
                                niche_r_squared, ne_r_squared, delta_aic)
  validate_vi_niche_ne_result(res)
}

#' Print vi_niche_ne_result Object
#'
#' @param x vi_niche_ne_result object.
#' @param ... Ignored.
#' @return Invisibly returns `x`.
#' @export
print.vi_niche_ne_result <- function(x, ...) {
  .vi_print_header(x)
  cat("  Niche R²:    ", if (is.na(x$niche_r_squared)) "NA" else sprintf("%.4g", x$niche_r_squared), "\n")
  cat("  Ne R²:       ", if (is.na(x$ne_r_squared)) "NA" else sprintf("%.4g", x$ne_r_squared), "\n")
  cat("  ΔAIC (niche-Ne):", if (is.na(x$delta_aic)) "NA" else sprintf("%.4g", x$delta_aic), "\n")
  invisible(x)
}

#' Summary of vi_niche_ne_result Object
#'
#' @param object vi_niche_ne_result object.
#' @param ... Ignored.
#' @return data.frame.
#' @export
summary.vi_niche_ne_result <- function(object, ...) {
  df <- .vi_base_summary(object)
  df$niche_r_squared <- object$niche_r_squared
  df$ne_r_squared <- object$ne_r_squared
  df$delta_aic <- object$delta_aic
  df
}

#' Convert vi_niche_ne_result to Data Frame
#'
#' @param x vi_niche_ne_result object.
#' @param row.names Ignored.
#' @param optional Ignored.
#' @param ... Additional arguments.
#' @return Tidy data.frame.
#' @export
as.data.frame.vi_niche_ne_result <- function(x, row.names = NULL, optional = FALSE, ...) {
  summary.vi_niche_ne_result(x)
}

# =============================================================================
# VI_FLUIDITY_RESULT CLASS (T5)
# =============================================================================

#' Create vi_fluidity_result object (constructor)
#'
#' Subclass for T5 pan-genome fluidity. Extra fields: `lifestyle_r_squared`,
#' `ne_r_squared`, `p_value`.
#'
#' @param test_name,statistic,p_value,vi_prediction,discriminating,status,values,metadata
#'   Base fields.
#' @param lifestyle_r_squared Numeric. R² of the lifestyle model.
#' @param ne_r_squared Numeric. R² of the Ne model.
#' @param p_value Numeric. Test p-value.
#'
#' @return vi_fluidity_result object (unvalidated).
#' @keywords internal
new_vi_fluidity_result <- function(test_name, statistic, p_value, vi_prediction,
                                   discriminating, status, values, metadata,
                                   lifestyle_r_squared, ne_r_squared, p_value2) {
  obj <- new_vi_test_result(test_name, statistic, p_value, vi_prediction,
                            discriminating, status, values, metadata)
  obj$lifestyle_r_squared <- .vi_or_na(lifestyle_r_squared)
  obj$ne_r_squared <- .vi_or_na(ne_r_squared)
  obj$p_value <- .vi_or_na(p_value2)  # class-level p_value
  class(obj) <- c("vi_fluidity_result", "vi_test_result")
  obj
}

#' Validate vi_fluidity_result object
#'
#' @param x vi_fluidity_result object.
#' @return Invisible `x` if valid.
#' @keywords internal
validate_vi_fluidity_result <- function(x) {
  validate_vi_test_result(x)
  if (!is.numeric(x$lifestyle_r_squared) || length(x$lifestyle_r_squared) != 1) {
    stop("lifestyle_r_squared must be a single numeric (or NA)", call. = FALSE)
  }
  if (!is.numeric(x$ne_r_squared) || length(x$ne_r_squared) != 1) {
    stop("ne_r_squared must be a single numeric (or NA)", call. = FALSE)
  }
  invisible(x)
}

#' Public helper for vi_fluidity_result
#'
#' @param test_name,statistic,p_value,vi_prediction,discriminating,status,values,metadata
#'   Base fields.
#' @param lifestyle_r_squared,ne_r_squared,p_value2 Extra fields.
#' @return Validated vi_fluidity_result object.
#' @export
vi_fluidity_result <- function(test_name, statistic = NA_real_, p_value = NA_real_,
                               vi_prediction = "", discriminating = FALSE,
                               status = .vi_status_of(p_value),
                               values = list(), metadata = list(),
                               lifestyle_r_squared = NA_real_, ne_r_squared = NA_real_,
                               p_value2 = NA_real_) {
  res <- new_vi_fluidity_result(test_name, statistic, p_value, vi_prediction,
                                discriminating, status, values, metadata,
                                lifestyle_r_squared, ne_r_squared, p_value2)
  validate_vi_fluidity_result(res)
}

#' Print vi_fluidity_result Object
#'
#' @param x vi_fluidity_result object.
#' @param ... Ignored.
#' @return Invisibly returns `x`.
#' @export
print.vi_fluidity_result <- function(x, ...) {
  .vi_print_header(x)
  cat("  Lifestyle R²: ", if (is.na(x$lifestyle_r_squared)) "NA" else sprintf("%.4g", x$lifestyle_r_squared), "\n")
  cat("  Ne R²:        ", if (is.na(x$ne_r_squared)) "NA" else sprintf("%.4g", x$ne_r_squared), "\n")
  invisible(x)
}

#' Summary of vi_fluidity_result Object
#'
#' @param object vi_fluidity_result object.
#' @param ... Ignored.
#' @return data.frame.
#' @export
summary.vi_fluidity_result <- function(object, ...) {
  df <- .vi_base_summary(object)
  df$lifestyle_r_squared <- object$lifestyle_r_squared
  df$ne_r_squared <- object$ne_r_squared
  df
}

#' Convert vi_fluidity_result to Data Frame
#'
#' @param x vi_fluidity_result object.
#' @param row.names Ignored.
#' @param optional Ignored.
#' @param ... Additional arguments.
#' @return Tidy data.frame.
#' @export
as.data.frame.vi_fluidity_result <- function(x, row.names = NULL, optional = FALSE, ...) {
  summary.vi_fluidity_result(x)
}

# =============================================================================
# VI_ORDERING_RESULT CLASS (T6)
# =============================================================================

#' Create vi_ordering_result object (constructor)
#'
#' Subclass for T6 gene-loss ordering. Extra fields: `rho`, `p_value`,
#' `n_permutations`.
#'
#' @param test_name,statistic,p_value,vi_prediction,discriminating,status,values,metadata
#'   Base fields.
#' @param rho Numeric. Spearman rho.
#' @param p_value Numeric. Permutation p-value.
#' @param n_permutations Integer. Number of permutations.
#'
#' @return vi_ordering_result object (unvalidated).
#' @keywords internal
new_vi_ordering_result <- function(test_name, statistic, p_value, vi_prediction,
                                   discriminating, status, values, metadata,
                                   rho, p_value2, n_permutations) {
  obj <- new_vi_test_result(test_name, statistic, p_value, vi_prediction,
                            discriminating, status, values, metadata)
  obj$rho <- .vi_or_na(rho)
  obj$p_value <- .vi_or_na(p_value2)
  obj$n_permutations <- .vi_or_na(n_permutations)
  class(obj) <- c("vi_ordering_result", "vi_test_result")
  obj
}

#' Validate vi_ordering_result object
#'
#' @param x vi_ordering_result object.
#' @return Invisible `x` if valid.
#' @keywords internal
validate_vi_ordering_result <- function(x) {
  validate_vi_test_result(x)
  if (!is.numeric(x$rho) || length(x$rho) != 1) {
    stop("rho must be a single numeric (or NA)", call. = FALSE)
  }
  if (!is.numeric(x$n_permutations) || length(x$n_permutations) != 1) {
    stop("n_permutations must be a single numeric (or NA)", call. = FALSE)
  }
  invisible(x)
}

#' Public helper for vi_ordering_result
#'
#' @param test_name,statistic,p_value,vi_prediction,discriminating,status,values,metadata
#'   Base fields.
#' @param rho,p_value2,n_permutations Extra fields.
#' @return Validated vi_ordering_result object.
#' @export
vi_ordering_result <- function(test_name, statistic = NA_real_, p_value = NA_real_,
                               vi_prediction = "", discriminating = FALSE,
                               status = .vi_status_of(p_value),
                               values = list(), metadata = list(),
                               rho = NA_real_, p_value2 = NA_real_,
                               n_permutations = NA_real_) {
  res <- new_vi_ordering_result(test_name, statistic, p_value, vi_prediction,
                                discriminating, status, values, metadata,
                                rho, p_value2, n_permutations)
  validate_vi_ordering_result(res)
}

#' Print vi_ordering_result Object
#'
#' @param x vi_ordering_result object.
#' @param ... Ignored.
#' @return Invisibly returns `x`.
#' @export
print.vi_ordering_result <- function(x, ...) {
  .vi_print_header(x)
  cat("  rho:                ", if (is.na(x$rho)) "NA" else sprintf("%.4g", x$rho), "\n")
  cat("  n_permutations:     ", x$n_permutations, "\n")
  invisible(x)
}

#' Summary of vi_ordering_result Object
#'
#' @param object vi_ordering_result object.
#' @param ... Ignored.
#' @return data.frame.
#' @export
summary.vi_ordering_result <- function(object, ...) {
  df <- .vi_base_summary(object)
  df$rho <- object$rho
  df$n_permutations <- object$n_permutations
  df
}

#' Convert vi_ordering_result to Data Frame
#'
#' @param x vi_ordering_result object.
#' @param row.names Ignored.
#' @param optional Ignored.
#' @param ... Additional arguments.
#' @return Tidy data.frame.
#' @export
as.data.frame.vi_ordering_result <- function(x, row.names = NULL, optional = FALSE, ...) {
  summary.vi_ordering_result(x)
}

# =============================================================================
# VI_TRANSFER_RESULT CLASS (L3)
# =============================================================================

#' Create vi_transfer_result object (constructor)
#'
#' Subclass for L3 cross-kingdom transfer. Extra fields: `rho`, `p_value`,
#' `n_null_draws`.
#'
#' @param test_name,statistic,p_value,vi_prediction,discriminating,status,values,metadata
#'   Base fields.
#' @param rho Numeric. Cross-kingdom Spearman rho.
#' @param p_value Numeric. Null p-value.
#' @param n_null_draws Integer. Number of null draws.
#'
#' @return vi_transfer_result object (unvalidated).
#' @keywords internal
new_vi_transfer_result <- function(test_name, statistic, p_value, vi_prediction,
                                   discriminating, status, values, metadata,
                                   rho, p_value2, n_null_draws) {
  obj <- new_vi_test_result(test_name, statistic, p_value, vi_prediction,
                            discriminating, status, values, metadata)
  obj$rho <- .vi_or_na(rho)
  obj$p_value <- .vi_or_na(p_value2)
  obj$n_null_draws <- .vi_or_na(n_null_draws)
  class(obj) <- c("vi_transfer_result", "vi_test_result")
  obj
}

#' Validate vi_transfer_result object
#'
#' @param x vi_transfer_result object.
#' @return Invisible `x` if valid.
#' @keywords internal
validate_vi_transfer_result <- function(x) {
  validate_vi_test_result(x)
  if (!is.numeric(x$rho) || length(x$rho) != 1) {
    stop("rho must be a single numeric (or NA)", call. = FALSE)
  }
  if (!is.numeric(x$n_null_draws) || length(x$n_null_draws) != 1) {
    stop("n_null_draws must be a single numeric (or NA)", call. = FALSE)
  }
  invisible(x)
}

#' Public helper for vi_transfer_result
#'
#' @param test_name,statistic,p_value,vi_prediction,discriminating,status,values,metadata
#'   Base fields.
#' @param rho,p_value2,n_null_draws Extra fields.
#' @return Validated vi_transfer_result object.
#' @export
vi_transfer_result <- function(test_name, statistic = NA_real_, p_value = NA_real_,
                               vi_prediction = "", discriminating = FALSE,
                               status = .vi_status_of(p_value),
                               values = list(), metadata = list(),
                               rho = NA_real_, p_value2 = NA_real_,
                               n_null_draws = NA_real_) {
  res <- new_vi_transfer_result(test_name, statistic, p_value, vi_prediction,
                                discriminating, status, values, metadata,
                                rho, p_value2, n_null_draws)
  validate_vi_transfer_result(res)
}

#' Print vi_transfer_result Object
#'
#' @param x vi_transfer_result object.
#' @param ... Ignored.
#' @return Invisibly returns `x`.
#' @export
print.vi_transfer_result <- function(x, ...) {
  .vi_print_header(x)
  cat("  rho:            ", if (is.na(x$rho)) "NA" else sprintf("%.4g", x$rho), "\n")
  cat("  null draws:     ", x$n_null_draws, "\n")
  invisible(x)
}

#' Summary of vi_transfer_result Object
#'
#' @param object vi_transfer_result object.
#' @param ... Ignored.
#' @return data.frame.
#' @export
summary.vi_transfer_result <- function(object, ...) {
  df <- .vi_base_summary(object)
  df$rho <- object$rho
  df$n_null_draws <- object$n_null_draws
  df
}

#' Convert vi_transfer_result to Data Frame
#'
#' @param x vi_transfer_result object.
#' @param row.names Ignored.
#' @param optional Ignored.
#' @param ... Additional arguments.
#' @return Tidy data.frame.
#' @export
as.data.frame.vi_transfer_result <- function(x, row.names = NULL, optional = FALSE, ...) {
  summary.vi_transfer_result(x)
}

# =============================================================================
# VI_COSEGREGATION_RESULT CLASS (T7)
# =============================================================================

#' Create vi_cosegregation_result object (constructor)
#'
#' Subclass for T7 LTEE co-segregation. Extra fields: `observed_pct`,
#' `expected_pct`, `depletion_ratio`.
#'
#' @param test_name,statistic,p_value,vi_prediction,discriminating,status,values,metadata
#'   Base fields.
#' @param observed_pct Numeric. Observed co-segregation percentage.
#' @param expected_pct Numeric. Expected co-segregation percentage.
#' @param depletion_ratio Numeric. observed/expected ratio.
#'
#' @return vi_cosegregation_result object (unvalidated).
#' @keywords internal
new_vi_cosegregation_result <- function(test_name, statistic, p_value,
                                        vi_prediction, discriminating, status,
                                        values, metadata, observed_pct,
                                        expected_pct, depletion_ratio) {
  obj <- new_vi_test_result(test_name, statistic, p_value, vi_prediction,
                            discriminating, status, values, metadata)
  obj$observed_pct <- .vi_or_na(observed_pct)
  obj$expected_pct <- .vi_or_na(expected_pct)
  obj$depletion_ratio <- .vi_or_na(depletion_ratio)
  class(obj) <- c("vi_cosegregation_result", "vi_test_result")
  obj
}

#' Validate vi_cosegregation_result object
#'
#' @param x vi_cosegregation_result object.
#' @return Invisible `x` if valid.
#' @keywords internal
validate_vi_cosegregation_result <- function(x) {
  validate_vi_test_result(x)
  if (!is.numeric(x$observed_pct) || length(x$observed_pct) != 1) {
    stop("observed_pct must be a single numeric (or NA)", call. = FALSE)
  }
  if (!is.numeric(x$expected_pct) || length(x$expected_pct) != 1) {
    stop("expected_pct must be a single numeric (or NA)", call. = FALSE)
  }
  if (!is.numeric(x$depletion_ratio) || length(x$depletion_ratio) != 1) {
    stop("depletion_ratio must be a single numeric (or NA)", call. = FALSE)
  }
  invisible(x)
}

#' Public helper for vi_cosegregation_result
#'
#' @param test_name,statistic,p_value,vi_prediction,discriminating,status,values,metadata
#'   Base fields.
#' @param observed_pct,expected_pct,depletion_ratio Extra fields.
#' @return Validated vi_cosegregation_result object.
#' @export
vi_cosegregation_result <- function(test_name, statistic = NA_real_, p_value = NA_real_,
                                    vi_prediction = "", discriminating = FALSE,
                                    status = .vi_status_of(p_value),
                                    values = list(), metadata = list(),
                                    observed_pct = NA_real_, expected_pct = NA_real_,
                                    depletion_ratio = NA_real_) {
  res <- new_vi_cosegregation_result(test_name, statistic, p_value, vi_prediction,
                                     discriminating, status, values, metadata,
                                     observed_pct, expected_pct, depletion_ratio)
  validate_vi_cosegregation_result(res)
}

#' Print vi_cosegregation_result Object
#'
#' @param x vi_cosegregation_result object.
#' @param ... Ignored.
#' @return Invisibly returns `x`.
#' @export
print.vi_cosegregation_result <- function(x, ...) {
  .vi_print_header(x)
  cat("  Observed %:    ", if (is.na(x$observed_pct)) "NA" else sprintf("%.2f", x$observed_pct), "\n")
  cat("  Expected %:    ", if (is.na(x$expected_pct)) "NA" else sprintf("%.2f", x$expected_pct), "\n")
  cat("  Depletion ratio:", if (is.na(x$depletion_ratio)) "NA" else sprintf("%.4g", x$depletion_ratio), "\n")
  invisible(x)
}

#' Summary of vi_cosegregation_result Object
#'
#' @param object vi_cosegregation_result object.
#' @param ... Ignored.
#' @return data.frame.
#' @export
summary.vi_cosegregation_result <- function(object, ...) {
  df <- .vi_base_summary(object)
  df$observed_pct <- object$observed_pct
  df$expected_pct <- object$expected_pct
  df$depletion_ratio <- object$depletion_ratio
  df
}

#' Convert vi_cosegregation_result to Data Frame
#'
#' @param x vi_cosegregation_result object.
#' @param row.names Ignored.
#' @param optional Ignored.
#' @param ... Additional arguments.
#' @return Tidy data.frame.
#' @export
as.data.frame.vi_cosegregation_result <- function(x, row.names = NULL, optional = FALSE, ...) {
  summary.vi_cosegregation_result(x)
}