#' Data loaders for Body-Grammar analyses
#'
#' @section Data sources:
#' - GramBank GB305: `data/glottobank/grambank/.../cldf/values.csv`
#' - Reflexive source types: `work/marsyas6/papers/other/supplementary/S_source_typed_reflexives.csv`
#' - CHG admixture: `data/analysis/adna-caucasus/chg-admixture-table.csv`
#' - Glottolog languages & families
#'
#' @name body_grammar_loaders
NULL

#' Load GramBank GB305 values
#'
#' @param values_path Path to GramBank values.csv
#' @param languages_path Path to GramBank languages.csv
#' @return Data frame with language_id, family, macroarea, latitude, longitude, gb305
#' @export
load_grambank_gb305 <- function(
    values_path = NULL,
    languages_path = NULL) {

  # Default paths
  if (is.null(values_path)) {
    values_path <- file.path("data", "glottobank", "grambank",
                             "grambank_extracted", "grambank-grambank-7ae000c",
                             "cldf", "values.csv")
  }
  if (is.null(languages_path)) {
    languages_path <- file.path("data", "glottobank", "grambank",
                                "grambank_extracted", "grambank-grambank-7ae000c",
                                "cldf", "languages.csv")
  }

  stopifnot(file.exists(values_path))
  stopifnot(file.exists(languages_path))

  # Load values — filter for GB305 (reflexive pronoun presence)
  values <- utils::read.csv(values_path, stringsAsFactors = FALSE)
  gb305 <- values[values$Parameter_ID == "GB305", ]
  names(gb305)[names(gb305) == "Value"] <- "gb305"
  names(gb305)[names(gb305) == "Language_ID"] <- "language_id"

  # Load languages
  languages <- utils::read.csv(languages_path, stringsAsFactors = FALSE)
  names(languages)[names(languages) == "ID"] <- "language_id"

  # Merge
  merged <- merge(gb305[, c("language_id", "gb305")],
                  languages[, c("language_id", "Name", "Family_name",
                                "Macroarea", "Latitude", "Longitude",
                                "Family_level_ID", "Language_level_ID")],
                  by = "language_id", all.x = TRUE)

  # Clean lat/lon
  merged$Latitude <- as.numeric(merged$Latitude)
  merged$Longitude <- as.numeric(merged$Longitude)

  list(data = merged, n = nrow(merged))
}

#' Load S_source_typed_reflexives.csv — HEAD/BODY classification
#'
#' @param path Path to reflexives CSV
#' @return Data frame with glottocode, language, source_type, source_word, gloss
#' @export
load_reflexive_sources <- function(
    path = file.path("work", "marsyas6", "papers", "other", "supplementary",
                     "S_source_typed_reflexives.csv")) {

  stopifnot(file.exists(path))

  df <- utils::read.csv(path, stringsAsFactors = FALSE)

  # Normalize column names
  names(df) <- tolower(gsub("\\.", "_", names(df)))

  # Ensure source_type is capitalized
  if ("source_type" %in% names(df)) {
    df$source_type <- toupper(df$source_type)
  }

  # Count by type
  counts <- table(df$source_type)

  list(
    data = df,
    n = nrow(df),
    n_head = if (is.null(counts[["HEAD"]])) 0 else counts[["HEAD"]],
    n_body = if (is.null(counts[["BODY"]])) 0 else counts[["BODY"]],
    n_other = sum(counts[!names(counts) %in% c("HEAD", "BODY")], na.rm = TRUE)
  )
}

#' Load CHG admixture table
#'
#' @param path Path to CSV with population, family, chg_pct, p4_present
#' @return Data frame with validated numeric columns
#' @export
load_chg_admixture <- function(
    path = file.path("data", "analysis", "adna-caucasus",
                     "chg-admixture-table.csv")) {

  stopifnot(file.exists(path))

  df <- utils::read.csv(path, stringsAsFactors = FALSE)

  # Normalise column names
  names(df) <- tolower(gsub("\\.", "_", names(df)))

  # Extract CHG percentage as numeric
  if ("chg_fraction_percent" %in% names(df)) {
    df$chg_pct <- as.numeric(df$chg_fraction_percent)
  } else if ("chg_pct" %in% names(df)) {
    df$chg_pct <- as.numeric(df$chg_pct)
  }

  # P4 presence as binary
  if ("p4_present" %in% names(df)) {
    df$p4_present <- as.integer(df$p4_present %in% c("YES", "yes", "Y", 1))
  }

  list(data = df, n = nrow(df))
}

#' Merge P4 classification with GramBank GB305
#'
#' Creates the analysis dataset: P4 (HEAD=1, all others=0) × GB305 × coordinates
#'
#' @param reflexive_list Output of load_reflexive_sources()
#' @param gb305_list Output of load_grambank_gb305()
#' @param remove_contaminated Logical. Remove 7 known contaminated entries? (default TRUE)
#' @return Data frame ready for GLMM
#' @export
build_p4_analysis_dataframe <- function(reflexive_list, gb305_list,
                                         remove_contaminated = TRUE) {
  reflex <- reflexive_list$data
  gb305 <- gb305_list$data

  # Map glottocode in reflex to language_id in gb305
  glottocode_col <- intersect(names(reflex), c("glottocode", "language_id"))[1]
  names(reflex)[names(reflex) == glottocode_col] <- "glottocode_tmp"
  reflex$p4 <- ifelse(is.na(reflex$source_type), 0L, as.integer(toupper(reflex$source_type) == "HEAD"))


  # Known contaminated glottocodes
  contaminated <- c("oloo1241", "kaba1281", "shee1238",
                     "kuna1268", "bamu1253", "marg1265", "huuu1240")

  if (remove_contaminated) {
    reflex <- reflex[!reflex$glottocode_tmp %in% contaminated, ]
  }

  # Merge reflexives with GB305
  merged <- merge(
    gb305,
    reflex[, c("glottocode_tmp", "p4", "source_type", "source_term")],
    by.x = "language_id", by.y = "glottocode_tmp",
    all.x = TRUE
  )

  # Set NAs to 0 (languages without HEAD-source = P4=0)
  merged$p4[is.na(merged$p4)] <- 0L
  # But exclude languages with no reflexive data at all
  merged <- merged[!is.na(merged$gb305), ]

  merged
}