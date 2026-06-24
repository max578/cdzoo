# features.R -- Cheap data-characteristic tests that drive the recommender.
#
# Each test answers one routing-relevant question about a data set with a
# transparent, base-R statistic. They are deliberately simple and fast; the
# recommender reports which test fired and how decisively, so the user can judge
# the route. None of them is a discovery algorithm -- they only describe the
# data.

#' Excess kurtosis of a numeric vector
#'
#' @param x A numeric vector.
#' @returns The excess kurtosis (0 for a Gaussian).
#' @noRd
#' @keywords internal
.excess_kurtosis <- function(x) {
  x <- x - mean(x)
  m2 <- mean(x^2)
  if (m2 <= 0) {
    return(0)
  }
  mean(x^4) / (m2^2) - 3
}

#' Fraction of columns whose marginal departs from Gaussian
#'
#' Uses the Shapiro-Wilk test (sub-sampled to its 5000-row limit) per column and
#' reports the share that reject normality at the 5% level, alongside the mean
#' absolute excess kurtosis as a continuous companion.
#'
#' @param data A numeric matrix.
#' @returns A list with `reject_fraction` and `mean_abs_kurtosis`.
#' @noRd
#' @keywords internal
.non_gaussianity <- function(data) {
  n <- nrow(data)
  idx <- if (n > 5000L) sample.int(n, 5000L) else seq_len(n)
  rej <- vapply(seq_len(ncol(data)), function(j) {
    xj <- data[idx, j]
    if (stats::sd(xj) == 0) {
      return(NA)
    }
    p <- tryCatch(stats::shapiro.test(xj)$p.value, error = function(e) NA_real_)
    isTRUE(p < 0.05)
  }, logical(1))
  kurt <- vapply(seq_len(ncol(data)),
                 function(j) abs(.excess_kurtosis(data[, j])), numeric(1))
  list(
    reject_fraction = mean(rej, na.rm = TRUE),
    mean_abs_kurtosis = mean(kurt, na.rm = TRUE)
  )
}

#' Per-node residual variances from a linear leave-one-in regression
#'
#' Regresses each variable on all the others and returns the residual variance.
#' Their spread speaks to the equal-noise-variance identifiability that the
#' continuous-optimisation methods exploit.
#'
#' @param data A numeric matrix.
#' @returns A numeric vector of residual variances, one per variable.
#' @noRd
#' @keywords internal
.residual_variances <- function(data) {
  n <- nrow(data)
  idx <- if (n > 2000L) sample.int(n, 2000L) else seq_len(n)
  d <- as.data.frame(data[idx, , drop = FALSE])
  vapply(seq_along(d), function(j) {
    fit <- tryCatch(
      stats::lm(d[[j]] ~ ., data = d[, -j, drop = FALSE]),
      error = function(e) NULL
    )
    if (is.null(fit)) {
      return(stats::var(d[[j]]))
    }
    stats::var(stats::residuals(fit))
  }, numeric(1))
}

#' A curvature heuristic for nonlinear mechanisms
#'
#' For each variable, compares the fit of a linear regression on the others with
#' one that adds their squared terms; the gain in `R^2` is a heuristic signal of
#' a nonlinear mechanism. The score is the largest gain across variables.
#'
#' @param data A numeric matrix.
#' @returns A single number in `[0, 1]`: the maximum quadratic `R^2` gain.
#' @noRd
#' @keywords internal
.nonlinearity_score <- function(data) {
  n <- nrow(data)
  idx <- if (n > 2000L) sample.int(n, 2000L) else seq_len(n)
  d <- as.data.frame(data[idx, , drop = FALSE])
  p <- ncol(d)
  gains <- vapply(seq_len(p), function(j) {
    y <- d[[j]]
    x <- d[, -j, drop = FALSE]
    lin <- tryCatch(stats::lm(y ~ ., data = x), error = function(e) NULL)
    if (is.null(lin)) {
      return(0)
    }
    xq <- as.data.frame(lapply(x, function(col) col^2))
    names(xq) <- paste0(names(x), "_sq")
    quad <- tryCatch(stats::lm(y ~ ., data = cbind(x, xq)),
                     error = function(e) NULL)
    if (is.null(quad)) {
      return(0)
    }
    r2_lin <- summary(lin)$r.squared
    r2_quad <- summary(quad)$r.squared
    max(0, r2_quad - r2_lin)
  }, numeric(1))
  max(gains, 0)
}

#' A latent-confounder hint from near-singular covariance
#'
#' A very ill-conditioned correlation matrix (a near-zero smallest eigenvalue) is
#' a weak hint of a low-rank structure such as a shared latent factor, where a
#' confounder-robust method is worth considering.
#'
#' @param data A numeric matrix.
#' @returns A single number: the condition number of the correlation matrix.
#' @noRd
#' @keywords internal
.condition_number <- function(data) {
  cc <- tryCatch(stats::cor(data), error = function(e) NULL)
  if (is.null(cc) || any(!is.finite(cc))) {
    return(NA_real_)
  }
  ev <- eigen(cc, symmetric = TRUE, only.values = TRUE)$values
  ev <- ev[ev > 0]
  if (length(ev) == 0L) {
    return(NA_real_)
  }
  max(ev) / min(ev)
}

#' Data characteristics of a discovery problem
#'
#' Computes the transparent statistics the recommender reads: how non-Gaussian
#' the margins are, how equal the per-node residual variances are, a curvature
#' heuristic for nonlinear mechanisms, and a near-singularity hint for latent
#' structure. They describe the data; they do not discover a graph.
#'
#' @param data A numeric matrix or data frame.
#' @returns A list with the named characteristics: `n`, `p`,
#'   `non_gaussian_fraction`, `mean_abs_kurtosis`, `equal_variance_ratio`,
#'   `nonlinearity`, and `condition_number`.
#' @noRd
#' @keywords internal
.cd_features <- function(data) {
  rv <- .residual_variances(data)
  ng <- .non_gaussianity(data)
  rv_pos <- rv[rv > 0]
  list(
    n = nrow(data),
    p = ncol(data),
    non_gaussian_fraction = ng$reject_fraction,
    mean_abs_kurtosis = ng$mean_abs_kurtosis,
    equal_variance_ratio = if (length(rv_pos) > 0L) {
      max(rv_pos) / min(rv_pos)
    } else {
      NA_real_
    },
    nonlinearity = .nonlinearity_score(data),
    condition_number = .condition_number(data)
  )
}

#' Describe the characteristics of a discovery data set
#'
#' Reports the data characteristics the recommender uses to route a problem, as a
#' one-row data frame. Use it to see what [cd_auto()] sees before it chooses a
#' method.
#'
#' @param data A numeric matrix or data frame of observations (rows) by
#'   variables (columns).
#' @returns A one-row data frame of the characteristics described in
#'   [cd_auto()]'s routing.
#' @seealso [cd_auto()]
#' @export
#' @examples
#' sim <- cd_scenario("linear_laplace", seed = 1)
#' cd_diagnose(sim$data)
cd_diagnose <- function(data) {
  data <- .validate_data(data)
  f <- .cd_features(data)
  data.frame(
    n = f$n,
    p = f$p,
    non_gaussian_fraction = round(f$non_gaussian_fraction, 3),
    mean_abs_kurtosis = round(f$mean_abs_kurtosis, 3),
    equal_variance_ratio = round(f$equal_variance_ratio, 3),
    nonlinearity = round(f$nonlinearity, 3),
    condition_number = round(f$condition_number, 1),
    stringsAsFactors = FALSE
  )
}
