#!/usr/bin/env Rscript
# generate_viz.R — Generate simulacra visualization HTML for GitHub Pages

library(vi.foundry)
library(ggplot2)

# Read all marks
all_marks <- read_all_marks("results/simulacra")

if (length(all_marks) == 0) {
  message("No marks found — generating placeholder page")
  html <- '<!DOCTYPE html><html><head><title>VI Foundry Simulacra</title></head><body><h1>VI Foundry Simulacra</h1><p>No simulacra results yet. Run the simulacra tests first.</p></body></html>'
  writeLines(html, "docs/index.html")
  quit(status = 0)
}

plots_html <- ""
for (sim_id in names(all_marks)) {
  marks <- all_marks[[sim_id]]
  if (length(marks) == 0) next
  param_names <- names(marks[[1]]$true_params)
  if (is.null(param_names)) next

  for (pname in param_names) {
    p <- plot_true_vs_recovered(marks, pname, sim_id)
    tmp <- tempfile(fileext = ".png")
    ggplot2::ggsave(tmp, p, width = 8, height = 6, dpi = 150)
    plots_html <- paste0(plots_html,
      "<h3>", sim_id, " — ", pname, "</h3>",
      "<img src=\"data:image/png;base64,",
      base64enc::base64encode(tmp), "\" />"
    )
  }
}

html <- paste0(
  "<!DOCTYPE html><html><head><title>VI Foundry Simulacra</title>",
  "<style>",
  "body { font-family: system-ui, sans-serif; max-width: 1000px; margin: 0 auto; padding: 20px; }",
  "h1 { color: #2c3e50; } h3 { color: #34495e; margin-top: 30px; }",
  "img { max-width: 100%; border: 1px solid #eee; }",
  ".header { background: #2c3e50; color: white; padding: 20px; border-radius: 8px; margin-bottom: 20px; }",
  ".summary { background: #f8f9fa; padding: 15px; border-radius: 4px; margin: 10px 0; }",
  "</style></head><body>",
  "<div class=\"header\"><h1>VI Foundry — Simulacra Parameter Recovery</h1>",
  "<p>Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M UTC"), "</p></div>",
  "<div class=\"summary\"><p>Each plot shows true parameters (x-axis) vs recovered parameters (y-axis).",
  " Points on the diagonal = successful recovery. Green = within CI, Red = outside CI.</p></div>",
  plots_html,
  "</body></html>"
)

dir.create("docs", showWarnings = FALSE, recursive = TRUE)
writeLines(html, "docs/index.html")
message("Generated docs/index.html")
