# auto.R -- The evidence-routed recommender.
#
# Causal discovery has no run-time ground truth, so this is a recommender, not a
# selector: it inspects the data characteristics, routes to the method the
# benchmark shows is suited to that regime, runs the best installed method on
# that route, and reports its rationale and a confidence label. It never claims
# "the best" -- it says why it chose and how sure it is, and offers a consensus
# of several methods when asked.
#
# The routing preferences are grounded in this package's scenario benchmark
# (see cd_field_benchmark and the package vignette): the continuous-optimisation
# methods lead on equal-variance linear-Gaussian data, the LiNGAM family is the
# cheap and accurate choice when the noise is non-Gaussian, a kernel CI test
# suits nonlinear mechanisms, and a confounder-robust method is the safer choice
# when latent structure is hinted at.

# The data-characteristic cutoffs that decide the route. They are the
# recommender's whole epistemology, so they live in one named place: read here,
# reported in every recommendation's provenance, and documented in cd_auto().
.ROUTING_THRESHOLDS <- list(
  nonlinearity = 0.05,        # quadratic R-squared gain above which a nonlinear
                              # mechanism is suspected
  non_gaussian_fraction = 0.5, # share of non-Gaussian margins that routes to
                              # the LiNGAM family
  condition_number = 1000,    # correlation condition number above which latent
                              # structure is hinted
  equal_variance_ratio = 2    # residual-variance spread below which equal-
                              # variance identifiability is assumed
)

#' First available method from a preference order
#'
#' @param order A character vector of method ids, best first.
#' @param available A character vector of available method ids.
#' @returns The first preferred id that is available, or `NA_character_`.
#' @noRd
#' @keywords internal
.prefer <- function(order, available) {
  hit <- order[order %in% available]
  if (length(hit) == 0L) NA_character_ else hit[1L]
}

#' Route a sampled-data problem to a method
#'
#' @param f The data characteristics from `.cd_features()`.
#' @param available Available method ids.
#' @returns A list with `method` (chosen, installed, or `NA`), `ideal` (the
#'   benchmark-preferred id regardless of installation), `rationale`,
#'   `confidence`, and `alternatives` (the route's preference order).
#' @noRd
#' @keywords internal
.route_sampled <- function(f, available) {
  ng <- f$non_gaussian_fraction
  ev_ratio <- f$equal_variance_ratio
  cn <- f$condition_number
  nl <- f$nonlinearity

  # Per-regime preference orders -------------------------------------------
  # Each route lists methods best-first for that data signature; the ordering
  # is grounded in cd_field_benchmark.
  routes <- list(
    nonlinear = c("pc_kci_cl", "ges_pcalg", "pc_pcalg", "mmhc_bnlearn"),
    non_gaussian = c("icalingam_pcalg", "directlingam_py", "rcd_py",
                     "dagma_linear_py"),
    latent = c("fci_pcalg", "rcd_py"),
    equal_variance = c("golem_gcastle", "dagma_linear_py", "notears_gcastle",
                       "ges_pcalg", "pc_pcalg"),
    default = c("golem_gcastle", "dagma_linear_py", "icalingam_pcalg",
                "ges_pcalg", "pc_pcalg")
  )

  pick <- function(route, rationale, confidence) {
    order <- routes[[route]]
    list(order = order, ideal = order[1L], rationale = rationale,
         confidence = confidence)
  }

  # Decide the route -------------------------------------------------------
  # Check the four data-characteristic thresholds in priority order; the first
  # to fire picks the route, its rationale, and a confidence label.
  thr <- .ROUTING_THRESHOLDS
  decided <- if (!is.na(nl) && nl > thr$nonlinearity) {
    pick("nonlinear", sprintf(
      paste0("a curvature heuristic flags a possible nonlinear mechanism ",
             "(quadratic R-squared gain %.2f); a kernel conditional-independence ",
             "test (PC+KCI) is suited to nonlinear dependence"), nl),
    "moderate")
  } else if (!is.na(ng) && ng >= thr$non_gaussian_fraction) {
    pick("non_gaussian", sprintf(
      paste0("%.0f%% of variables depart from normality (mean |excess ",
             "kurtosis| %.2f); the LiNGAM family exploits non-Gaussianity for ",
             "orientation and is fast"), 100 * ng, f$mean_abs_kurtosis),
    if (ng > 0.8) "high" else "moderate")
  } else if (!is.na(cn) && cn > thr$condition_number) {
    pick("latent", sprintf(
      paste0("a near-singular covariance (condition number %.0f) hints at ",
             "latent structure; a confounder-robust method (FCI / RCD) is the ",
             "safer choice"), cn),
    "low")
  } else if (!is.na(ev_ratio) && ev_ratio < thr$equal_variance_ratio) {
    pick("equal_variance", sprintf(
      paste0("approximately Gaussian margins with comparable per-node residual ",
             "variances (ratio %.2f); the continuous-optimisation methods ",
             "exploit equal-variance identifiability and lead the benchmark on ",
             "this regime"), ev_ratio),
    if (ev_ratio < 1.5) "high" else "moderate")
  } else {
    pick("default",
         paste0("no decisive data signature; using the benchmark's strongest ",
                "overall method"),
         "moderate")
  }

  method <- .prefer(decided$order, available)
  rationale <- decided$rationale
  confidence <- decided$confidence
  # If the route's preferred methods are all absent, fall back to the strongest
  # available method anywhere and say so plainly.
  if (is.na(method)) {
    method <- .prefer(routes$default, available)
    if (is.na(method) && length(available) > 0L) {
      method <- available[1L]
    }
  }
  if (!is.na(method) && !identical(method, decided$ideal)) {
    ideal_name <- .method_label(decided$ideal)
    rationale <- paste0(
      rationale,
      sprintf(". The preferred method (%s) is not installed; using %s",
              ideal_name, .method_label(method)))
  }
  list(method = method, ideal = decided$ideal, rationale = rationale,
       confidence = confidence, alternatives = decided$order)
}

