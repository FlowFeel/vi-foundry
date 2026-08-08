#' Data loaders for VI foundry datasets
#'
#' Each loader reads from the bundled data/ directory, runs the appropriate
#' contract validator, and returns a structured result object (A6: proof
#' object with data + metadata).
#'
#' @section DFT Axioms:
#' - A1 (pure-io-separation): I/O isolated to loaders, logic functions are pure
#' - A5 (real-fakes): FakeDataLoader returns real dataframes from in-memory fixtures
#' - A6 (check-result): loaders return list with data + provenance + validation status
#'
#' @name data_loaders
NULL
