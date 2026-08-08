#' Data loaders for VI foundry datasets
#'
#' Each loader reads from the bundled data/ directory, runs the appropriate
#' contract validator, and returns a structured result object (A6: proof
#' object with data + metadata).
#'
#' All loaders follow DFT A1 (pure IO separation): I/O is isolated to
#' these thin wrapper functions. The analysis logic functions they feed
#' are pure — they never touch the filesystem.
#'
#' @section DFT Axioms:
#' - A1 (pure-io-separation): I/O isolated to loaders
#' - A5 (real-fakes): FakeDataLoader returns real dataframes from fixtures
#' - A6 (check-result): loaders return list with data + provenance + validation
#'
#' @name data_loaders
NULL

#' Helper: get data directory path
#'
#' Returns the path to the bundled data directory. Resolves correctly
#' both when running as an installed package and when running from source.
#'
#' @return Character. Path to data/ directory.
#' @keywords internal
get_data_dir <- function() {
  path <- system.file("data", package = "vi.foundry")
  if (path != "" && dir.exists(path)) {
    return(path)
  }
  # Fallback: project-relative path
  "data"
}

#' Helper: create result object (A6: check-result)
#'
#' Wraps data with metadata into a structured proof object.
#'
#' @param data The loaded data.
#' @param name Name of the dataset.
#' @param source Description of data source.
#' @return List with data, metadata (name, source, n, loaded_at).
#' @keywords internal
make_result <- function(data, name, source) {
  list(
    data = data,
    metadata = list(
      name = name,
      source = source,
      n = nrow(data),
      loaded_at = format(Sys.time(), "%Y-%m-%d %H:%M:%S UTC", tz = "UTC")
    )
  )
}

#' Load Orobanchaceae plastome data
#'
#' Loads species-level plastome sizes and parasitism scores for
#' Orobanchaceae, along with the phylogenetic tree.
#'
#' @return List with data (plastome data frame), tree (Newick string),
#'   and metadata.
#'
#' @section Theoretical Context:
#'
#' Tests VI Prediction D5: plastome size correlates with parasitism level.
#' Competitor: relaxed selection (Lahti 2009) predicts the same gradient.
#' This data feeds T1 (PGLS) and T6 (gene-loss ordering).
#'
#' @dft
#' - A1 (pure-io-separation): I/O in loader, logic in analysis functions
#' - A6 (check-result): returns proof object with data + provenance
#'
#' @export
#' @examples
#' \dontrun{
#' result <- load_orobanchaceae()
#' head(result$data)
#' }
load_orobanchaceae <- function() {
  data_dir <- get_data_dir()
  data_path <- file.path(data_dir, "species_plastome_data.tsv")
  tree_path <- file.path(data_dir, "orobanchaceae_tree.nwk")

  data <- utils::read.table(data_path, header = TRUE, sep = "\t",
                             stringsAsFactors = FALSE)
  names(data) <- c("species", "genus", "accession", "plastome_size_bp",
                   "parasitism_category", "parasitism_score")
  data$plastome_size_kb <- data$plastome_size_bp / 1000

  tree <- readLines(tree_path, n = 1L)

  validate_plastome_data(data)
  validate_parasitism_scores(data$parasitism_score)
  validate_phylo_tree(tree)

  make_result(data, "orobanchaceae",
              "NCBI GenBank plastome sizes + parasitism scores")
}

#' Load cross-family plastome data
#'
#' Loads plastome sizes across multiple independent parasitic plant
#' families for cross-family replication.
#'
#' @return List with data (data frame) and metadata.
#'
#' @section Theoretical Context:
#'
#' Tests VI Prediction D5: gene-loss gradient replicates across
#' independently evolved parasitic lineages. Competitor: stochastic gene
#' loss / relaxed selection — both predict the same pattern. Does NOT
#' distinguish VI from competitors.
#'
#' @dft
#' - A1, A6
#'
#' @export
load_cross_family_plastomes <- function() {
  data_dir <- get_data_dir()
  data_path <- file.path(data_dir, "cross_family_plastome_data.tsv")

  data <- utils::read.table(data_path, header = TRUE, sep = "\t",
                             stringsAsFactors = FALSE)
  names(data) <- c("species", "family", "accession", "plastome_bp",
                    "parasitism_level", "parasitism_score",
                    "outgroup_available")
  data$plastome_size_kb <- data$plastome_bp / 1000

  validate_plastome_data(data)
  validate_parasitism_scores(data$parasitism_score)

  make_result(data, "cross_family",
              "NCBI GenBank, 12+ parasitic plant families")
}