#' Display label for a method id
#'
#' @param id A method id.
#' @returns The method's display name, or the id when it is not registered.
#' @noRd
#' @keywords internal
.method_label <- function(id) {
  m <- .get_method(id)
  if (is.null(m) || !nzchar(m@name)) id else m@name
}

#' Is the input an evaluable-density object rather than a data matrix?
#'
#' @param data The first argument to [cd_auto()].
#' @returns `TRUE` when `data` is a proxymix mixture or target object.
#' @noRd
#' @keywords internal
.is_density_input <- function(data) {
  if (!requireNamespace("proxymix", quietly = TRUE)) {
    return(FALSE)
  }
  S7::S7_inherits(data, proxymix::gmm) ||
    S7::S7_inherits(data, proxymix::gmm_target)
}

#' Route an evaluable-density input to the density-structure method
#'
#' When the input is an evaluable density rather than a sample -- a fitted
#' proxymix mixture, or a target the mixture is fitted to -- the conditional-
#' independence (Markov) structure is read off the mixture in closed form. This
#' is the route for the case where a density can be evaluated but not sampled,
#' which the sampling-based methods cannot serve.
#'
#' @param data A proxymix `gmm`, `gmm_fit`, or `gmm_target`.
#' @param threshold The partial-correlation threshold for an edge.
#' @param density_components The number of mixture components to fit when `data`
#'   is a target rather than an already-fitted mixture.
#' @returns A [cd_result].
#' @noRd
#' @keywords internal
.route_density <- function(data, threshold, density_components) {
  t0 <- Sys.time()
  g <- if (S7::S7_inherits(data, proxymix::gmm_target)) {
    proxymix::fit_proxymix(data, N = density_components, regime = "kld")
  } else {
    data
  }
  amat <- proxymix::gmm_independence_graph(g, threshold = threshold)
  storage.mode(amat) <- "double"
  attr(amat, "pcor") <- NULL
  rt <- as.numeric(Sys.time() - t0, units = "secs")
  cd_result(
    graph = amat, method = "gmm_independence_graph",
    method_name = "Mixture independence graph", family = "density",
    language = "R", output = "cpdag", runtime_s = rt, status = "ok",
    rationale = paste0(
      "the input is an evaluable density, not a sample; the conditional-",
      "independence (Markov) structure is read off the mixture in closed form"),
    confidence = "high",
    provenance = list(threshold = threshold, mode = "density")
  )
}

