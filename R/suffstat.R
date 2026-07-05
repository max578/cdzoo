# suffstat.R -- Discovery from a sufficient statistic, and the tessera ingress.
#
# cd_discover() and the registered methods all consume a raw observation matrix;
# the constraint-based back-ends then reduce it to list(C = cor(data), n) before
# they run. A great deal of real data, though, arrives already aggregated -- a
# published correlation or covariance matrix, a privacy-preserving summary, or
# pairwise co-occurrence counts -- with no row-level matrix to hand. This file
# is the front door for that case: cd_discover_suffstat() runs constraint-based
# discovery directly on (C, n), and cd_correlation_from_counts() assembles a
# positive-definite correlation matrix from pairwise binary counts.
#
# Population-scale note. When n is very large, a significance-based conditional-
# independence test rejects independence for essentially every pair, so the
# recovered graph saturates. The magnitude test (test = "magnitude") prunes by
# effect size -- it drops an edge when the partial correlation falls below tau
# -- which is the right behaviour at population sample sizes.

#' Validate and normalise a correlation / covariance matrix
#'
#' @param C A square symmetric numeric matrix.
#' @returns A correlation matrix (covariance input is standardised) with
#'   dimnames, validated.
#' @noRd
#' @keywords internal
.cd_validate_corr <- function(C) {
  if (!is.matrix(C) || !is.numeric(C)) {
    stop(call. = FALSE, "`C` must be a numeric matrix.")
  }
  if (nrow(C) != ncol(C)) {
    stop(call. = FALSE, "`C` must be a square matrix.")
  }
  if (ncol(C) < 2L) {
    stop(call. = FALSE, "`C` must have at least two variables.")
  }
  if (any(!is.finite(C))) {
    stop(call. = FALSE, "`C` must not contain missing or non-finite values.")
  }
  if (max(abs(C - t(C))) > 1e-8) {
    stop(call. = FALSE, "`C` must be symmetric.")
  }
  # standardise a covariance to a correlation, but only after the diagonal is
  # known positive: cov2cor divides by sqrt(diag) and a zero or negative
  # variance would silently produce non-finite entries past the finite check.
  if (any(diag(C) <= 0)) {
    stop(call. = FALSE, "`C` must have a strictly positive diagonal.")
  }
  C <- stats::cov2cor(C)
  if (is.null(dimnames(C))) {
    nm <- paste0("x", seq_len(ncol(C)))
    dimnames(C) <- list(nm, nm)
  }
  storage.mode(C) <- "double"
  C
}

#' Magnitude-based conditional-independence test for pcalg
#'
#' A drop-in `indepTest` declaring independence when the partial correlation of
#' `x` and `y` given `S` falls below `suffStat$tau`. Returns `1` (independent)
#' or `0` (dependent); paired with `alpha = 0.5` this prunes by effect size, not
#' by significance, which is the correct behaviour at population sample sizes.
#'
#' @param x,y Integer node indices.
#' @param S Integer vector of conditioning node indices.
#' @param suffStat A list with the correlation matrix `C` and threshold `tau`.
#' @returns `1` when independent (below threshold), otherwise `0`.
#' @noRd
#' @keywords internal
.cd_pcor_mag_test <- function(x, y, S, suffStat) {
  r <- pcalg::pcorOrder(x, y, S, C = suffStat$C)
  as.numeric(abs(r) < suffStat$tau)
}

#' Project a symmetric matrix to the nearest positive-definite correlation
#' matrix
#'
#' Clips the eigenvalues at a small positive floor and rescales to a unit
#' diagonal. A base-R repair, so the ingress carries no extra dependency.
#'
#' @param C A symmetric numeric matrix.
#' @param tol The eigenvalue floor.
#' @returns A positive-definite correlation matrix with the dimnames of `C`.
#' @noRd
#' @keywords internal
.psd_repair <- function(C, tol = 1e-8) {
  e <- eigen(C, symmetric = TRUE)
  vals <- pmax(e$values, tol)
  m <- e$vectors %*% diag(vals, length(vals)) %*% t(e$vectors)
  d <- sqrt(diag(m))
  m <- m / outer(d, d)
  diag(m) <- 1
  dimnames(m) <- dimnames(C)
  m
}