#' Load endosymbiont genome data
#'
#' Loads genome sizes and host dependency scores for bacterial
#' endosymbionts (Buchnera, Wigglesworthia, Carsonella, Blochmannia).
#'
#' @return List with data (data frame) and metadata.
#'
#' @section Theoretical Context:
#'
#' Tests VI Prediction: biphasic genome reduction (fast Phase 1, slow
#' Phase 2). Competitors: constant rate (Lynch 2007), accelerating
#' (Muller's ratchet). McCutcheon's metabolic complementarity predicts
#' the same correlation — does NOT distinguish VI from McCutcheon.
#'
#' @dft
#' - A1, A6
#'
#' @export
load_endosymbionts <- function() {
  data_dir <- get_data_dir()
  data_path <- file.path(data_dir, "endosymbiont_genome_data.tsv")

  data <- utils::read.table(data_path, header = TRUE, sep = "\t",
                             stringsAsFactors = FALSE)

  validate_endosymbiont_data(data)

  make_result(data, "endosymbionts",
              "GenBank: Buchnera, Wigglesworthia, Carsonella, Blochmannia")
}

#' Load Bobay-Ochman niche data
#'
#' Loads the Bobay & Ochman (2017) Table S1 data with Ne, genome size,
#' and lifestyle classifications for 140+ species.
#'
#' @return List with data (data frame) and metadata.
#'
#' @section Theoretical Context:
#'
#' Tests VI Prediction D3: niche breadth predicts gene loss better than
#' Ne alone. Competitor: drift (Lynch 2007) predicts Ne is primary.
#' DOES distinguish VI from drift.
#'
#' @dft
#' - A1, A6
#'
#' @export
load_bobay_ochman <- function() {
  data_dir <- get_data_dir()
  data_path <- file.path(data_dir, "bobay_ochman_table_s1.xlsx")

  data <- readxl::read_xlsx(data_path, skip = 1)
  data <- as.data.frame(data)
  names(data) <- make.names(names(data))

  validate_niche_data(data)

  make_result(data, "bobay_ochman",
              "Bobay & Ochman (2017) Table S1, 140+ species")
}

#' Load Dewar pan-genome data
#'
#' Loads pangenome fluidity and lifestyle data from Dewar et al. (2024).
#'
#' @return List with data (data frame) and metadata.
#'
#' @section Theoretical Context:
#'
#' Tests VI Prediction: pan-genome openness tracks lifestyle (commensal
#' vs free-living). Competitor: Ne-only model. DOES distinguish VI.
#'
#' @dft
#' - A1, A6
#'
#' @export
load_dewar_pangenome <- function() {
  data_dir <- get_data_dir()
  data_path <- file.path(data_dir, "dewar_pangenome_lifestyles.csv")

  data <- utils::read.csv(data_path, stringsAsFactors = FALSE)

  validate_pangenome_data(data)

  make_result(data, "dewar_pangenome",
              "Dewar et al. (2024) supplementary, pan-genome lifestyles")
}

#' Load island bird morphology data
#'
#' Loads morphological change rankings for island bird flight-loss traits.
#'
#' @return List with data (data frame) and metadata.
#'
#' @section Theoretical Context:
#'
#' Tests VI L3 Prediction: plant-derived integration-depth parameters
#' predict bird morphological change ordering across kingdoms.
#' Competitor: substrates are independent — no parameter transfer.
#' DOES distinguish VI. This is the strongest test in the monograph.
#'
#' @dft
#' - A1, A6
#'
#' @export
load_island_birds <- function() {
  data_dir <- get_data_dir()
  data_path <- file.path(data_dir, "island_bird_morphology.csv")

  if (!file.exists(data_path)) {
    stop("island_bird_morphology.csv not found. Run data preparation first.",
         call. = FALSE)
  }

  data <- utils::read.csv(data_path, stringsAsFactors = FALSE)

  validate_bird_morphology(data)

  make_result(data, "island_birds",
              "Island bird flight-loss morphological rankings")
}
