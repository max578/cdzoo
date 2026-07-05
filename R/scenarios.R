# scenarios.R -- Structural-causal-model scenarios with known ground truth.
#
# Each scenario generates data from a known DAG, so a recovered structure can be
# scored against an answer that the discovery method did not produce. The grid
# spans regimes that expose differential strengths -- Gaussian and non-Gaussian
# noise, multimodal and heteroscedastic disturbances, a nonlinear mechanism, a
# denser graph, a larger graph, a small sample, and heterogeneous regimes -- and
# is not tuned to flatter any one method.

# -- random DAG weighted adjacency (strictly lower triangular: i -> j, i < j) --
.random_lower_B <- function(p, edge_prob, lo, hi) {
  b <- matrix(0, p, p)
  for (j in seq_len(p)) {
    for (i in seq_len(j - 1L)) {
      if (stats::runif(1L) < edge_prob) {
        b[j, i] <- stats::runif(1L, lo, hi) * sample(c(-1, 1), 1L)
      }
    }
  }
  b
}

.rand_B <- function(p, edge_prob, seed) {
  # derive the graph seed in double arithmetic and fold back into integer range
  # only when needed, so a large scenario seed cannot overflow R's integer type
  # while every previously-valid seed keeps its realisation.
  derived <- as.double(seed) * 7919 + 13
  if (abs(derived) > .Machine$integer.max) {
    derived <- derived %% .Machine$integer.max
  }
  set.seed(as.integer(derived))
  .random_lower_B(p, edge_prob, lo = 0.5, hi = 1.5)
}

# -- noise families ----------------------------------------------------------
.noise_gaussian <- function(n, sd) stats::rnorm(n, sd = sd)

.noise_laplace <- function(n, sd) {
  u <- stats::runif(n) - 0.5
  z <- -sign(u) * log(1 - 2 * abs(u))
  sd * z / stats::sd(z)
}

.noise_bimodal <- function(n, sd) {
  comp <- sample(c(-1, 1), n, replace = TRUE)
  z <- comp * 3 + stats::rnorm(n, sd = 0.6)
  sd * (z - mean(z)) / stats::sd(z)
}

.noise_scalemix <- function(n, sd) {
  s <- sample(c(0.4, 2.2), n, replace = TRUE, prob = c(0.7, 0.3))
  z <- stats::rnorm(n, sd = s)
  sd * (z - mean(z)) / stats::sd(z)
}

# -- structural-causal-model builders ---------------------------------------
.sim_linear_noise <- function(n, B, noisefun, noise_sd = 1, seed = NULL) {
  # force the (lazily supplied) graph before seeding: .rand_B seeds its own
  # stream while drawing B, so without the force the noise below would run on
  # the tail of the graph stream and this set.seed would be dead code.
  force(B)
  if (!is.null(seed)) {
    set.seed(seed)
  }
  p <- nrow(B)
  x <- matrix(0, n, p)
  for (j in seq_len(p)) {
    parents <- which(B[j, ] != 0)
    mu <- if (length(parents)) {
      x[, parents, drop = FALSE] %*% B[j, parents]
    } else {
      rep(0, n)
    }
    x[, j] <- mu + noisefun(n, noise_sd)
  }
  colnames(x) <- paste0("x", seq_len(p))
  list(data = x, dag = (B != 0) * 1L, p = p, n = n)
}

# heterogeneous regimes: each edge's coefficient flips sign between two latent
# subpopulations, so the pooled linear correlation is near zero but the joint is
# a clear two-component mixture.
.sim_regimes <- function(n, B, noise_sd = 0.5, seed = NULL) {
  # force B before seeding, for the same reason as .sim_linear_noise
  force(B)
  if (!is.null(seed)) {
    set.seed(seed)
  }
  p <- nrow(B)
  regime <- sample(c(1, -1), n, replace = TRUE)
  x <- matrix(0, n, p)
  for (j in seq_len(p)) {
    parents <- which(B[j, ] != 0)
    mu <- if (length(parents)) {
      (x[, parents, drop = FALSE] %*% B[j, parents]) * regime
    } else {
      rep(0, n)
    }
    x[, j] <- mu + stats::rnorm(n, sd = noise_sd)
  }
  colnames(x) <- paste0("x", seq_len(p))
  list(data = x, dag = (B != 0) * 1L, p = p, n = n)
}

# nonlinear additive-noise chain x1 -> x2 -> ... with nonlinear mechanisms.
.sim_nonlinear_anm <- function(n, p = 6L, noise_sd = 0.5, seed = NULL) {
  if (!is.null(seed)) {
    set.seed(seed)
  }
  fns <- list(
    function(z) sin(2 * z),
    function(z) z^3 / 3,
    function(z) tanh(2 * z),
    function(z) sign(z) * sqrt(abs(z))
  )
  x <- matrix(0, n, p)
  x[, 1L] <- .noise_laplace(n, 1)
  for (j in seq_len(p - 1L) + 1L) {
    f <- fns[[((j - 2L) %% length(fns)) + 1L]]
    x[, j] <- f(x[, j - 1L]) + .noise_laplace(n, noise_sd)
  }
  colnames(x) <- paste0("x", seq_len(p))
  b <- matrix(0, p, p)
  for (j in seq_len(p - 1L) + 1L) {
    b[j, j - 1L] <- 1
  }
  list(data = x, dag = (b != 0) * 1L, p = p, n = n)
}

