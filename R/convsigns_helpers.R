#' Helper functions for the Bentz & Dutkiewicz (2026) conventional signs analysis
#'
#' Implements statistical features in pure base R to avoid package dependencies.
#' All implementations follow the paper's equations (3–12).
#'
#' @section Features:
#' - TTR: type-token ratio (eq 3)
#' - unigram_entropy: ML-estimated Shannon entropy (eqs 4–7)
#' - entropy_rate: LZ78-based increasing-window estimator (eq 10)
#' - repetition_rate: adjacent repetition rate, lsmo variant (eq 12 modified)
#' - volume: derived from length, width, depth
#'
#' @name convsigns-helpers
#' @rdname convsigns-helpers
NULL

#' Type-Token Ratio
#'
#' Number of unique types divided by number of tokens (eq 3).
#' Range: (0, 1] for nonempty sequences.
#'
#' @param chars Character vector (UTF-8 string split into individual chars)
#' @return Numeric TTR value
#' @export
#' @examples
#' chars <- unlist(strsplit("XX_vvvvvvvv_vvvv", ""))
#' ttr(chars)  # 3/16 ≈ 0.19
ttr <- function(chars) {
  if (length(chars) == 0) return(NA_real_)
  length(unique(chars)) / length(chars)
}

#' Unigram Entropy (ML estimator)
#'
#' Shannon entropy estimated via maximum likelihood (plug-in) estimator.
#' Uses log base 2 (bits per sign).
#'
#' H_ML = -Σ (fi/n) log2(fi/n)  (eqs 4–7)
#'
#' @param chars Character vector
#' @return Numeric entropy in bits/sign
#' @examples
#' chars <- unlist(strsplit("Mila esker maitea ", ""))
#' unigram_entropy(chars)  # ≈ 3.29 bits/sign (for Basque example)
unigram_entropy <- function(chars) {
  if (length(chars) == 0) return(NA_real_)
  tbl <- table(chars)
  freq <- as.numeric(tbl)
  n <- sum(freq)
  probs <- freq / n
  -sum(probs * log2(probs))
}

#' Entropy Rate (LZ78-based estimator)
#'
#' Increasing-window estimator based on Lempel-Ziv compression.
#' Follows Gao et al. (2008) equation (6), reproduced as eq 10.
#'
#' ĥ(s) = (1/n) Σ_{i=2}^{n} log2(i) / L_i
#'
#' where L_i is the length (+1) of the longest contiguous subsequence
#' starting at position i which also appears in the prefix s[1:(i-1)].
#'
#' @param chars Character vector
#' @return Numeric entropy rate in bits/sign
#' @examples
#' chars <- unlist(strsplit("same_but_different", ""))
#' entropy_rate(chars)
entropy_rate <- function(chars) {
  if (length(chars) <= 1) return(NA_real_)
  n <- length(chars)
  total <- 0
  for (i in 2:n) {
    # longest match of subsequence starting at i in prefix chars[1:(i-1)]
    max_len <- 0
    prefix <- chars[1:(i - 1)]
    for (k in 1:min(50, n - i + 1)) {
      subseq <- chars[i:(i + k - 1)]
      # Check if this subseq exists anywhere in prefix as contiguous
      found <- FALSE
      if (k <= length(prefix)) {
        for (start in 1:(length(prefix) - k + 1)) {
          if (all(prefix[start:(start + k - 1)] == subseq)) {
            found <- TRUE
            break
          }
        }
      }
      if (found) {
        max_len <- k
      } else {
        break
      }
    }
    Li <- max_len + 1
    total <- total + log2(i) / Li
  }
  total / n
}

#' Repetition Rate (lsmo variant)
#'
#' Number of adjacent repetitions divided by (n - 1).
#' This is the lsmo-modified version of Sproat's repetition rate (eq 12).
#'
#' @param chars Character vector
#' @return Numeric repetition rate in [0, 1]
#' @examples
#' chars <- unlist(strsplit("XXXXX", ""))
#' repetition_rate(chars)  # 1.0
repetition_rate <- function(chars) {
  if (length(chars) <= 1) return(NA_real_)
  n <- length(chars)
  radj <- 0
  for (i in 1:(n - 1)) {
    if (chars[i] == chars[i + 1]) {
      radj <- radj + 1
    }
  }
  radj / (n - 1)
}

#' Compute all four features for a sequence
#'
#' @param chars Character vector (UTF-8 chars)
#' @return Named numeric vector: ttr, entropy, entropy_rate, rep_rate
compute_features <- function(chars) {
  c(
    ttr = ttr(chars),
    entropy = unigram_entropy(chars),
    entropy_rate = entropy_rate(chars),
    rep_rate = repetition_rate(chars)
  )
}

#' Compute volume from length, width, depth (mm → cm³)
#'
#' @param length_mm,width_mm,depth_mm Numeric dimensions in mm
#' @return Numeric volume in cm³
compute_volume <- function(length_mm, width_mm, depth_mm) {
  (length_mm * width_mm * depth_mm) / 1000
}

#' Extract max date BP from date_bp_max string
#'
#' Takes the first 5 characters (the year value) as numeric.
#'
#' @param date_string Character string like "35810±710"
#' @return Numeric max date BP
extract_date_bp <- function(date_string) {
  as.numeric(substr(as.character(date_string), 1, 5))
}

#' Error of approximation for entropy rate estimator
#'
#' For short highly repetitive sequences the LZ78 estimator overestimates.
#' This stabilizes as n increases. See SI Appendix Figs. S9–S12.
#'
#' @param n Sequence length
#' @return Logical: TRUE if n >= 3 (minimum for meaningful estimation)
valid_sequence_length <- function(n) {
  n >= 3
}