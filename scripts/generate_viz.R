#!/usr/bin/env Rscript
# generate_viz.R — Generate simulacra visualization HTML for GitHub Pages
#
# Thin wrapper retained for backwards compatibility with CI.
# All rendering logic lives in scripts/render_pages.R.
#
# The CI simulacra job invokes this script (Rscript scripts/generate_viz.R)
# after the simulacrum tests produce their mark logs. It delegates to the
# comprehensive renderer, which produces the fully self-contained
# docs/index.html page.

source("scripts/render_pages.R")