#' Phi coefficient of a 2x2 table
#' @noRd
#' @keywords internal
.phi_2x2 <- function(n11, n10, n01, n00) {
  num <- n11 * n00 - n10 * n01
  den <- sqrt((n11 + n10) * (n01 + n00) * (n11 + n01) * (n10 + n00))
  if (den == 0) 0 else num / den
}

#' Tetrachoric (latent-Gaussian) correlation of a 2x2 table
#' @noRd
#' @keywords internal
.tetra_2x2 <- function(n11, n10, n01, n00) {
  tab <- matrix(c(n00, n10, n01, n11), nrow = 2L)
  suppressWarnings(psych::tetrachoric(tab, smooth = TRUE)$rho)
}

#' Metadata for a sufficient-statistic discovery method
#' @noRd
#' @keywords internal
.suffstat_method_meta <- function(method, test) {
  switch(
    method,
    ggm = list(id = "ggm_suffstat",
               name = "Gaussian graphical model (partial correlation)",
               family = "constraint", output = "cpdag"),
    pc = list(id = "pc_suffstat",
              name = sprintf("PC from sufficient statistic (%s)", test),
              family = "constraint", output = "cpdag"),
    fci = list(id = "fci_suffstat",
               name = sprintf("FCI from sufficient statistic (%s)", test),
               family = "constraint", output = "pag")
  )
}

#' Direct-comorbidity skeleton by partial-correlation magnitude
#' @noRd
#' @keywords internal
.ggm_skeleton <- function(C, tau) {
  # invert through the Cholesky factor and guard the conditioning: a matrix
  # repaired to the positive-definite floor can invert into explosive partial
  # correlations, so refuse rather than return noise.
  ch <- tryCatch(chol(C), error = function(e) NULL)
  if (is.null(ch) || kappa(ch)^2 > 1e12) {
    stop(call. = FALSE, paste0(
      "`C` is too ill-conditioned to invert for a partial-correlation ",
      "skeleton; supply a better-conditioned matrix (raise the `repair` floor ",
      "in cd_correlation_from_counts, or increase `tau`)."))
  }
  precision <- chol2inv(ch)
  scale <- sqrt(diag(precision))
  pcor <- -precision / outer(scale, scale)
  amat <- (abs(pcor) >= tau) * 1
  diag(amat) <- 0
  dimnames(amat) <- dimnames(C)
  storage.mode(amat) <- "double"
  amat
}

#' PC / FCI from a sufficient statistic
#' @noRd
#' @keywords internal
.suffstat_constraint <- function(method, C, n, test, alpha, tau, labels) {
  algo <- if (method == "pc") pcalg::pc else pcalg::fci
  # order-independent skeleton search on both branches, so the recovered graph
  # does not depend on the variable ordering.
  if (test == "gauss") {
    fit <- algo(list(C = C, n = n), pcalg::gaussCItest, alpha = alpha,
                labels = labels, skel.method = "stable", verbose = FALSE)
  } else {
    fit <- algo(list(C = C, tau = tau), .cd_pcor_mag_test, alpha = 0.5,
                labels = labels, skel.method = "stable", verbose = FALSE)
  }
  if (method == "pc") {
    methods::as(fit@graph, "matrix")
  } else {
    .pag_to_amat(fit@amat, labels)
  }
}