#' Combine several results into a stability-weighted consensus graph
#'
#' @param results A list of [cd_result] objects on the same variables.
#' @param labels The variable names.
#' @returns A list with `amat` (the consensus graph) and `agreement` (the
#'   per-edge skeleton agreement matrix).
#' @noRd
#' @keywords internal
.combine_consensus <- function(results, labels) {
  ok <- Filter(function(r) {
    r@status == "ok" && length(r@graph) > 0L
  }, results)
  p <- length(labels)
  empty <- list(amat = matrix(numeric(0), 0L, 0L),
                agreement = matrix(numeric(0), 0L, 0L))
  if (length(ok) == 0L) {
    return(empty)
  }
  skel <- matrix(0, p, p, dimnames = list(labels, labels))
  fwd <- matrix(0, p, p)
  und <- matrix(0, p, p)
  for (r in ok) {
    g <- r@graph[labels, labels, drop = FALSE]
    for (i in seq_len(p)) {
      for (j in seq_len(p)) {
        if (i >= j) {
          next
        }
        a_ij <- g[i, j] != 0
        a_ji <- g[j, i] != 0
        if (a_ij || a_ji) {
          skel[i, j] <- skel[i, j] + 1
          if (a_ij && a_ji) {
            und[i, j] <- und[i, j] + 1
          } else if (a_ij) {
            fwd[i, j] <- fwd[i, j] + 1
          } else {
            fwd[j, i] <- fwd[j, i] + 1
          }
        }
      }
    }
  }
  agreement <- skel / length(ok)
  amat <- matrix(0, p, p, dimnames = list(labels, labels))
  for (i in seq_len(p)) {
    for (j in seq_len(p)) {
      if (i >= j) {
        next
      }
      if (agreement[i, j] >= 0.5) {
        n_ij <- fwd[i, j]
        n_ji <- fwd[j, i]
        n_un <- und[i, j]
        if (n_ij > n_ji && n_ij >= n_un) {
          amat[i, j] <- 1
        } else if (n_ji > n_ij && n_ji >= n_un) {
          amat[j, i] <- 1
        } else {
          amat[i, j] <- 1
          amat[j, i] <- 1
        }
      }
    }
  }
  agreement <- agreement + t(agreement)
  dimnames(agreement) <- list(labels, labels)
  list(amat = amat, agreement = agreement)
}

