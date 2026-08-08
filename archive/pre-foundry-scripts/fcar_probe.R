.libPaths(c("/data/R/library", .libPaths()))
library(fcaR, lib.loc="/data/R/library")

I <- matrix(c(
  1, 1, 0, 0,
  1, 1, 1, 0,
  1, 0, 0, 0
), nrow=3, byrow=TRUE)
rownames(I) <- c("GARD", "RNA-World", "Iron-Sulfur")
colnames(I) <- c("L1-obs", "L2-inference", "L3-eval", "L4-converge")

fc <- FormalContext$new(I)
cat("=== Formal context ===\n")
print(fc)

# List public methods
cat("\n=== FormalContext public methods ===\n")
for (m in sort(names(fc$public_methods))) cat("  ", m, "\n")

# Closure
cat("\n=== Closure of {L1-obs} ===\n")
S <- Set$new(attributes = colnames(I))
S$assign("L1-obs")
cat("Input set class:", class(S), "\n")
result <- fc$closure(S)
cat("Result class:", class(result), "\n")
cat("Result:\n")
print(result)

# Concepts
cat("\n=== Concepts ===\n")
fc$compute_concepts(verbose = FALSE)
concepts <- fc$get_concepts()
cat("Concept count:", length(concepts$get()), "\n")

# Print first few concepts
for (i in seq_along(concepts$get())) {
  c_obj <- concepts$get()[[i]]
  cat(sprintf("  Concept %d:", i))
  print(c_obj)
}

# Implications
cat("\n=== Implications ===\n")
fc$compute_implications(verbose = FALSE)
impls <- fc$get_implications()
cat("Implication count:", length(impls$get()), "\n")
print(impls)

# Incidence check
cat("\n=== Incidence check: GARD holds L1-obs ===\n")
print("GARD" %holds_in% "L1-obs" %% fc)

# Implication satisfaction
cat("\n=== Implication satisfaction ===\n")
S2 <- Set$new(attributes = colnames(I))
S2$assign("L1-obs")
cat("Does {L1-obs} respect implications?\n")
print(S2 %respects% impls)

# Set methods
cat("\n=== Set public methods ===\n")
for (m in sort(names(S$public_methods))) cat("  ", m, "\n")

# ConceptLattice methods
lat <- fc$get_concepts()
cat("\n=== ConceptLattice methods ===\n")
for (m in sort(names(lat$public_methods))) cat("  ", m, "\n")

# ImplicationSet methods
cat("\n=== ImplicationSet methods ===\n")
for (m in sort(names(impls$public_methods))) cat("  ", m, "\n")

# JSON round-trip
cat("\n=== JSON serialization ===\n")
fc_json <- fc$to_json()
cat("JSON length:", nchar(fc_json), "chars\n")
fc2 <- FormalContext$new()
fc2$from_json(fc_json)
cat("Round-trip equal:", identical(fc$I, fc2$I), "\n")