# -- the scenario registry ---------------------------------------------------
.SCENARIOS <- list(
  linear_gaussian = list(
    p = 6L, n = 500L, family = "linear-Gaussian",
    description = "Gaussian noise; constraint- and score-based territory.",
    gen = function(seed) {
      .sim_linear_noise(500L, .rand_B(6L, 0.4, seed), .noise_gaussian,
                        seed = seed)
    }),
  linear_laplace = list(
    p = 6L, n = 500L, family = "linear-non-Gaussian",
    description = "Heavy-tailed Laplace noise; LiNGAM-family territory.",
    gen = function(seed) {
      .sim_linear_noise(500L, .rand_B(6L, 0.4, seed), .noise_laplace,
                        seed = seed)
    }),
  linear_bimodal = list(
    p = 6L, n = 500L, family = "linear-multimodal",
    description = "Strongly bimodal mixture noise.",
    gen = function(seed) {
      .sim_linear_noise(500L, .rand_B(6L, 0.4, seed), .noise_bimodal,
                        seed = seed)
    }),
  linear_scalemix = list(
    p = 6L, n = 500L, family = "linear-heteroscedastic",
    description = "Scale-mixture (heteroscedastic-marginal) noise.",
    gen = function(seed) {
      .sim_linear_noise(500L, .rand_B(6L, 0.4, seed), .noise_scalemix,
                        seed = seed)
    }),
  nonlinear_anm = list(
    p = 6L, n = 500L, family = "nonlinear-additive",
    description = "Nonlinear additive-noise chain.",
    gen = function(seed) .sim_nonlinear_anm(500L, p = 6L, seed = seed)),
  dense_bimodal = list(
    p = 6L, n = 800L, family = "dense-multimodal",
    description = "Denser graph with bimodal noise (edge-density stress).",
    gen = function(seed) {
      .sim_linear_noise(800L, .rand_B(6L, 0.65, seed), .noise_bimodal,
                        seed = seed)
    }),
  larger_p10 = list(
    p = 10L, n = 800L, family = "larger-multimodal",
    description = "Ten variables with bimodal noise (scalability).",
    gen = function(seed) {
      .sim_linear_noise(800L, .rand_B(10L, 0.3, seed), .noise_bimodal,
                        seed = seed)
    }),
  small_n = list(
    p = 6L, n = 150L, family = "low-sample-multimodal",
    description = "Bimodal noise at a small sample size.",
    gen = function(seed) {
      .sim_linear_noise(150L, .rand_B(6L, 0.4, seed), .noise_bimodal,
                        seed = seed)
    }),
  regime_switching = list(
    p = 5L, n = 800L, family = "heterogeneous-regimes",
    description = "Sign-flipping edges across two latent regimes.",
    gen = function(seed) .sim_regimes(800L, .rand_B(5L, 0.45, seed),
                                      seed = seed))
)

#' True adjacency matrix from a simulated DAG
#'
#' Converts the simulator's `dag` (where `dag[j, i] == 1` encodes \eqn{i \to j})
#' into the package's `amat.cpdag` convention (`amat[i, j] == 1` encodes
#' \eqn{i \to j}).
#'
#' @param dag A 0/1 matrix in the simulator convention.
#' @param labels The variable names.
#' @returns A square double matrix, the true graph in `amat.cpdag` convention.
#' @noRd
#' @keywords internal
.true_amat <- function(dag, labels) {
  a <- t(dag) * 1
  dimnames(a) <- list(labels, labels)
  storage.mode(a) <- "double"
  a
}

#' Generate a benchmark scenario with known ground truth
#'
#' Realises one of the built-in structural-causal-model scenarios at a given seed
#' and returns the data together with the true graph, the independent oracle a
#' recovered structure is scored against by [cd_score()].
#'
#' @param name A single string: the scenario name (see [cd_scenarios()]).
#' @param seed A single integer-valued seed for reproducibility; any finite
#'   number is accepted (a value beyond integer range is folded back into it).
#' @returns A list with `data` (the observation matrix), `truth` (the true graph
#'   in `amat.cpdag` convention), `dag` (the raw simulator DAG), `scenario`,
#'   `family`, `p`, and `n`.
#' @seealso [cd_scenarios()], [cd_score()], [cd_benchmark()]
#' @export
#' @examples
#' sim <- cd_scenario("linear_gaussian", seed = 1)
#' dim(sim$data)
#' sim$truth
cd_scenario <- function(name, seed = 1L) {
  if (!name %in% names(.SCENARIOS)) {
    stop(call. = FALSE, sprintf(
      "Unknown scenario '%s'. See cd_scenarios()$name.", name))
  }
  if (length(seed) != 1L || !is.finite(seed)) {
    stop(call. = FALSE, "`seed` must be a single finite number.")
  }
  seed <- as.double(seed)
  if (abs(seed) > .Machine$integer.max) {
    seed <- seed %% .Machine$integer.max
  }
  sc <- .SCENARIOS[[name]]
  sim <- sc$gen(as.integer(seed))
  labels <- colnames(sim$data)
  list(
    data = sim$data,
    truth = .true_amat(sim$dag, labels),
    dag = sim$dag,
    scenario = name,
    family = sc$family,
    p = sim$p,
    n = sim$n
  )
}

#' The built-in benchmark scenarios
#'
#' Lists the structural-causal-model scenarios available to [cd_scenario()] and
#' [cd_benchmark()].
#'
#' @returns A data frame with columns `name`, `p`, `n`, `family`, and
#'   `description`.
#' @seealso [cd_scenario()], [cd_benchmark()]
#' @export
#' @examples
#' cd_scenarios()
cd_scenarios <- function() {
  nm <- names(.SCENARIOS)
  data.frame(
    name = nm,
    p = vapply(.SCENARIOS, function(s) s$p, integer(1)),
    n = vapply(.SCENARIOS, function(s) s$n, integer(1)),
    family = vapply(.SCENARIOS, function(s) s$family, character(1)),
    description = vapply(.SCENARIOS, function(s) s$description, character(1)),
    row.names = NULL,
    stringsAsFactors = FALSE
  )
}