#' Recommend and run a causal-discovery method for a data set
#'
#' Inspects a data set with [cd_diagnose()]'s transparent characteristics,
#' routes it to a discovery method suited to that regime, runs the best
#' installed method on the route, and returns the recovered graph together with
#' the routing rationale and a confidence label. Because causal discovery has no
#' run-time ground truth, this is a recommender, not a selector: it reports why
#' it chose and how sure it is, and -- in `"consensus"` mode -- returns a
#' stability-weighted union of several methods with per-edge agreement.
#'
#' The route is decided by four data-characteristic thresholds, checked in this
#' order and reported in the result's `provenance$thresholds`: a curvature
#' heuristic above `0.05` routes to a kernel conditional-independence test; a
#' non-Gaussian margin fraction of `0.5` or more routes to the LiNGAM family; a
#' correlation condition number above `1000` (a latent-structure hint) routes to
#' a confounder-robust method; and a residual-variance ratio below `2` routes to
#' the equal-variance continuous-optimisation methods. Failing all four, the
#' benchmark's strongest overall method is used.
#'
#' When `data` is an evaluable density rather than a sample -- a proxymix `gmm`,
#' `gmm_fit`, or `gmm_target` (requires the suggested \pkg{proxymix} package) --
#' the conditional-independence (Markov) structure is read off the mixture in
#' closed form, the route for the case where a density can be evaluated but not
#' sampled.
#'
#' @param data A numeric matrix or data frame of observations by variables, or
#'   an evaluable-density object (a proxymix `gmm` / `gmm_fit` / `gmm_target`).
#' @param mode `"route"` (run the single recommended method) or `"consensus"`
#'   (run the top `top_k` installed methods on the route and return their
#'   stability-weighted union).
#' @param report A single logical. When `TRUE` (the default) the recommended
#'   method is run and its graph returned; when `FALSE` only the recommendation
#'   is returned, with an empty graph and the status
#'   `"recommendation only (report = FALSE)"`.
#' @param top_k The number of methods to combine in `"consensus"` mode.
#' @param threshold The partial-correlation edge threshold for the
#'   density route.
#' @param density_components The number of mixture components to fit when
#'   routing an evaluable target density.
#' @returns A [cd_result] whose `rationale`, `confidence`, and `alternatives`
#'   (always a list of method labels, in the route's preference order) record
#'   the recommendation. In `"consensus"` mode the per-edge agreement and the
#'   individual member results are stored in the result's `provenance` (as
#'   `agreement` and `runs`).
#' @seealso [cd_diagnose()], [cd_discover()], [list_methods()]
#' @export
#' @examples
#' if (requireNamespace("pcalg", quietly = TRUE)) {
#'   sim <- cd_scenario("linear_laplace", seed = 1)
#'   rec <- cd_auto(sim$data, report = FALSE)
#'   rec@rationale
#' }
cd_auto <- function(data, mode = c("route", "consensus"), report = TRUE,
                    top_k = 3L, threshold = 0.05, density_components = 4L) {
  mode <- match.arg(mode)

  # Density route ----------------------------------------------------------
  # An evaluable density is not a sample; its Markov structure is read in
  # closed form, the case the sampling methods cannot serve.
  if (.is_density_input(data)) {
    return(.route_density(data, threshold, density_components))
  }

  # Route -----------------------------------------------------------------
  # Describe the data, then route on those characteristics. The provenance
  # records the features, the ideal method, and the deciding thresholds, so
  # every recommendation carries the evidence it was made on.
  data <- .validate_data(data)
  available <- .available_method_ids()
  f <- .cd_features(data)
  route <- .route_sampled(f, available)
  prov <- list(features = f, ideal = route$ideal, mode = mode,
               thresholds = .ROUTING_THRESHOLDS)
  alt <- vapply(route$alternatives, .method_label, character(1))

  # No back-end installed: return the recommendation, not a graph.
  if (is.na(route$method) || length(available) == 0L) {
    return(cd_result(
      method = if (is.na(route$ideal)) NA_character_ else route$ideal,
      method_name = .method_label(route$ideal),
      family = NA_character_, status = "no back-end installed",
      rationale = paste0(
        route$rationale,
        ". No discovery back-end is installed; install one of the suggested ",
        "packages (pcalg, bnlearn, or a Python back-end via reticulate) to run ",
        "the recommendation."),
      confidence = route$confidence, alternatives = as.list(alt),
      provenance = prov
    ))
  }

  if (!report) {
    chosen <- .get_method(route$method)
    return(cd_result(
      method = route$method, method_name = chosen@name,
      family = chosen@family, language = chosen@language,
      output = chosen@output,
      status = "recommendation only (report = FALSE)",
      rationale = route$rationale, confidence = route$confidence,
      alternatives = as.list(alt), provenance = prov
    ))
  }

  # Consensus mode --------------------------------------------------------
  # Run the top installed methods on the route and combine them; the member
  # results and the per-edge agreement ride in the provenance.
  if (identical(mode, "consensus")) {
    ids <- utils::head(route$alternatives[route$alternatives %in% available],
                       top_k)
    if (length(ids) == 0L) {
      ids <- route$method
    }
    runs <- lapply(ids, function(id) {
      m <- .get_method(id)
      .assemble_result(m@run(data), m, data)
    })
    comb <- .combine_consensus(runs, colnames(data))
    n_ok <- sum(vapply(runs, function(r) r@status == "ok", logical(1)))
    return(cd_result(
      graph = comb$amat, method = "consensus",
      method_name = sprintf("Consensus of %d methods", length(ids)),
      family = NA_character_, language = "R", output = "cpdag",
      status = "ok",
      rationale = sprintf("%s; consensus of %s", route$rationale,
                          paste(vapply(ids, .method_label, character(1)),
                                collapse = ", ")),
      confidence = route$confidence,
      alternatives = as.list(alt),
      provenance = c(prov, list(agreement = comb$agreement, n_ok = n_ok,
                                runs = runs))
    ))
  }

  m <- .get_method(route$method)
  res <- .assemble_result(m@run(data), m, data,
                          extra = list(features = f))
  res@rationale <- route$rationale
  res@confidence <- route$confidence
  res@alternatives <- as.list(alt)
  res
}
