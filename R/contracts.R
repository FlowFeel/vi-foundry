#' Contract validators for VI foundry data
#'
#' These functions validate inputs at function entry and outputs at exit,
#' enforcing the MPI Handoff Blueprint's pure-function contract discipline.
#'
#' @section DFT Axioms:
#' - A1 (pure-io-separation): validators are pure — no I/O, no side effects
#' - A6 (check-result): validators return structured validation results
#'
#' @name contracts
NULL
