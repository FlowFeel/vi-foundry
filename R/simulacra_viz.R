#' Simulacrum visualizations — lower-dimensional projections from marks
#'
#' Produces ggplot2 visualizations from simulacrum mark logs. Each mark
#' captures a vertex in parameter space (true params) and where the
#' pipeline landed (recovered params). These are projected into 2D
#' for human-readable communication.
#'
#' @section Theoretical Context:
#'
#' The visualizations serve as the clearest communication of simulacrum
#' results: recovered parameters cluster tightly around true parameters
#' (signal), while null control parameters scatter widely (noise). The
#' visual separation between these clusters IS the proof that the methods
#' can distinguish signal from noise.
#'
#' @dft A1 (pure — data in, ggplot2 object out), A6 (returns structured plot)
#'
#' @name simulacra_viz
NULL

#' Plot true vs recovered parameters (2D scatter)
#'
#' Projects the parameter space onto 2D: true parameter value (x-axis)
#' vs recovered parameter value (y-axis). Points should cluster along
#' the y=x diagonal for successful recovery. Null control points
#' should scatter randomly.
#'
#' @param marks List. Mark entries from read_marks().
#' @param param_name Character. Name of the parameter to plot.
#' @param simulacrum_id Character. Simulacrum name for title.
#'
#' @return ggplot2 object.
#'
#' @section Theoretical Context:
#'
#' Points on the y=x diagonal = successful parameter recovery (the pipeline
#' finds the known signal). Points scattered off the diagonal = failed
#' recovery (the pipeline cannot find the signal). Null control points
#' SHOULD be scattered — this proves specificity.
#'
#' @dft A1, A6
#'
#' @export
plot_true_vs_recovered <- function(marks, param_name, simulacrum_id = "") {
  # Extract true and recovered values for the named parameter
  true_vals <- sapply(marks, function(m) {
    m$true_params[[param_name]]
  })
  recovered_vals <- sapply(marks, function(m) {
    m$recovered_params[[param_name]]
  })
  within_ci <- sapply(marks, function(m) m$within_ci)

  df <- data.frame(
    true = true_vals,
    recovered = recovered_vals,
    within_ci = within_ci,
    sim_index = seq_along(true_vals)
  )

  p <- ggplot2::ggplot(df, ggplot2::aes(
    x = .data$true, y = .data$recovered,
    color = .data$within_ci
  )) +
    ggplot2::geom_abline(
      slope = 1, intercept = 0, linetype = "dashed",
      color = "grey50"
    ) +
    ggplot2::geom_point(size = 3, alpha = 0.7) +
    ggplot2::scale_color_manual(
      values = c("TRUE" = "#2ecc71", "FALSE" = "#e74c3c"),
      labels = c("TRUE" = "Within CI", "FALSE" = "Outside CI"),
      name = "Recovery"
    ) +
    ggplot2::labs(
      title = paste0("Simulacrum: ", simulacrum_id),
      subtitle = paste0("Parameter: ", param_name),
      x = paste0("True ", param_name),
      y = paste0("Recovered ", param_name)
    ) +
    ggplot2::theme_minimal(base_size = 12)

  p
}

#' Plot recovery trajectory over simulations
#'
#' Shows how recovered parameters converge (or fail to converge) across
#' multiple simulations. X-axis = simulation index, y-axis = parameter value.
#' True value shown as horizontal line.
#'
#' @param marks List. Mark entries from read_marks().
#' @param param_name Character. Parameter to plot.
#' @param simulacrum_id Character. For title.
#'
#' @return ggplot2 object.
#' @export
plot_recovery_trajectory <- function(marks, param_name, simulacrum_id = "") {
  true_vals <- sapply(marks, function(m) m$true_params[[param_name]])
  recovered_vals <- sapply(marks, function(m) m$recovered_params[[param_name]])
  null_vals <- sapply(marks, function(m) m$null_result)
  sim_idx <- seq_along(true_vals)

  df <- data.frame(
    sim_index = sim_idx,
    recovered = recovered_vals,
    true_value = true_vals[1], # Constant — true params don't change
    null = null_vals
  )

  p <- ggplot2::ggplot(df, ggplot2::aes(x = .data$sim_index)) +
    ggplot2::geom_hline(ggplot2::aes(yintercept = .data$true_value),
      color = "#2ecc71", linewidth = 1, linetype = "dashed"
    ) +
    ggplot2::geom_line(ggplot2::aes(y = .data$recovered), color = "#3498db", linewidth = 0.8) +
    ggplot2::geom_point(ggplot2::aes(y = .data$recovered), color = "#3498db", size = 2) +
    ggplot2::geom_point(ggplot2::aes(y = .data$null),
      color = "#e74c3c",
      size = 2, alpha = 0.5
    ) +
    ggplot2::labs(
      title = paste0("Recovery trajectory: ", simulacrum_id),
      subtitle = paste0("Parameter: ", param_name),
      x = "Simulation index",
      y = paste0(param_name, " value"),
      caption = "Green dashed = true | Blue = recovered | Red = null control"
    ) +
    ggplot2::theme_minimal(base_size = 12)

  p
}

