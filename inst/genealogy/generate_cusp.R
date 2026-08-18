#' Thom Cusp Catastrophe — Stage 3 of the Genealogy
#'
#' V(x) = x^4/4 + a*x^2/2 + b*x
#' Equilibria: dV/dx = x^3 + a*x + b = 0
#' Bifurcation set: 4*a^3 + 27*b^2 = 0
#'
#' @param seed Integer. Default 42.
#' @param n_a Integer. Number of 'a' values. Default 50.
#' @param n_b Integer. Number of 'b' values. Default 50.
#' @param a_range Numeric. Default c(-2, 2).
#' @param b_range Numeric. Default c(-2, 2).
#'
#' @return List with data frame: a, b, x_eq, V_eq, on_bifurcation_set, stage

generate_cusp <- function(seed = 42L, n_a = 50L, n_b = 50L,
                          a_range = c(-2, 2), b_range = c(-2, 2)) {
  withr::with_seed(seed, {
    a_vals <- seq(a_range[1], a_range[2], length.out = n_a)
    b_vals <- seq(b_range[1], b_range[2], length.out = n_b)
    results <- data.frame()

    for (a in a_vals) {
      for (b in b_vals) {
        D <- -4 * a^3 - 27 * b^2

        if (D < 0) {
          roots <- polyroot(c(b, a, 0, 1))
          real_roots <- Re(roots)[abs(Im(roots)) < 1e-6]
          for (x in real_roots) {
            V <- x^4 / 4 + a * x^2 / 2 + b * x
            bif_dist <- abs(4 * a^3 + 27 * b^2)
            results <- rbind(results, data.frame(
              a = a, b = b, x_eq = x, V_eq = V,
              on_bifurcation_set = bif_dist < 0.1,
              n_equilibria = 1, stage = "cusp"
            ))
          }
        } else {
          if (abs(a) < 1e-10) {
            x_roots <- c(-abs(b)^(1/3), 0, abs(b)^(1/3)) * sign(b)^(1/3)
          } else {
            phi <- acos(sqrt(3) * b / (2 * a) * sqrt(-3 / a)) / 3
            m <- 2 * sqrt(-a / 3)
            x_roots <- c(
              m * cos(phi),
              m * cos(phi - 2 * pi / 3),
              m * cos(phi - 4 * pi / 3)
            )
          }
          for (x in x_roots) {
            V <- x^4 / 4 + a * x^2 / 2 + b * x
            bif_dist <- abs(4 * a^3 + 27 * b^2)
            results <- rbind(results, data.frame(
              a = a, b = b, x_eq = x, V_eq = V,
              on_bifurcation_set = bif_dist < 0.1,
              n_equilibria = 3, stage = "cusp"
            ))
          }
        }
      }
    }

    list(
      values = list(n_points = nrow(results),
                    bifurcation_eq = "4a^3 + 27b^2 = 0",
                    n_on_bifurcation = sum(results$on_bifurcation_set)),
      metadata = list(
        seed = seed, data = results,
        params = list(n_a = n_a, n_b = n_b, a_range = a_range, b_range = b_range),
        generator = "generate_cusp", converged = TRUE
      )
    )
  })
}
