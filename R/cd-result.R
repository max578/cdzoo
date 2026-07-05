# cd-result.R -- The discovery-result object and its methods.
#
# A cd_result carries the recovered graph (a pcalg amat.cpdag-convention
# adjacency matrix), the method that produced it, timing and status, and -- when
# the result came from the recommender -- the routing rationale, a confidence
# label, and the alternatives that were considered.

#' A causal-discovery result
#'
#' The object returned by [cd_discover()] and [cd_auto()]. It holds the
#' recovered graph as an adjacency matrix in the `pcalg` `amat.cpdag`
#' convention, where
#' `graph[i, j] == 1` and `graph[j, i] == 0` encodes the directed edge
#' \eqn{i \rightarrow j}, and `graph[i, j] == graph[j, i] == 1` encodes an
#' undirected (unoriented) edge \eqn{i - j}.
#'
#' The `rationale`, `confidence`, and `alternatives` properties are populated by
#' [cd_auto()] and are empty for a single-method [cd_discover()] call.
#'
#' @param graph A square numeric adjacency matrix in the `amat.cpdag`
#'   convention, with variable names as dimnames; empty when the method failed.
#' @param method A single string: the identifier of the method that produced the
#'   result.
#' @param method_name A single string: the human-readable method name.
#' @param family A single string: the algorithm family (constraint, score,
#'   functional, continuous-optimisation, hybrid, or density).
#' @param language A single string: the back-end language, `"R"` or `"Python"`.
#' @param output A single string: the native output type, one of `"dag"`,
#'   `"cpdag"`, or `"pag"`.
#' @param runtime_s A single number: wall-clock runtime in seconds.
#' @param status A single string: `"ok"`, or a short error description.
#' @param rationale A single string: why the recommender chose this method.
#' @param confidence A single string: `"high"`, `"moderate"`, or `"low"`.
#' @param alternatives A list of method labels the recommender considered as
#'   alternatives, in its preference order.
#' @param provenance A list of call metadata (data characteristics, options).
#'
#' @returns An S7 object of class `cd_result`.
#' @family results
#' @export
#' @examples
#' g <- matrix(c(0, 0, 1, 0), 2, 2,
#'             dimnames = list(c("x1", "x2"), c("x1", "x2")))
#' cd_result(graph = g, method = "pc_pcalg", method_name = "PC (Fisher-Z)")
cd_result <- S7::new_class(
  name = "cd_result",
  package = "cdzoo",
  properties = list(
    graph = S7::class_double,
    method = S7::new_property(S7::class_character, default = NA_character_),
    method_name = S7::new_property(S7::class_character, default = ""),
    family = S7::new_property(S7::class_character, default = NA_character_),
    language = S7::new_property(S7::class_character, default = "R"),
    output = S7::new_property(S7::class_character, default = "cpdag"),
    runtime_s = S7::new_property(S7::class_double, default = NA_real_),
    status = S7::new_property(S7::class_character, default = "ok"),
    rationale = S7::new_property(S7::class_character, default = ""),
    confidence = S7::new_property(S7::class_character, default = NA_character_),
    alternatives = S7::new_property(S7::class_list, default = list()),
    provenance = S7::new_property(S7::class_list, default = list())
  ),
  validator = function(self) {
    g <- self@graph
    if (length(g) > 0L) {
      if (!is.matrix(g)) {
        return("`graph` must be a matrix")
      }
      if (nrow(g) != ncol(g)) {
        return("`graph` must be a square matrix")
      }
    }
    if (length(self@status) != 1L) {
      return("`status` must be a single string")
    }
    NULL
  }
)

