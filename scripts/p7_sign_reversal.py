#!/usr/bin/env python3
"""
P7 Sign Reversal Analysis Script
=================================
Test P7: Do lineages with cumulative culture show positive diversity-dependent speciation?

This script outlines the formal analysis pipeline for testing
positive diversity-dependent speciation in cultural bird lineages.

Requirements:
- R with DDD package (Etienne & Haegeman 2012)
- birdtree.org phylogenies (Jetz et al. 2012)
- ape, phytools, geiger R packages

Usage:
    python p7_sign_reversal_pipeline.py --treedir /path/to/birdtrees

Status: SCRIPT OUTLINE — not yet executable

Note: Results in results/p1-p8-testing/p7-retest-results.md were
gathered through literature analysis of published datasets
(Garcia-Porta et al. 2022, van Holstein & Foley 2024, Rabosky datasets).
This script outlines the formal BAMM/DDD analysis pipeline that would
be needed for a complete quantitative test with original phylogenetic data.
"""

import argparse
import logging
import os
import subprocess
import sys
from pathlib import Path

logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")
logger = logging.getLogger(__name__)

# Cultural lineages (families with documented cumulative culture)
CULTURAL_LINEAGES = {
    "Corvidae": "Corvidae",          # crows, ravens, jays
    "Psittacidae": "Psittacidae",    # true parrots
    "Ptilonorhynchidae": "Ptilonorhynchidae",  # bowerbirds
    "Trochilidae": "Trochilidae",    # hummingbirds (vocal learning)
}

# Non-cultural comparison lineages (no cumulative culture)
NON_CULTURAL_LINEAGES = {
    "Galliformes": "Galliformes",    # game birds
    "Anseriformes": "Anseriformes",  # waterfowl
    "Tinamiformes": "Tinamiformes",  # tinamous
    "Struthioniformes": "Struthioniformes",  # ratites
}

R_SCRIPT = """
library(DDD)
library(ape)
library(phytools)

# Load tree
tree <- read.tree("%s")
cultural_clades <- c(%s)
non_cultural_clades <- c(%s)

# Helper function to fit DD models
fit_dd_models <- function(tree, clade_species) {
    # Prune tree to clade
    clade_tree <- keep.tip(tree, intersect(tree$tip.label, clade_species))
    if (length(clade_tree$tip.label) < 10) {
        return(list(n_species = length(clade_tree$tip.label), 
                    error = "Too few species"))
    }
    
    # Fit models
    # 1. Constant rate (bd)
    # 2. Negative DD (ddl — diversity-dependent linear)
    # 3. Positive DD (ddl with positive lambda0)
    
    # Note: DDD's dd_ML uses r = lambda0 - mu0 (net diversification)
    # and K = carrying capacity. Positive DD would be K < 0.
    
    suppressWarnings({
        # Constant rate
        cr <- bd_ML(tr = clade_tree)
        
        # Negative diversity-dependent (K > 0 = carrying capacity)
        ndd <- dd_ML(tr = clade_tree, ddmodel = 1)  # linear DD
        
        # Positive diversity-dependent (try with different starting values)
        # ddmodel = 1 allows positive OR negative DD depending on K sign
        # K > 0 → negative DD, K < 0 → positive DD
        pdd <- try(dd_ML(tr = clade_tree, ddmodel = 1, 
                         initparsopt = c(0.1, 0.01, 50)), silent = TRUE)
    })
    
    return(list(
        n_species = length(clade_tree$tip.label),
        cr_loglik = cr$loglik,
        cr_lambda0 = cr$lambda0,
        cr_mu0 = cr$mu0,
        ndd_loglik = ndd$loglik,
        ndd_lambda0 = ndd$lambda0,
        ndd_mu0 = ndd$mu0,
        ndd_K = ndd$K,
        pdd_loglik = ifelse(is(pdd, "try-error"), NA, pdd$loglik),
        pdd_lambda0 = ifelse(is(pdd, "try-error"), NA, pdd$lambda0),
        pdd_mu0 = ifelse(is(pdd, "try-error"), NA, pdd$mu0),
        pdd_K = ifelse(is(pdd, "try-error"), NA, pdd$K)
    ))
}

# Run analysis
results <- list()
for (clade_name in names(cultural_clades)) {
    cat(sprintf("\\n=== Cultural clade: %s ===\\n", clade_name))
    results[[clade_name]] <- fit_dd_models(tree, cultural_clades[[clade_name]])
}

for (clade_name in names(non_cultural_clades)) {
    cat(sprintf("\\n=== Non-cultural clade: %s ===\\n", clade_name))
    results[[clade_name]] <- fit_dd_models(tree, non_cultural_clades[[clade_name]])
}

# Save results
saveRDS(results, "p7_dd_results.rds")
cat("\\nResults saved to p7_dd_results.rds\\n")

# Print summary
for (clade in names(results)) {
    r <- results[[clade]]
    cat(sprintf("\\n%s (n=%d):\\n", clade, r$n_species))
    if (is.null(r$error)) {
        delta_aic_ndd <- 2 * (r$cr_loglik - r$ndd_loglik) + 2
        cat(sprintf("  CR: logL=%.2f, lambda=%.3f, mu=%.3f\\n", 
                    r$cr_loglik, r$cr_lambda0, r$cr_mu0))
        cat(sprintf("  NDD: logL=%.2f, lambda=%.3f, mu=%.3f, K=%.1f\\n", 
                    r$ndd_loglik, r$ndd_lambda0, r$ndd_mu0, r$ndd_K))
        cat(sprintf("  Delta AIC (NDD vs CR): %.2f\\n", delta_aic_ndd))
        if (!is.na(r$pdd_loglik)) {
            delta_aic_pdd <- 2 * (r$cr_loglik - r$pdd_loglik) + 2
            cat(sprintf("  PDD: logL=%.2f, lambda=%.3f, mu=%.3f, K=%.1f\\n", 
                        r$pdd_loglik, r$pdd_lambda0, r$pdd_mu0, r$pdd_K))
            cat(sprintf("  Delta AIC (PDD vs CR): %.2f\\n", delta_aic_pdd))
        }
        # Strategy: positive DD signalled by K < 0
        # (carrying capacity is negative → speciation accelerates with diversity)
        if (!is.na(r$ndd_K) && r$ndd_K < 0) {
            cat("  *** POSITIVE DD DETECTED (K < 0) ***\\n")
        }
    } else {
        cat(sprintf("  Error: %s\\n", r$error))
    }
}
"""


