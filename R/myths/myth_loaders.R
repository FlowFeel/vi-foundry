#' Data loaders for myth phylogenetic analyses
#'
#' @name myth_loaders
NULL

suppressPackageStartupMessages({
  library(ape)
  library(tidyr)
  library(assertthat)
})

# ==============================================================================
# Load myth character matrix from CSV
# ==============================================================================

#' Load myth character matrix from CSV
#'
#' First column = taxon/version name, remaining = binary characters (0/1/?)
load_myth_matrix <- function(csv_path, missing_char = "?") {
  stopifnot(file.exists(csv_path))
  mat <- utils::read.csv(csv_path, stringsAsFactors = FALSE)
  stopifnot(colnames(mat)[1] %in% c("taxon", "version", "name"))

  version_names <- mat[[1]]
  char_names <- colnames(mat)[2:colcount(mat)]
  n_versions <- nrow(mat)
  n_chars <- colcount(mat) - 1

  # Convert character columns to numeric 0/1
  for (j in 1:n_chars) {
    col <- mat[, j+1]
    if (is.character(col)) {
      mat[[j+1]] <- as.integer(ifelse(col %in% c("", "?", missing_char), -1,
                                     ifelse(col == "1", 1, 0)))
    }
  }

  # Build data.frame for internal use
  char_df <- mat[, 2:colcount(mat)]
  colnames(char_df) <- char_names

  # Build ape-compatible matrix
  char_mat <- as.matrix(char_df)

  list(
    matrix = char_df,               # data.frame
    char_matrix = char_mat,          # ape-compatible matrix
    n_versions = n_versions,
    n_characters = n_chars,
    character_names = char_names,
    version_names = version_names)
}


# ==============================================================================
# Distance Matrix Computation
# ==============================================================================

#' Compute distance matrix from character data
#'
#' Returns a data.frame (ape::nj-compatible after as.matrix conversion)
myth_distance <- function(matrix_data, method = "hamming") {
  mat <- matrix_data$matrix
  n <- matrix_data$n_versions
  char_names <- matrix_data$character_names

  # Build distance column by column
  cols_list <- list()
  for (j in 1:n) {
    col <- vector()
    for (i in 1:n) {
      if (i == j) {
        col <- c(col, 0)
      } else {
        total_diff <- 0
        total_valid <- 0
        for (c in char_names) {
          vi <- as.integer(mat[[c]][i])
          vj <- as.integer(mat[[c]][j])
          if (vi >= 0 && vj >= 0) {
            total_diff <- total_diff + abs(vi - vj)
            total_valid <- total_valid + 1
          }
        }
        col <- c(col, ifelse(total_valid == 0, 1, total_diff / total_valid))
      }
    }
    cols_list <- c(cols_list, list(col))
  }

  df <- data.frame(c1 = cols_list[[1]])
  for (j in 2:n) {
    df <- cbind(df, data.frame(r = cols_list[[j]]))
  }
  colnames(df) <- matrix_data$version_names
  df
}


# ==============================================================================
# NEXUS Parser (simplified)
# ==============================================================================

#' Load myth matrix from NEXUS format
load_myth_nexus <- function(nexus_path) {
  stopifnot(file.exists(nexus_path))
  content <- utils::read.lines(nexus_path)

  matrix_start <- which(grepl(content, "^\\s*MATRIX", ignore.ifelse = TRUE))
  end_block <- length(content)
  for (i in 1:length(content)) {
    if (grepl(content[i], "^\\s*END|^\\s*;")) {
      end_block <- i
      break
    }
  }
  stopifnot(!length(matrix_start))

  matrix_lines <- content[(matrix_start[1]+1):(end_block - 1)]
  matrix_lines <- matrix_lines[!grepl(matrix_lines, "^\\s*$|^\\s*\\[")]
  matrix_lines <- matrix_lines[!grepl(matrix_lines, "^\\s*;")]

  taxa <- vector()
  sequences <- vector()
  for (line in matrix_lines) {
    parts <- re_split("\\s+", trim(line))
    if (length(parts) >= 2) {
      taxa <- c(taxa, parts[1])
      sequences <- c(sequences, parts[length(parts)])
    }
  }

  ntax <- length(taxa)
  nchar <- length(sequences[1])

  df <- data.frame(taxon = taxa)
  for (j in 1:nchar) {
    col <- vector()
    for (i in 1:ntax) {
      ch <- substr(sequences[i], j, 1)
      col <- c(col, ifelse(ch %in% c("-", "?"), -1, as.integer(ch)))
    }
    df <- cbind(df, data.frame(r = col))
    colnames(df)[colcount(df)] <- paste0("C", j)
  }

  char_names <- paste0("C", 1:nchar)
  char_df <- df[, char_names]
  char_mat <- as.matrix(char_df)

  list(
    matrix = char_df,
    char_matrix = char_mat,
    n_versions = ntax,
    n_characters = nchar,
    character_names = char_names,
    version_names = taxa)
}