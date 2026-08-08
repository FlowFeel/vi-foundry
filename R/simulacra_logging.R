#' Simulacrum logging — discrete marks for visualization
#'
#' Each simulacrum run emits structured marks capturing:
#' - True parameters (vertices in parameter space)
#' - Recovered parameters (where the pipeline landed)
#' - Whether recovery succeeded (within CI)
#' - Null control result (specificity check)
#' - Seed, timestamp, simulation index
#'
#' Marks are stored as YAML (human-readable) and can be projected
#' into 2D visualizations via simulacra_viz.
#'
#' @section Theoretical Context:
#'
#' The marks form a trajectory through parameter space. In a successful
#' simulacrum, the recovered parameters cluster tightly around the true
#' parameters (signal), while the null control parameters scatter widely
#' (noise). Visualizing this separation is the clearest way to communicate
#' that the methods work.
#'
#' @dft A1 (pure logging — no side effects beyond file write), A6 (check-result)
#'
#' @name simulacra_logging
NULL

#' Initialize a simulacrum mark log
#'
#' Creates an empty mark log file (YAML format) for a simulacrum run.
#'
#' @param simulacrum_id Character. Name of the simulacrum (e.g., "param_recovery").
#' @param output_dir Character. Directory for mark logs. Default "results/simulacra".
#'
#' @return Character. Path to the mark log file.
#' @export
init_mark_log <- function(simulacrum_id, output_dir = "results/simulacra") {
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }
  log_path <- file.path(output_dir, paste0(simulacrum_id, "_marks.yml"))
  # Write empty YAML header
  cat(sprintf("# Simulacrum marks: %s\n# Generated: %s\nmarks: []\n",
              simulacrum_id,
              format(Sys.time(), "%Y-%m-%d %H:%M:%S UTC", tz = "UTC")),
      file = log_path)
  log_path
}

#' Emit a discrete mark to the log
#'
#' Appends a mark to the simulacrum mark log. Each mark captures:
#' the true parameters, recovered parameters, within_ci flag, null control
#' result, seed, simulation index, and timestamp.
#'
#' @param log_path Character. Path to the mark log file.
#' @param sim_index Integer. Simulation index (1-based).
#' @param true_params Named numeric vector. True parameters.
#' @param recovered_params Named numeric vector. Recovered parameters.
#' @param within_ci Logical. Were recovered params within CI of true?
#' @param null_result Numeric or NA. Null control result.
#' @param seed Integer. Random seed used.
#' @param extra Named list. Additional mark data (optional).
#'
#' @return Invisible TRUE.
#' @export
mark <- function(log_path, sim_index, true_params, recovered_params,
                 within_ci, null_result = NA, seed = 42L, extra = NULL) {
  mark_entry <- list(
    sim_index = sim_index,
    timestamp = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
    seed = seed,
    true_params = as.list(true_params),
    recovered_params = as.list(recovered_params),
    within_ci = within_ci,
    null_result = null_result,
    extra = extra
  )

  # Append as YAML block
  yaml_str <- yaml::as.yaml(list(mark_entry))
  # Remove the leading "- " that as.yaml adds for lists, reformat
  yaml_str <- sub("^- ", "  - ", yaml_str)

  cat(yaml_str, "\n", file = log_path, append = TRUE)
  invisible(TRUE)
}

#' Read all marks from a log file
#'
#' @param log_path Character. Path to mark log.
#'
#' @return List of mark entries.
#' @export
read_marks <- function(log_path) {
  if (!file.exists(log_path)) {
    warning("Mark log not found: ", log_path)
    return(list())
  }
  marks_yaml <- yaml::read_yaml(log_path)
  marks_yaml$marks
}

#' Read all marks across all simulacra
#'
#' Reads every *_marks.yml file in the output directory.
#'
#' @param output_dir Character. Default "results/simulacra".
#'
#' @return List keyed by simulacrum ID, each containing mark entries.
#' @export
read_all_marks <- function(output_dir = "results/simulacra") {
  files <- list.files(output_dir, pattern = "_marks\\.yml$", full.names = TRUE)
  result <- list()
  for (f in files) {
    sim_id <- sub("_marks\\.yml$", "", basename(f))
    result[[sim_id]] <- read_marks(f)
  }
  result
}