def parse_args():
    """Parse CLI args: --treedir, --treefile, --n_trees, --n_cores."""
    parser = argparse.ArgumentParser(
        description="Test P7: Positive diversity-dependent speciation in cultural bird lineages"
    )
    parser.add_argument(
        "--treedir",
        type=str,
        default="./birdtrees",
        help="Directory containing Jetz et al. (2012) bird phylogenies",
    )
    parser.add_argument(
        "--treefile",
        type=str,
        default=None,
        help="Specific tree file (nexus or newick format)",
    )
    parser.add_argument(
        "--n_trees",
        type=int,
        default=100,
        help="Number of posterior trees to analyze (default: 100)",
    )
    parser.add_argument(
        "--n_cores",
        type=int,
        default=4,
        help="Number of CPU cores for parallel processing",
    )
    return parser.parse_args()


def main():
    """Execute P7 sign reversal pipeline. Requires R with DDD package."""
    args = parse_args()
    
    logger.info("=" * 60)
    logger.info("P7: Sign Reversal on Generative Substrates")
    logger.info("=" * 60)
    
    logger.info(f"Cultural lineages: {', '.join(CULTURAL_LINEAGES.keys())}")
    logger.info(f"Non-cultural lineages: {', '.join(NON_CULTURAL_LINEAGES.keys())}")
    
    # Check prerequisites
    if args.treefile:
        tree_path = args.treefile
    elif args.treedir:
        # Find nexus or newick files
        tree_dir = Path(args.treedir)
        nexus_files = list(tree_dir.glob("*.nex")) + list(tree_dir.glob("*.nexus"))
        newick_files = list(tree_dir.glob("*.tre")) + list(tree_dir.glob("*.tree"))
        
        if nexus_files:
            tree_path = str(nexus_files[0])
        elif newick_files:
            tree_path = str(newick_files[0])
        else:
            logger.error("No tree files found in %s", args.treedir)
            logger.error("Download from birdtree.org first")
            logger.error("  e.g., Full trees, Hackett backbone (9993 species)")
            sys.exit(1)
    else:
        logger.error("No tree file or directory provided")
        sys.exit(1)
    
    logger.info(f"Using tree: {tree_path}")
    
    # Generate R script
    r_script = R_SCRIPT % (
        tree_path,
        ", ".join(f'"{v}"' for v in CULTURAL_LINEAGES.values()),
        ", ".join(f'"{v}"' for v in NON_CULTURAL_LINEAGES.values()),
    )
    
    r_script_path = "p7_dd_analysis.R"
    with open(r_script_path, "w") as f:
        f.write(r_script)
    
    logger.info(f"R analysis script written to {r_script_path}")
    logger.info("Run with: Rscript %s", r_script_path)
    logger.info("")
    logger.info("Note: Requires R packages: DDD, ape, phytools")
    logger.info("Install with: install.packages(c('DDD', 'ape', 'phytools'))")
    
    # Optional: run R immediately
    if input("Run R analysis now? (y/N): ").strip().lower() == "y":
        logger.info("Running R analysis...")
        result = subprocess.run(
            ["Rscript", r_script_path],
            capture_output=True,
            text=True,
            cwd=os.path.dirname(os.path.abspath(r_script_path)),
        )
        print(result.stdout)
        if result.stderr:
            print("STDERR:", result.stderr[:500])
        logger.info("R analysis complete")
    else:
        logger.info("Skipping R execution. Script ready for manual use.")


if __name__ == "__main__":
    main()