# helper-simulacra.R — make simulacrum generators available to tests
#
# The synthetic-data generators live in inst/simulacra/ (outside R/), so
# roxygen2 does not pick up their @export tags and they are not in NAMESPACE.
# Tests source them directly to get real, in-process generator functions
# (DFT A5: real fakes, not mocks). Sourcing defines the functions in the
# global environment of the test process, where tests can call them.

.simulacra_dir <- function() {
  system.file("simulacra", package = "vi.foundry")
}

source_simulacrum <- function(file) {
  path <- file.path(.simulacra_dir(), file)
  if (!file.exists(path)) {
    stop("simulacrum generator not found: ", file, call. = FALSE)
  }
  source(path, local = FALSE)
}

source_simulacrum("generate_synthetic_population.R")
source_simulacrum("generate_biphasic_genome.R")
source_simulacrum("generate_cross_kingdom.R")
source_simulacrum("generate_cusp_system.R")
source_simulacrum("generate_autocatalytic.R")
