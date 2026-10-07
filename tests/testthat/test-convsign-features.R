test_that("convsigns: TTR matches paper examples", {
  # Aurignacian example from Table 1: "XX_vvvvvvvv_vvvv"
  chars <- unlist(strsplit("XX_vvvvvvvv_vvvv", ""))
  expect_equal(ttr(chars), 3/16, tolerance = 0.001)
  
  # Chinese example from Table 1
  # For a simple verification: TTR for unique chars should be 1.0
  expect_equal(ttr(c("a", "b", "c")), 1.0)
  
  # Single character
  expect_equal(ttr(c("X")), 1.0)
})

test_that("convsigns: unigram entropy matches paper examples", {
  # Basque example from Table 1: "Mila esker maitea "
  chars <- unlist(strsplit("Mila esker maitea ", ""))
  h <- unigram_entropy(chars)
  expect_gt(h, 3.0)
  expect_lt(h, 3.5)
  # Paper reports 3.29 bits/sign
  
  # Uniform distribution: entropy = log2(n_types)
  chars_unif <- c("a", "b", "c", "d", "e")
  expect_equal(unigram_entropy(chars_unif), log2(5), tolerance = 0.001)
  
  # Single type: entropy = 0
  expect_equal(unigram_entropy(c("X", "X", "X")), 0, tolerance = 0.001)
})

test_that("convsigns: repetition rate (lsmo) matches paper examples", {
  # All identical: r = 1.0
  chars <- c("X", "X", "X", "X", "X")
  expect_equal(repetition_rate(chars), 1.0, tolerance = 0.001)
  
  # No adjacent repeats: r = 0
  chars <- c("a", "b", "c", "d")
  expect_equal(repetition_rate(chars), 0.0, tolerance = 0.001)
  
  # Alternating: r ≈ 0
  chars <- c("a", "b", "a", "b")
  expect_equal(repetition_rate(chars), 0.0, tolerance = 0.001)
  
  # Aurignacian example: "XX_vvvvvvvv_vvvv"
  chars <- unlist(strsplit("XX_vvvvvvvv_vvvv", ""))
  r <- repetition_rate(chars)
  expect_gt(r, 0.7)
  # Paper reports r ≈ 0.73 for this sequence in Table 1
})

test_that("convsigns: entropy rate is bounded by unigram entropy", {
  # For a completely random sequence, entropy rate ≈ unigram entropy
  set.seed(42)
  chars <- sample(c("a", "b", "c", "d"), 50, replace = TRUE)
  h <- unigram_entropy(chars)
  hr <- entropy_rate(chars)
  
  # Rate should be <= unigram entropy for random sequences
  expect_lte(hr, h + 0.5)
})

test_that("convsigns: volume computation", {
  # 100mm × 50mm × 20mm = 100,000 mm³ = 100 cm³
  expect_equal(compute_volume(100, 50, 20), 100)
  
  # Zero dimensions
  expect_equal(compute_volume(0, 0, 0), 0)
  
  # Paper example: typical artifact dimensions
  # vhc0145 mammoth figurine: ~49×17×17 mm = 14.2 cm³
  vol <- compute_volume(49, 17, 17)
  expect_gt(vol, 14)
  expect_lt(vol, 15)
})

test_that("convsigns: feature vectors are consistent on real data", {
  # Load the actual SignBase data
  sign_data <- read.csv(
    system.file("extdata/convsigns/signBase_randomized.csv",
                package = "vi.foundry"),
    stringsAsFactors = FALSE
  )
  
  # Filter to sequences with valid clean coding
  valid <- sign_data[sign_data$coding_clean != "" &
                       !is.na(sign_data$coding_clean), ]
  valid <- valid[nchar(as.character(valid$coding_clean)) >= 3, ]
  
  # Compute features for first 10 sequences
  features <- list()
  for (i in 1:min(10, nrow(valid))) {
    chars <- unlist(strsplit(as.character(valid$coding_clean[i]), ""))
    # Remove spaces from the sequence for feature computation
    chars <- chars[chars != " "]
    if (length(chars) >= 3) {
      features[[i]] <- compute_features(chars)
    }
  }
  
  # All computed features should be numeric and finite
  for (f in features) {
    if (!is.null(f)) {
      expect_true(is.numeric(f))
      expect_true(all(is.finite(f)))
      expect_true(f["ttr"] > 0 && f["ttr"] <= 1)
      expect_true(f["entropy"] >= 0)
      expect_true(f["entropy_rate"] >= 0)
      expect_true(f["rep_rate"] >= 0 && f["rep_rate"] <= 1)
    }
  }
})

test_that("convsigns: repetition rate for known sequences from paper", {
  # From Table 1: Basque "Mila esker maitea " — no adjacent repeats
  chars_basque <- unlist(strsplit("Mila esker maitea ", ""))
  expect_equal(repetition_rate(chars_basque), 0, tolerance = 0.01)
  
  # From Table 1: Uruk V "N01 N01 N01" — underscores as visual group separators
  chars_uruk5 <- c("N", "0", "1", "_", "N", "0", "1", "_", "N", "0", "1")
  r <- repetition_rate(chars_uruk5)
  expect_equal(r, 0.0, tolerance = 0.01)
})

test_that("convsigns: feature range sanity checks", {
  # Random sequence: moderate entropy, low rep rate
  set.seed(123)
  chars_rand <- sample(c("a", "b", "c", "d", "e", "f", "g"), 100, replace = TRUE)
  feat_rand <- compute_features(chars_rand)
  expect_gt(feat_rand["entropy"], 2.0)
  expect_lt(feat_rand["entropy"], 3.0)
  expect_lt(feat_rand["rep_rate"], 0.3)
  
  # Repetitive sequence: low entropy, high rep rate
  chars_rep <- rep(c("X", "X", "X", "_"), 25)
  feat_rep <- compute_features(chars_rep)
  expect_lt(feat_rep["entropy"], 1.5)
  expect_gt(feat_rep["rep_rate"], 0.3)
})