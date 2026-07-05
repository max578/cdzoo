# explain.R -- A human-readable account of a recommendation.
#
# print(cd_result) is a compact one-screen summary; cd_explain() is the fuller
# narrative a user reads to understand and audit a recommendation: which method
# ran and why, how sure the recommender is, what else it considered, the
# thresholds that decided the route, and -- for a consensus -- how much the
# methods agreed.

#' Explain a discovery recommendation in words
#'
#' Prints a readable account of a [cd_result]: the method that ran and its
#' status, the routing rationale and confidence, the alternatives the
#' recommender considered, the data-characteristic thresholds that decided the
#' route (when [cd_auto()] produced the result), and -- for a `"consensus"`
#' result -- the per-edge agreement among the combined methods. It is the
#' auditable companion to `print()`, which stays compact.
#'
#' @param x A [cd_result], typically from [cd_auto()].
#' @returns `x`, invisibly. Called for the account it prints.
#' @seealso [cd_auto()], [cd_result], [cd_edges()]
#' @export
#' @examples
#' if (requireNamespace("pcalg", quietly = TRUE)) {
#'   sim <- cd_scenario("linear_laplace", seed = 1)
#'   cd_explain(cd_auto(sim$data, report = FALSE))
#' }
cd_explain <- function(x) {
  if (!S7::S7_inherits(x, cd_result)) {
    stop(call. = FALSE, "`x` must be a `cd_result`.")
  }
  label <- if (nzchar(x@method_name)) x@method_name else x@method

  # ---- Headline --------------------------------------------------------------
  cat(sprintf("Recommendation: %s\n", label))
  if (!is.na(x@family)) {
    cat(sprintf("  family    : %s (%s)\n", x@family, x@language))
  }
  cat(sprintf("  status    : %s\n", x@status))
  if (length(x@graph) > 0L) {
    ec <- .edge_counts(x@graph)
    cat(sprintf(
      "  graph     : %d variables, %d directed and %d undirected edges\n",
      nrow(x@graph), ec$directed, ec$undirected))
  }

  # ---- Why -------------------------------------------------------------------
  if (nzchar(x@rationale)) {
    cat("\nWhy this method:\n")
    cat(.cd_wrap(x@rationale, "  "), "\n", sep = "")
  }
  if (!is.na(x@confidence)) {
    cat(sprintf("\nConfidence: %s\n", x@confidence))
  }

  # ---- Alternatives ----------------------------------------------------------
  alts <- x@alternatives
  if (length(alts) > 0L) {
    labs <- vapply(alts, function(a) {
      if (is.character(a)) a else "<result>"
    }, character(1))
    cat("\nAlternatives considered (preference order):\n")
    cat(sprintf("  %s\n", paste(labs, collapse = ", ")))
  }

  # ---- Thresholds ------------------------------------------------------------
  thr <- x@provenance$thresholds
  if (is.list(thr) && length(thr) > 0L) {
    cat("\nRouting thresholds:\n")
    for (nm in names(thr)) {
      cat(sprintf("  %-22s %s\n", nm, format(thr[[nm]])))
    }
  }

  # ---- Consensus agreement ---------------------------------------------------
  agr <- x@provenance$agreement
  if (is.matrix(agr) && nrow(agr) > 0L) {
    ut <- agr[upper.tri(agr)]
    shared <- sum(ut >= 0.999)
    partial <- sum(ut > 0 & ut < 0.999)
    cat(sprintf(
      "\nConsensus: %d edge(s) found by every method, %d by some\n",
      shared, partial))
  }

  invisible(x)
}

#' Wrap a string to roughly 76 columns with a fixed indent
#'
#' @param text A single string.
#' @param indent A leading indent for every line.
#' @returns The wrapped, indented string (no trailing newline).
#' @noRd
#' @keywords internal
.cd_wrap <- function(text, indent = "") {
  wrapped <- strwrap(text, width = 76 - nchar(indent))
  paste0(indent, wrapped, collapse = "\n")
}