#' Discover a causal graph from a sufficient statistic
#'
#' Runs constraint-based discovery directly on a correlation (or covariance)
#' matrix and its sample size, returning a [cd_result] in the same `amat.cpdag`
#' convention as [cd_discover()]. This is the entry point for data that arrives
#' already aggregated -- a published correlation matrix, a privacy-preserving
#' summary, or the output of [cd_correlation_from_counts()] -- with no row-level
#' observation matrix to pass to [cd_discover()].
#'
#' `method = "ggm"` returns the Gaussian-graphical-model skeleton (an undirected
#' edge wherever the partial correlation given all other variables clears `tau`)
#' and needs no back-end. `method = "pc"` and `method = "fci"` run the PC and
#' FCI algorithms from `pcalg` and add such orientation as the data identify;
#' FCI additionally allows latent confounders.
#'
#' `test = "gauss"` uses the Fisher-Z significance test at level `alpha`, as
#' [cd_discover()] does. `test = "magnitude"` instead prunes an edge when the
#' partial correlation magnitude falls below `tau`; use it when `n` is so large
#' that a significance test would call every pair dependent.
#'
#' @param C A square correlation or covariance matrix; covariance input is
#'   standardised. Variable names are taken from its dimnames.
#' @param n A single positive number: the sample size the statistic summarises.
#' @param method One of `"pc"` (default), `"fci"`, or `"ggm"`.
#' @param test One of `"gauss"` (default) or `"magnitude"`.
#' @param alpha The Fisher-Z significance level for `test = "gauss"`.
#' @param tau The partial-correlation magnitude threshold for `test =
#'   "magnitude"` and for `method = "ggm"`.
#' @returns A [cd_result] whose `provenance$source` is `"suffstat"`.
#' @seealso [cd_discover()], [cd_correlation_from_counts()], [cd_score()]
#' @export
#' @examples
#' if (requireNamespace("pcalg", quietly = TRUE)) {
#'   sim <- cd_scenario("linear_gaussian", seed = 1)
#'   # discover from the sufficient statistic alone -- no row-level data
#'   res <- cd_discover_suffstat(stats::cor(sim$data), nrow(sim$data), "pc")
#'   cd_score(res, sim$truth)
#' }
cd_discover_suffstat <- function(C, n,
                                 method = c("pc", "fci", "ggm"),
                                 test = c("gauss", "magnitude"),
                                 alpha = 0.05, tau = 0.05) {
  method <- match.arg(method)
  test <- match.arg(test)
  C <- .cd_validate_corr(C)
  if (length(n) != 1L || !is.finite(n) || n < 1) {
    stop(call. = FALSE, "`n` must be a single positive number (sample size).")
  }
  needs_pcalg <- method %in% c("pc", "fci")
  if (needs_pcalg && !requireNamespace("pcalg", quietly = TRUE)) {
    stop(call. = FALSE, sprintf(paste0(
      "method = \"%s\" needs the 'pcalg' package; install it, or use ",
      "method = \"ggm\" (no back-end required)."), method))
  }
  labels <- colnames(C)
  meta <- .suffstat_method_meta(method, test)

  run <- .timed(function() {
    if (method == "ggm") {
      .ggm_skeleton(C, tau)
    } else {
      .suffstat_constraint(method, C, n, test, alpha, tau, labels)
    }
  })

  cd_result(
    graph = .coerce_amat(run$amat, labels),
    method = meta$id, method_name = meta$name, family = meta$family,
    language = "R", output = meta$output,
    runtime_s = run$runtime_s, status = run$status,
    provenance = list(source = "suffstat", n = as.double(n), p = ncol(C),
                      method = method, test = test,
                      threshold = if (test == "magnitude") tau else alpha))
}

