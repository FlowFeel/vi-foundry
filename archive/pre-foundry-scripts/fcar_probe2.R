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

# Closure
cat("\n=== Closure of {L1-obs} ===\n")
S <- Set$new(attributes = colnames(I))
S$assign("L1-obs")
result <- fc$closure(S)
cat("Closure result:\n")
print(result)

# Try the standard NextClosure algorithm
cat("\n=== Compute concepts (using standard algorithm) ===\n")
fc$compute_concepts(verbose = FALSE)
concepts <- fc$get_concepts()
cat("Class:", class(concepts), "\n")
cat("Concept count:", length(concepts$get()), "\n")

# Try printing concepts
cat("\n=== Print concepts ===\n")
print(concepts)

# Implications  
cat("\n=== Compute implications ===\n")
fc$compute_implications(verbose = FALSE)
impls <- fc$get_implications()
cat("Implication count:", length(impls$get()), "\n")
print(impls)

# Incidence
cat("\n=== Incidence: GARD holds L1-obs ===\n")
result_inc <- "GARD" %holds_in% "L1-obs" %% fc
cat("Result:", result_inc, "\n")

# JSON
cat("\n=== JSON round-trip ===\n")
fc_json <- fc$to_json()
cat("JSON length:", nchar(fc_json), "chars\n")

# Check what we can do with the Set class
cat("\n=== Set operations ===\n")
S1 <- Set$new(attributes = colnames(I))
S1$assign("L1-obs")
S2 <- Set$new(attributes = colnames(I))
S2$assign("L2-inference")
cat("S1:"); print(S1)
cat("S2:"); print(S2)
cat("Union:"); print(S1 %|% S2)
cat("Intersection:"); print(S1 %&% S2)
cat("Difference:"); print(S1 %-% S2)

# Check implication satisfaction
cat("\n=== Implication satisfaction ===\n")
cat("Does {L1-obs} respect all implications?\n")
print(S1 %respects% impls)
