#!/usr/bin/env Rscript
# run_carling_cathcart_replication.R — Foundry replication of Carling & Cathcart (2021)
# "Evolutionary dynamics of Indo-European alignment patterns"
# Usage: Rscript scripts/run_carling_cathcart_replication.R [--chars 1-9] [--trees 1-100] [--iter 200]
library(rstan)
library(phytools)
rstan_options(auto_write = TRUE)
options(mc.cores = parallel::detectCores())

# Parse args
args <- commandArgs(trailingOnly = TRUE)
target_chars <- 1:9
n_trees <- 10
n_iter <- 200
for (i in seq_along(args)) {
  if (args[i] == "--chars" && i < length(args)) target_chars <- eval(parse(text = args[i+1]))
  if (args[i] == "--trees" && i < length(args)) n_trees <- as.integer(args[i+1])
  if (args[i] == "--iter" && i < length(args)) n_iter <- as.integer(args[i+1])
}

repo_dir <- "evo-dyn-ie-align"
if (!dir.exists(repo_dir)) repo_dir <- "/tmp/evo-dyn-ie-align"
cat("=== Carling & Cathcart (2021) — Foundry Replication ===\n\n")

diacl.data <- read.csv(file.path(repo_dir, "diacl_qualitative_wide.tsv"), sep="\t", row.names=1)
diacl.data <- diacl.data[,1:9]
IE.trees <- read.newick(file.path(repo_dir, "IE_final.newick"))
cat("Data:", nrow(diacl.data), "langs x", 9, "chars\n")
cat("Trees:", length(IE.trees), "available\n\n")

model_code <- "
data { int<lower=1> N, T, B, F;
  int<lower=1> child[B]; int<lower=1> parent[B]; real<lower=0> brlen[B];
  int<lower=0,upper=1> tiplik[T,F]; }
parameters { real<lower=0> R[F*(F-1)]; }
transformed parameters { matrix[F,F] Q;
  { int k = 1; for (i in 1:F) for (j in 1:F) if (i != j) { Q[i,j] = R[k]; k++; }
    for (i in 1:F) { real z = 0; for (j in 1:F) if (i != j) z -= Q[i,j]; Q[i,i] = z; } } }
model { matrix[N,F] lambda; matrix[F,F] pi_matrix; vector[F] pi;
  for (i in 1:F*(F-1)) R[i] ~ gamma(1,1);
  for (t in 1:T) for (f in 1:F) lambda[t,f] = log(tiplik[t,f]);
  for (n in (T+1):N) for (f in 1:F) lambda[n,f] = 0;
  for (b in 1:B) { matrix[F,F] P = matrix_exp(brlen[b]*Q);
    for (f in 1:F) lambda[parent[b],f] += log(dot_product(P[f], exp(lambda[child[b]]))); }
  pi_matrix = matrix_exp(1000*Q);
  for (f in 1:F) pi[f] = pi_matrix[1,f];
  target += log(dot_product(pi, exp(lambda[parent[B]]))); }
"

for (j in target_chars) {
  cat(sprintf("\n--- Character %d/9 ---\n", j))
  tree <- IE.trees[[1]]
  sub <- diacl.data[tree$tip.label,]
  for (cj in 1:9) sub[,cj] <- as.character(sub[,cj])
  likelihood <- to.matrix(sub[,j], seq = unique(sub[,j]))
  rownames(likelihood) <- rownames(sub)
  likelihood[rowSums(likelihood) == 0,] <- likelihood[rowSums(likelihood) == 0,] + 1
  tree <- reorder.phylo(tree, "pruningwise")
  curr.states <- likelihood[tree$tip.label,]
  parent <- tree$edge[,1]; child <- tree$edge[,2]; b.lens <- tree$edge.length
  N <- length(unique(c(parent, child)))
  T <- length(child[which(!child %in% parent)])
  cat(sprintf("  N=%d T=%d B=%d F=%d iter=%d\n", N, T, length(parent), ncol(curr.states), n_iter))
  t0 <- Sys.time()
  fit <- stan(model_code = model_code,
    data = list(N = N, T = T, B = length(parent), brlen = b.lens / 1000,
      child = child, parent = parent, tiplik = curr.states, F = ncol(curr.states)),
    iter = n_iter, chains = 2, refresh = n_iter > 1000 ? floor(n_iter / 4) : 0)
  s <- summary(fit)$summary
  cat(sprintf("  Time: %.0f s  Max Rhat: %.3f  States: %d\n",
    as.numeric(difftime(Sys.time(), t0, units = "secs")),
    max(s[, "Rhat"], na.rm = TRUE), ncol(curr.states)))
  # Stationary probabilities
  pi <- s[1:ncol(curr.states), "mean"]
  names(pi) <- unique(sub[,j])
  cat("  Stationary probabilities:\n")
  for (k in seq_along(pi)) cat(sprintf("    %s: %.4f\n", names(pi)[k], pi[k]))
}
cat("\n=== Foundry Replication Complete ===\n")
