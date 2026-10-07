#' P8: Cross-Clade Diversity-Dependence × Cultural-Mediation PGLS
#'
#' Tests whether the correlation between diversity-dependent speciation
#' coefficient (Gl) and cultural mediation score survives phylogenetic
#' correction. Data from the E18 gradient (16 vertebrate clades).
#'
#' VI prediction: lineages with generative cultural substrates show
#' more positive (or less negative) diversity-dependent speciation,
#' controlling for shared evolutionary history.
#'
#' @param data Data frame with clade, dd, culture columns.
#'   From load_cross_clade_dd().
#' @param tree Newick string. Consensus mammal + bird phylogeny.
#' @param seed Integer. Reproducibility seed.
#'
#' @return List (A6 proof object):
#'   \item{values}{Named numeric: slope, p_value, r_squared, lambda,
#'                 slope_ols, p_ols, n_homo_dd, n_nonhomo_dd}
#'   \item{metadata}{List: seed, n_clades, converged, tree_tips}
#'
#' @section VI Prediction:
#'   Positive slope: more cultural mediation → more positive DD.
#'   Null result: slope ≈ 0 or negative.
#'
#' @dft
#' - A1: pure function, no I/O
#' - A2: seed injected
#' - A6: returns proof object
#'
#' @export
p8_cross_clade_pgls <- function(data, tree = NULL, seed = 42L) {
  withr::with_seed(seed, {
    # Default tree
    if (is.null(tree) || nchar(tree) < 10) {
      tree <- "((((Rodentia:28,(Platyrrhini:22,(Cercopithecidae:18,(Hominidae:14,Homo:12):2):6):10):18,((Eulipotyphla:18,Chiroptera:18):12,(Cetartiodactyla:25,(Carnivora:22,Canidae:19):3):7):12):25,Proboscidea:32):10,Marsupialia:40):8,(Corvidae:28,Psittacidae:28):18);"
    }

    # Parse tree
    if (is.character(tree)) {
      tree <- ape::read.tree(text = tree)
    }

    # Match data to tree tips
    data <- data[data$clade %in% tree$tip.label, ]
    tree <- ape::drop.tip(tree, tree$tip.label[!tree$tip.label %in% data$clade])

    # Build comparative data object
    rownames(data) <- data$clade
    comp <- caper::comparative.data(phy = tree, data = data,
      names.col = "clade", vcv = TRUE, warn.dropped = FALSE)

    # PGLS with ML lambda
    mod <- caper::pgls(dd ~ culture, data = comp, lambda = "ML")
    s <- summary(mod)

    # OLS (no phylogenetic correction) for comparison
    lm_mod <- lm(dd ~ culture, data = data)
    ls <- summary(lm_mod)

    n_homo <- sum(data$clade %in% c("Homo"))
    n_nonhomo <- nrow(data) - n_homo

    list(
      values = c(
        slope = unname(coef(mod)[2]),
        p_value = unname(s$coefficients[2, 4]),
        r_squared = unname(s$r.squared),
        lambda = unname(mod$param[2]),
        slope_ols = unname(coef(lm_mod)[2]),
        p_ols = unname(ls$coefficients[2, 4]),
        n_homo_dd = n_homo,
        n_nonhomo_dd = n_nonhomo
      ),
      metadata = list(
        seed = seed,
        n_clades = nrow(data),
        converged = s$model@converged,
        tree_tips = Ntip(tree)
      )
    )
  })
}

#' Data loader: cross-clade DD × cultural mediation
#'
#' Reads data/cross_clade_dd.csv.
#'
#' @return List with $data data frame.
#' @export
load_cross_clade_dd <- function() {
  path <- get_data_dir("cross_clade_dd.csv")
  data <- read.csv(file.path(path, "cross_clade_dd.csv"), stringsAsFactors = FALSE)
  list(data = data)
}