#' Count directed and undirected edges in an adjacency matrix
#'
#' @param amat A square adjacency matrix in `amat.cpdag` convention.
#' @returns A list with integer `directed` and `undirected` counts.
#' @noRd
#' @keywords internal
.edge_counts <- function(amat) {
  if (length(amat) == 0L) {
    return(list(directed = 0L, undirected = 0L))
  }
  p <- nrow(amat)
  directed <- 0L
  undirected <- 0L
  for (i in seq_len(p)) {
    for (j in seq_len(p)) {
      if (i >= j) {
        next
      }
      a_ij <- amat[i, j] != 0
      a_ji <- amat[j, i] != 0
      if (a_ij && a_ji) {
        undirected <- undirected + 1L
      } else if (a_ij || a_ji) {
        directed <- directed + 1L
      }
    }
  }
  list(directed = directed, undirected = undirected)
}

#' @export
S7::method(print, cd_result) <- function(x, ...) {
  cat(sprintf(
    "<cd_result>: %s [%s, %s]\n",
    if (nzchar(x@method_name)) x@method_name else x@method,
    if (is.na(x@family)) "?" else x@family,
    x@language
  ))
  cat(sprintf("  status    : %s\n", x@status))
  if (length(x@graph) > 0L) {
    p <- nrow(x@graph)
    nm <- colnames(x@graph)
    shown <- if (is.null(nm)) "" else {
      sprintf(" (%s%s)", paste(utils::head(nm, 6L), collapse = ", "),
              if (p > 6L) ", ..." else "")
    }
    cat(sprintf("  variables : %d%s\n", p, shown))
    ec <- .edge_counts(x@graph)
    cat(sprintf("  edges     : %d directed, %d undirected\n",
                ec$directed, ec$undirected))
  }
  if (!is.na(x@runtime_s)) {
    cat(sprintf("  runtime   : %.3gs\n", x@runtime_s))
  }
  if (nzchar(x@rationale)) {
    cat(sprintf("  routed    : %s\n", x@rationale))
  }
  if (!is.na(x@confidence)) {
    cat(sprintf("  confidence: %s\n", x@confidence))
  }
  invisible(x)
}

#' Edge list of a discovery result
#'
#' Returns the edges of a [cd_result] (or a bare adjacency matrix) as a data
#' frame, one row per edge, with the orientation made explicit.
#'
#' @param x A [cd_result] or a square adjacency matrix in `amat.cpdag`
#'   convention.
#' @returns A data frame with columns `from`, `to`, and `type` (`"-->"` for a
#'   directed edge, `"---"` for an undirected one). Zero rows when the graph is
#'   empty.
#' @family results
#' @export
#' @examples
#' g <- matrix(c(0, 0, 1, 0), 2, 2,
#'             dimnames = list(c("x1", "x2"), c("x1", "x2")))
#' cd_edges(cd_result(graph = g, method = "demo"))
cd_edges <- function(x) {
  amat <- if (S7::S7_inherits(x, cd_result)) x@graph else x
  empty <- data.frame(
    from = character(0), to = character(0), type = character(0),
    stringsAsFactors = FALSE
  )
  if (length(amat) == 0L) {
    return(empty)
  }
  p <- nrow(amat)
  nm <- colnames(amat)
  if (is.null(nm)) {
    nm <- paste0("x", seq_len(p))
  }
  rows <- vector("list", 0L)
  for (i in seq_len(p)) {
    for (j in seq_len(p)) {
      if (i >= j) {
        next
      }
      a_ij <- amat[i, j] != 0
      a_ji <- amat[j, i] != 0
      if (a_ij && a_ji) {
        rows[[length(rows) + 1L]] <-
          data.frame(from = nm[i], to = nm[j], type = "---",
                     stringsAsFactors = FALSE)
      } else if (a_ij) {
        rows[[length(rows) + 1L]] <-
          data.frame(from = nm[i], to = nm[j], type = "-->",
                     stringsAsFactors = FALSE)
      } else if (a_ji) {
        rows[[length(rows) + 1L]] <-
          data.frame(from = nm[j], to = nm[i], type = "-->",
                     stringsAsFactors = FALSE)
      }
    }
  }
  if (length(rows) == 0L) {
    return(empty)
  }
  do.call(rbind, rows)
}
