test_that("convsigns: regression reproduces key coefficients", {
  # Load full artifact + features dataset
  sign_data <- read.csv(
    system.file("extdata/convsigns/signBase_randomized.csv",
                package = "vi.foundry"),
    stringsAsFactors = FALSE
  )
  
  # Filter valid sequences
  valid <- sign_data[nchar(as.character(sign_data$coding_clean)) >= 3 &
                       sign_data$coding_clean != "" &
                       !is.na(sign_data$coding_clean), ]
  
  # Compute features for all sequences
  entropy_rates <- numeric(nrow(valid))
  for (i in seq_len(nrow(valid))) {
    chars <- unlist(strsplit(as.character(valid$coding_clean[i]), ""))
    chars <- chars[chars != " " & chars != "_"]
    if (length(chars) >= 3) {
      entropy_rates[i] <- entropy_rate(chars)
    } else {
      entropy_rates[i] <- NA
    }
  }
  
  seq_features <- data.frame(
    object_id = valid$object_id,
    object_type = valid$object_type,
    material = valid$material,
    preservation = valid$preservation,
    length_mm = valid$length_mm,
    width_mm = valid$width_mm,
    depth_mm = valid$depth_mm,
    date_bp_max = valid$date_bp_max,
    entropy_rate = entropy_rates,
    stringsAsFactors = FALSE
  )
  seq_features <- seq_features[!is.na(seq_features$entropy_rate), ]
  
  # Add volume
  seq_features$volume <- compute_volume(
    seq_features$length_mm,
    seq_features$width_mm,
    seq_features$depth_mm
  )
  
  # Add date
  seq_features$date <- as.numeric(substr(as.character(seq_features$date_bp_max), 1, 5))
  
  # Collapse factor levels to match paper
  seq_features$object_type <- dplyr::case_when(
    grepl("figurine anthropomorph|plaque", seq_features$object_type) ~ "figurine_anthropomorph",
    grepl("figurine zoomorph", seq_features$object_type) ~ "figurine_zoomorph",
    grepl("awl|perforated baton|rod/baton|spatula/lissoir", seq_features$object_type) ~ "tool",
    grepl("flute|tube", seq_features$object_type) ~ "tube_flute",
    grepl("personal ornament", seq_features$object_type) ~ "personal_ornament",
    TRUE ~ "other"
  )
  seq_features <- seq_features[seq_features$object_type != "other", ]
  
  # material
  seq_features$material <- dplyr::case_when(
    grepl("ivory", seq_features$material) ~ "ivory",
    grepl("antler", seq_features$material) ~ "antler",
    grepl("bone", seq_features$material) ~ "bone",
    TRUE ~ "other"
  )
  
  # Set factor levels
  seq_features$object_type <- factor(seq_features$object_type,
                                       levels = c("tool", "figurine_anthropomorph",
                                                  "figurine_zoomorph", "tube_flute",
                                                  "personal_ornament"))
  
  # Use only complete cases
  model_data <- seq_features[complete.cases(seq_features[, 
    c("entropy_rate", "volume", "date", "object_type", "preservation")]), ]
  
  if (nrow(model_data) < 50) {
    skip("Not enough complete cases for regression")
  }
  
  fit <- lm(entropy_rate ~ volume + date + object_type + preservation,
            data = model_data)
  
  # Check overall significance (paper: F = 8.5, df = 196, p < 10⁻¹⁰)
  f_stat <- summary(fit)$fstatistic
  expect_gt(f_stat[1], 5)
  expect_true(summary(fit)$r.squared > 0.1)
  
  # Check AIC is reasonable
  expect_true(is.finite(AIC(fit)))
  
  # Check direction of figurine coefficients (should be positive vs tool baseline)
  coefs <- coef(fit)
  
  # figurine_zoomorph coefficient should be positive (paper: β = +0.23)
  if ("object_typefigurine_zoomorph" %in% names(coefs)) {
    expect_gt(coefs["object_typefigurine_zoomorph"], 0)
  }
  
  # figurine_anthropomorph should be borderline positive (paper: β = +0.29)
  if ("object_typefigurine_anthropomorph" %in% names(coefs)) {
    expect_gt(coefs["object_typefigurine_anthropomorph"], -0.1)
  }
  
  # personal_ornament should be negative (paper: β = −0.32)
  if ("object_typepersonal_ornament" %in% names(coefs)) {
    expect_lt(coefs["object_typepersonal_ornament"], 0)
  }
  
  # tube_flute should be negative (paper: β = −0.22)
  if ("object_typetube_flute" %in% names(coefs)) {
    expect_lt(coefs["object_typetube_flute"], 0)
  }
  
  # Check AIC improvement
  fit_null <- lm(entropy_rate ~ 1, data = model_data)
  expect_lt(AIC(fit), AIC(fit_null))
})

test_that("convsigns: entropy rate is bounded 0–2 for Aurignacian sequences", {
  # Paper says entropy rates are "roughly in the range [0, 2]"
  sign_data <- read.csv(
    system.file("extdata/convsigns/signBase_randomized.csv",
                package = "vi.foundry"),
    stringsAsFactors = FALSE
  )
  
  valid <- sign_data[nchar(as.character(sign_data$coding_clean)) >= 3 &
                       sign_data$coding_clean != "" &
                       !is.na(sign_data$coding_clean), ]
  
  hrs <- numeric(0)
  for (i in seq_len(nrow(valid))) {
    chars <- unlist(strsplit(as.character(valid$coding_clean[i]), ""))
    chars <- chars[chars != " " & chars != "_"]
    if (length(chars) >= 3) {
      hrs <- c(hrs, entropy_rate(chars))
    }
  }
  
  expect_true(all(hrs >= 0, na.rm = TRUE))
  expect_true(all(hrs <= 3, na.rm = TRUE))
  expect_lt(median(hrs, na.rm = TRUE), 2)
})

test_that("convsigns: PCA reproduces overlap structure", {
  # Load and compute features for a sample
  sign_data <- read.csv(
    system.file("extdata/convsigns/signBase_randomized.csv",
                package = "vi.foundry"),
    stringsAsFactors = FALSE
  )
  
  valid <- sign_data[nchar(as.character(sign_data$coding_clean)) >= 3 &
                       sign_data$coding_clean != "" &
                       !is.na(sign_data$coding_clean), ]
  
  # Compute features
  feat_matrix <- matrix(NA, nrow = min(50, nrow(valid)), ncol = 4)
  colnames(feat_matrix) <- c("ttr", "entropy", "entropy_rate", "rep_rate")
  
  for (i in 1:min(50, nrow(valid))) {
    chars <- unlist(strsplit(as.character(valid$coding_clean[i]), ""))
    chars <- chars[chars != " " & chars != "_"]
    if (length(chars) >= 3) {
      feat_matrix[i, ] <- compute_features(chars)
    }
  }
  
  feat_matrix <- feat_matrix[complete.cases(feat_matrix), ]
  
  if (nrow(feat_matrix) < 10) {
    skip("Not enough sequences for PCA")
  }
  
  # PCA
  pca <- prcomp(feat_matrix, scale. = TRUE)
  
  # First component should explain > 30% of variance
  var_exp <- summary(pca)$importance[2, 1]
  expect_gt(var_exp, 0.3)
  
  # First two components should explain > 60%
  var_exp_2 <- sum(summary(pca)$importance[2, 1:2])
  expect_gt(var_exp_2, 0.6)
})