#' Plot parameter space projection (2D scatter of two parameters)
#'
#' Projects multi-dimensional parameter space onto 2D by plotting two
#' chosen parameters against each other. Points colored by recovery
#' success. Null control points shown as open circles.
#'
#' @param marks List. Mark entries from read_marks().
#' @param param_x Character. Parameter for x-axis.
#' @param param_y Character. Parameter for y-axis.
#' @param simulacrum_id Character. For title.
#'
#' @return ggplot2 object.
#' @export
plot_param_space_projection <- function(marks, param_x, param_y,
                                        simulacrum_id = "") {
  x_true <- sapply(marks, function(m) m$true_params[[param_x]])
  y_true <- sapply(marks, function(m) m$true_params[[param_y]])
  x_rec <- sapply(marks, function(m) m$recovered_params[[param_x]])
  y_rec <- sapply(marks, function(m) m$recovered_params[[param_y]])
  within_ci <- sapply(marks, function(m) m$within_ci)

  df <- data.frame(
    x_true = x_true, y_true = y_true,
    x_recovered = x_rec, y_recovered = y_rec,
    within_ci = within_ci,
    sim_index = seq_along(x_true)
  )

  p <- ggplot2::ggplot(df) +
    ggplot2::geom_point(ggplot2::aes(x = .data$x_true, y = .data$y_true),
      color = "#2ecc71", size = 4, shape = 18, alpha = 0.6
    ) +
    ggplot2::geom_point(
      ggplot2::aes(
        x = .data$x_recovered, y = .data$y_recovered,
        color = .data$within_ci
      ),
      size = 3, alpha = 0.8
    ) +
    ggplot2::geom_segment(
      ggplot2::aes(
        x = .data$x_true, y = .data$y_true,
        xend = .data$x_recovered,
        yend = .data$y_recovered,
        color = .data$within_ci
      ),
      alpha = 0.3, linewidth = 0.5
    ) +
    ggplot2::scale_color_manual(
      values = c("TRUE" = "#3498db", "FALSE" = "#e74c3c"),
      labels = c("TRUE" = "Recovered", "FALSE" = "Failed"),
      name = "Recovery"
    ) +
    ggplot2::labs(
      title = paste0("Parameter space: ", simulacrum_id),
      subtitle = paste0(param_x, " vs ", param_y),
      x = param_x,
      y = param_y,
      caption = "Green diamonds = true | Colored dots = recovered | Lines = displacement"
    ) +
    ggplot2::theme_minimal(base_size = 12)

  p
}

#' Plot recovery rate over simulations (rolling)
#'
#' Shows the proportion of simulations that recovered parameters within CI,
#' computed as a rolling window. This communicates the reliability of the
#' pipeline — a flat line at 95% means the pipeline reliably recovers signal.
#'
#' @param marks List. Mark entries from read_marks().
#' @param window Integer. Rolling window size. Default 10.
#' @param simulacrum_id Character. For title.
#'
#' @return ggplot2 object.
#' @export
plot_recovery_rate <- function(marks, window = 10L, simulacrum_id = "") {
  within_ci <- sapply(marks, function(m) m$within_ci)
  n <- length(within_ci)

  if (n < window) {
    window <- n
  }

  rolling_rate <- sapply(seq_len(n), function(i) {
    start <- max(1L, i - window + 1L)
    mean(within_ci[start:i])
  })

  df <- data.frame(
    sim_index = seq_len(n),
    recovery_rate = rolling_rate
  )

  p <- ggplot2::ggplot(df, ggplot2::aes(
    x = .data$sim_index,
    y = .data$recovery_rate
  )) +
    ggplot2::geom_hline(
      yintercept = 0.95, color = "#2ecc71",
      linetype = "dashed", linewidth = 0.8
    ) +
    ggplot2::geom_line(color = "#3498db", linewidth = 1) +
    ggplot2::geom_point(color = "#3498db", size = 2) +
    ggplot2::ylim(0, 1) +
    ggplot2::labs(
      title = paste0("Recovery rate: ", simulacrum_id),
      subtitle = sprintf("Rolling window: %d simulations", window),
      x = "Simulation index",
      y = "Proportion recovered within CI",
      caption = "Green dashed = 95% target"
    ) +
    ggplot2::theme_minimal(base_size = 12)

  p
}

#' Render all simulacrum visualizations to a report
#'
#' Produces a multi-page PDF with all projections for all simulacra.
#'
#' @param output_dir Character. Where mark logs live. Default "results/simulacra".
#' @param pdf_path Character. Output PDF path.
#'
#' @return Invisible TRUE. Side effect: writes PDF.
#' @export
render_simulacra_report <- function(output_dir = "results/simulacra",
                                    pdf_path = "results/simulacra_report.pdf") {
  all_marks <- read_all_marks(output_dir)

  if (length(all_marks) == 0) {
    warning("No mark logs found in ", output_dir)
    return(invisible(FALSE))
  }

  grDevices::pdf(pdf_path, width = 10, height = 8)

  for (sim_id in names(all_marks)) {
    marks <- all_marks[[sim_id]]
    if (length(marks) == 0) next

    # Get parameter names from first mark
    param_names <- names(marks[[1]]$true_params)
    if (is.null(param_names)) next

    # Plot true vs recovered for each parameter
    for (pname in param_names) {
      p <- plot_true_vs_recovered(marks, pname, sim_id)
      print(p)
    }

    # Plot recovery trajectory for first parameter
    p <- plot_recovery_trajectory(marks, param_names[1], sim_id)
    print(p)

    # Plot recovery rate
    p <- plot_recovery_rate(marks, simulacrum_id = sim_id)
    print(p)

    # If 2+ params, plot param space projections
    if (length(param_names) >= 2) {
      p <- plot_param_space_projection(
        marks, param_names[1],
        param_names[2], sim_id
      )
      print(p)
    }
  }

  grDevices::dev.off()
  invisible(TRUE)
}
