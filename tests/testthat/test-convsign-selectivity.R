test_that("convsigns: sign-type x object-type selectivity (chi-square)", {
  sign_data <- read.csv(
    system.file("extdata/convsigns/signBase_randomized.csv", package = "vi.foundry"),
    stringsAsFactors = FALSE
  )
  
  # Collapse object types per paper
  sign_data$obj_type <- dplyr::case_when(
    grepl("figurine anthropomorph|plaque", sign_data$object_type) ~ "fig_anthropomorph",
    grepl("figurine zoomorph", sign_data$object_type) ~ "fig_zoomorph",
    grepl("awl|perforated baton|rod/baton|spatula/lissoir", sign_data$object_type) ~ "tool",
    grepl("flute|tube", sign_data$object_type) ~ "tube_flute",
    grepl("personal ornament", sign_data$object_type) ~ "personal_ornament",
    TRUE ~ "other"
  )
  sign_data <- sign_data[sign_data$obj_type != "other", ]
  
  # Build sign token table
  signs <- c()
  obj_types <- c()
  for (i in seq_len(nrow(sign_data))) {
    code <- as.character(sign_data$coding_clean[i])
    if (nchar(code) < 3) next
    obj_type <- sign_data$obj_type[i]
    chars <- unlist(strsplit(code, ""))
    chars <- chars[chars != " " & chars != "_"]
    for (c in chars) {
      signs <- c(signs, c)
      obj_types <- c(obj_types, obj_type)
    }
  }
  
  # Classify into cross/dot families
  cross_set <- c("X", "+", "x", "*")
  dot_set <- c(".", "v", "•")
  
  families <- character(length(signs))
  for (i in 1:length(signs)) {
    if (signs[i] %in% cross_set) {
      families[i] <- "cross"
    } else if (signs[i] %in% dot_set) {
      families[i] <- "dot"
    } else {
      families[i] <- "other"
    }
  }
  
  # Only cross/dot
  keep <- families == "cross" | families == "dot"
  families <- families[keep]
  obj_types <- obj_types[keep]
  
  obj_type_levels <- sort(unique(obj_types))
  family_levels <- c("cross", "dot")
  
  # Build contingency matrix
  nf <- length(family_levels)
  no <- length(obj_type_levels)
  cont <- matrix(0, nf, no)
  for (i in 1:nf) {
    for (j in 1:no) {
      cont[i, j] <- sum(families == family_levels[i] & obj_types == obj_type_levels[j])
    }
  }
  
  # Chi-square test
  chi_sq <- chisq.test(cont)
  
  # Should be massively significant
  expect_lt(chi_sq$p.value, 0.001)
  expect_gt(chi_sq$statistic, 20)
  
  # Check specific: crosses on anthropomorphs = 0
  idx_anthro <- which(obj_type_levels == "fig_anthropomorph")
  idx_cross <- 1
  if (idx_anthro > 0) {
    expect_equal(cont[idx_cross, idx_anthro], 0)
  }
})

test_that("convsigns: Fisher exact — crosses on anthropomorphs vs tools", {
  sign_data <- read.csv(
    system.file("extdata/convsigns/signBase_randomized.csv", package = "vi.foundry"),
    stringsAsFactors = FALSE
  )
  
  sign_data$obj_type <- dplyr::case_when(
    grepl("figurine anthropomorph|plaque", sign_data$object_type) ~ "fig_anthropomorph",
    grepl("figurine zoomorph", sign_data$object_type) ~ "fig_zoomorph",
    grepl("awl|perforated baton|rod/baton|spatula/lissoir", sign_data$object_type) ~ "tool",
    grepl("flute|tube", sign_data$object_type) ~ "tube_flute",
    grepl("personal ornament", sign_data$object_type) ~ "personal_ornament",
    TRUE ~ "other"
  )
  sign_data <- sign_data[sign_data$obj_type != "other", ]
  
  cross_set <- c("X", "+", "x", "*")
  dot_set <- c(".", "v", "•")
  
  c_anthro <- 0
  d_anthro <- 0
  c_tool <- 0
  d_tool <- 0
  
  for (i in seq_len(nrow(sign_data))) {
    ot <- sign_data$obj_type[i]
    if (ot != "fig_anthropomorph" && ot != "tool") next
    code <- as.character(sign_data$coding_clean[i])
    if (nchar(code) < 3) next
    chars <- unlist(strsplit(code, ""))
    chars <- chars[chars != " " & chars != "_"]
    for (c in chars) {
      if (c %in% cross_set) {
        if (ot == "fig_anthropomorph") c_anthro <- c_anthro + 1
        else if (ot == "tool") c_tool <- c_tool + 1
      } else if (c %in% dot_set) {
        if (ot == "fig_anthropomorph") d_anthro <- d_anthro + 1
        else if (ot == "tool") d_tool <- d_tool + 1
      }
    }
  }
  
  # Hypergeometric probability of 0 crosses landing on anthropomorphs
  n_total <- c_anthro + d_anthro + c_tool + d_tool
  total_crosses <- c_anthro + c_tool
  anthro_tokens <- c_anthro + d_anthro
  
  p_value <- choose(n_total - total_crosses, anthro_tokens) / choose(n_total, anthro_tokens)
  
  expect_lt(p_value, 0.01)
  expect_equal(c_anthro, 0)
  expect_gt(c_tool, 10)
  expect_gt(d_anthro, 10)
})