#' Assemble a correlation matrix from pairwise binary counts
#'
#' Builds a positive-definite correlation matrix over a set of binary variables
#' from their pairwise two-by-two co-occurrence counts -- the aggregated form in
#' which co-occurrence data (comorbidity, market-basket, species co-occurrence)
#' is usually published. The result feeds straight into
#' [cd_discover_suffstat()].
#'
#' A matrix assembled pair by pair is not guaranteed positive semi-definite, so
#' it is repaired to the nearest positive-definite correlation matrix by
#' eigenvalue clipping when `repair = TRUE`; the eigenvalue floor reached and
#' the repair distortion are recorded in the result's `"repair"` attribute.
#'
#' Every unordered variable pair must appear exactly once; a repeated pair is an
#' error rather than a silent overwrite. A pair that is absent from `pairs` is
#' taken to have zero correlation (the off-diagonal entry stays zero before
#' repair).
#'
#' @param pairs A data frame with one row per variable pair and columns `var_i`,
#'   `var_j` (the two variable identifiers) and `n11`, `n10`, `n01`, `n00` (the
#'   counts of: both present, the first only, the second only, both absent).
#' @param type `"phi"` (default; the Pearson correlation of the two indicators,
#'   base R) or `"tetra"` (the latent-Gaussian tetrachoric correlation, which
#'   needs the `psych` package).
#' @param repair Whether to project an indefinite matrix to the nearest
#'   positive-definite correlation matrix. Defaults to `TRUE`.
#' @returns A correlation matrix with a `"repair"` attribute recording the
#'   minimum eigenvalue before and after repair, the Frobenius distortion, and
#'   the pair and variable counts.
#' @seealso [cd_discover_suffstat()]
#' @export
#' @examples
#' pairs <- data.frame(
#'   var_i = "a", var_j = "b",
#'   n11 = 900, n10 = 100, n01 = 100, n00 = 8900)
#' cd_correlation_from_counts(pairs)
cd_correlation_from_counts <- function(pairs,
                                       type = c("phi", "tetra"),
                                       repair = TRUE) {
  type <- match.arg(type)
  need <- c("var_i", "var_j", "n11", "n10", "n01", "n00")
  if (!all(need %in% names(pairs))) {
    stop(call. = FALSE, "`pairs` must have columns ",
         paste(need, collapse = ", "), ".")
  }
  counts <- as.matrix(pairs[, c("n11", "n10", "n01", "n00")])
  if (any(!is.finite(counts)) || any(counts < 0)) {
    stop(call. = FALSE,
         "the count columns (n11, n10, n01, n00) must be non-negative and ",
         "finite.")
  }
  # a variable pair appearing twice would be silently overwritten (last row
  # wins), quietly discarding data -- refuse instead.
  key <- paste(pmin(as.character(pairs$var_i), as.character(pairs$var_j)),
               pmax(as.character(pairs$var_i), as.character(pairs$var_j)),
               sep = "\r")
  if (anyDuplicated(key)) {
    stop(call. = FALSE,
         "`pairs` has more than one row for a variable pair; each unordered ",
         "pair must appear once.")
  }
  if (type == "tetra" && !requireNamespace("psych", quietly = TRUE)) {
    stop(call. = FALSE,
         "type = \"tetra\" needs the 'psych' package; install it, or use ",
         "type = \"phi\".")
  }
  cor_fun <- if (type == "phi") .phi_2x2 else .tetra_2x2
  vars <- sort(unique(c(as.character(pairs$var_i), as.character(pairs$var_j))))
  p <- length(vars)
  c_mat <- diag(p)
  dimnames(c_mat) <- list(vars, vars)
  for (r in seq_len(nrow(pairs))) {
    value <- cor_fun(pairs$n11[r], pairs$n10[r], pairs$n01[r], pairs$n00[r])
    i <- as.character(pairs$var_i[r])
    j <- as.character(pairs$var_j[r])
    c_mat[i, j] <- value
    c_mat[j, i] <- value
  }

  eig_min_raw <- min(eigen(c_mat, symmetric = TRUE, only.values = TRUE)$values)
  c_raw <- c_mat
  if (repair && eig_min_raw < 1e-8) {
    c_mat <- .psd_repair(c_mat)
  }
  eig_min <- min(eigen(c_mat, symmetric = TRUE, only.values = TRUE)$values)
  attr(c_mat, "repair") <- list(
    eig_min_raw = eig_min_raw, eig_min = eig_min,
    distortion = sqrt(sum((c_mat - c_raw)^2)),
    n_pairs = nrow(pairs), n_vars = p, type = type)
  c_mat
}

# ---------------------------------------------------------------------------
# A sufficient statistic as a first-class input
# ---------------------------------------------------------------------------