test_that("convsigns: full sign-type x object-type contingency (chi-square)", {
  sign_data <- read.csv(
    system.file("extdata/convsigns/signBase_randomized.csv", package = "vi.foundry"),
    stringsAsFactors = FALSE
  )
  
  sign_data$obj_type <- dplyr::case_when(
    grepl("figurine anthropomorph|plaque", sign_data$object_type) ~ "fig_anthropomorph",
    grepl("figurine zoomorph", sign_data$object_type) ~ "fig_zoomorph",
    grepl("awl|perforated baton|rod/baton|spatula/lissoir", sign_data$object_type) ~ "tool",
    grepl("flute|tube", sign_data$object_type) ~ "tube_flute",
    grepl("personal ornament", sign_data$object_type) ~ "personal_ornament",
    TRUE ~ "other"
  )
  sign_data <- sign_data[sign_data$obj_type != "other", ]
  
  # Count sign tokens per (sign, obj_type) pair
  sign_rows <- list()
  idx <- 0
  for (i in seq_len(nrow(sign_data))) {
    code <- as.character(sign_data$coding_clean[i])
    if (nchar(code) < 3) next
    ot <- sign_data$obj_type[i]
    chars <- unlist(strsplit(code, ""))
    chars <- chars[chars != " " & chars != "_"]
    for (c in chars) {
      idx <- idx + 1
      sign_rows[[idx]] <- list(sign = c, obj_type = ot)
    }
  }
  
  # Build data frame
  signs_vec <- sapply(sign_rows, function(r) r$sign)
  obj_vec <- sapply(sign_rows, function(r) r$obj_type)
  
  # Filter to signs appearing >= 5 times
  tbl <- data.frame(sign = signs_vec, obj_type = obj_vec, stringsAsFactors = FALSE)
  sign_ct <- table(tbl$sign)
  common_ct_names <- names(sign_ct)
  common_ct_vals <- as.numeric(sign_ct)
  common <- common_ct_names[common_ct_vals >= 5]
  tbl <- tbl[tbl$sign %in% common, ]
  
  # Build contingency
  sign_lev <- unique(tbl$sign)
  obj_lev <- unique(tbl$obj_type)
  ns <- length(sign_lev)
  no <- length(obj_lev)
  
  cont <- matrix(0, ns, no)
  for (i in 1:ns) {
    for (j in 1:no) {
      cont[i, j] <- sum(tbl$sign == sign_lev[i] & tbl$obj_type == obj_lev[j])
    }
  }
  
  # Drop zero rows/cols
  rs <- sapply(1:ns, function(i) sum(cont[i, ]))
  cs <- sapply(1:no, function(j) sum(cont[, j]))
  keep_r <- rs > 0
  keep_c <- cs > 0
  
  if (sum(keep_r) >= 2 && sum(keep_c) >= 2) {
    reduced <- cont[keep_r, keep_c]
    chi_sq <- chisq.test(reduced)
    expect_lt(chi_sq$p.value, 0.001)
    expect_gt(chi_sq$statistic, 30)
    
    # Print the contingency for the record
    cat(sprintf("Contingency: %d signs x %d types, X² = %.1f, p ~ 0\n",
      sum(keep_r), sum(keep_c), chi_sq$statistic))
  }
})