#' A sufficient statistic as a discovery input
#'
#' Wraps a correlation (or covariance) matrix and its sample size as a tagged
#' object that [cd_auto()] accepts in place of a data matrix, so the recommender
#' can route and run on data that arrives already aggregated. The matrix is
#' validated and standardised exactly as [cd_discover_suffstat()] does.
#'
#' @param C A square correlation or covariance matrix; covariance input is
#'   standardised. Variable names are taken from its dimnames.
#' @param n A single positive number: the sample size the statistic summarises.
#' @returns An object of class `cd_suffstat`: a list with the validated
#'   correlation matrix `C` and the sample size `n`.
#' @seealso [cd_auto()], [cd_discover_suffstat()]
#' @export
#' @examples
#' sim <- cd_scenario("linear_gaussian", seed = 1)
#' ss <- cd_suffstat(stats::cor(sim$data), nrow(sim$data))
#' ss$n
cd_suffstat <- function(C, n) {
  C <- .cd_validate_corr(C)
  if (length(n) != 1L || !is.finite(n) || n < 1) {
    stop(call. = FALSE, "`n` must be a single positive number (sample size).")
  }
  structure(list(C = C, n = as.double(n)), class = "cd_suffstat")
}

#' Run one registered suffstat method on a sufficient statistic
#'
#' Shared `run` body for the registered `*_suffstat` methods. Delegates to the
#' same helpers as [cd_discover_suffstat()], so there is one implementation of
#' each algorithm.
#'
#' @param method One of `"pc"`, `"fci"`, or `"ggm"`.
#' @param suff A `list(C, n)` sufficient statistic, optionally carrying `test`,
#'   `alpha`, and `tau`.
#' @returns A `.timed()` result list (`amat`, `runtime_s`, `status`).
#' @noRd
#' @keywords internal
.run_suffstat_method <- function(method, suff) {
  test <- suff$test %||% "gauss"
  alpha <- suff$alpha %||% 0.05
  tau <- suff$tau %||% 0.05
  labels <- colnames(suff$C)
  .timed(function() {
    if (method == "ggm") {
      .ggm_skeleton(suff$C, tau)
    } else {
      .suffstat_constraint(method, suff$C, suff$n, test, alpha, tau, labels)
    }
  })
}

#' Register the built-in sufficient-statistic methods
#'
#' Called once from `.onLoad`, after the data methods. These methods declare
#' `accepts = "suffstat"`, so [cd_discover()] reduces a data matrix to its
#' sufficient statistic before running them and [cd_auto()] routes a
#' [cd_suffstat()] input among them.
#'
#' @returns `NULL`, invisibly.
#' @noRd
#' @keywords internal
.register_suffstat_methods <- function() {
  register_method(cd_method(
    id = "ggm_suffstat",
    name = "Gaussian graphical model (partial correlation)",
    family = "constraint", language = "R", output = "cpdag",
    citation = "Lauritzen (1996)", cost = "fast",
    assumptions = "Gaussian; partial-correlation (precision) skeleton",
    accepts = "suffstat", available = function() TRUE,
    run = function(suff) .run_suffstat_method("ggm", suff)
  ))
  register_method(cd_method(
    id = "pc_suffstat", name = "PC from sufficient statistic",
    family = "constraint", language = "R", output = "cpdag",
    citation = "Spirtes, Glymour & Scheines (2000)", cost = "fast",
    assumptions = "causal sufficiency; linear-Gaussian CI test on (C, n)",
    accepts = "suffstat", available = .has_pkg("pcalg"),
    run = function(suff) .run_suffstat_method("pc", suff)
  ))
  register_method(cd_method(
    id = "fci_suffstat", name = "FCI from sufficient statistic",
    family = "constraint", language = "R", output = "pag",
    citation = "Spirtes, Meek & Richardson (1995)", cost = "fast",
    assumptions = "allows latent confounders; CI test on (C, n)",
    accepts = "suffstat", available = .has_pkg("pcalg"),
    run = function(suff) .run_suffstat_method("fci", suff)
  ))
  invisible(NULL)
}
