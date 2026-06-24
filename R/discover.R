# discover.R -- Run one registered method on a data set.

#' Validate and normalise a data matrix
#'
#' @param data A numeric matrix or data frame of observations (rows) by
#'   variables (columns).
#' @returns A numeric matrix with column names, validated.
#' @noRd
#' @keywords internal
.validate_data <- function(data) {
  if (is.data.frame(data)) {
    if (!all(vapply(data, is.numeric, logical(1)))) {
      stop(call. = FALSE, "`data` must contain only numeric columns.")
    }
    data <- as.matrix(data)
  }
  if (!is.matrix(data) || !is.numeric(data)) {
    stop(call. = FALSE, "`data` must be a numeric matrix or data frame.")
  }
  if (ncol(data) < 2L) {
    stop(call. = FALSE, "`data` must have at least two variables (columns).")
  }
  if (nrow(data) < 5L) {
    stop(call. = FALSE, "`data` must have at least five observations (rows).")
  }
  if (any(!is.finite(data))) {
    stop(call. = FALSE,
         "`data` must not contain missing or non-finite values.")
  }
  if (is.null(colnames(data))) {
    colnames(data) <- paste0("x", seq_len(ncol(data)))
  }
  storage.mode(data) <- "double"
  data
}

#' Coerce a back-end estimate to the canonical adjacency matrix
#'
#' @param amat A matrix or `NULL`.
#' @param labels The variable names.
#' @returns A square double matrix in `amat.cpdag` convention, or an empty
#'   matrix when `amat` is `NULL`.
#' @noRd
#' @keywords internal
.coerce_amat <- function(amat, labels) {
  if (is.null(amat) || length(amat) == 0L) {
    return(matrix(numeric(0), 0L, 0L))
  }
  amat[!is.finite(amat)] <- 0
  storage.mode(amat) <- "double"
  if (is.null(dimnames(amat))) {
    dimnames(amat) <- list(labels, labels)
  }
  amat
}

#' Assemble a result from a back-end run
#'
#' @param res The list returned by a [cd_method]'s `run` adapter.
#' @param method The [cd_method] that produced it.
#' @param data The data matrix it was run on.
#' @param extra A list of extra provenance fields.
#' @returns A [cd_result].
#' @noRd
#' @keywords internal
.assemble_result <- function(res, method, data, extra = list()) {
  amat <- .coerce_amat(res$amat, colnames(data))
  cd_result(
    graph = amat,
    method = method@id,
    method_name = method@name,
    family = method@family,
    language = method@language,
    output = method@output,
    runtime_s = as.double(res$runtime_s %||% NA_real_),
    status = res$status %||% "ok",
    provenance = c(list(n = nrow(data), p = ncol(data)), extra)
  )
}

#' Discover a causal graph with one method
#'
#' Runs a single registered discovery method on a data set and returns the
#' recovered graph as a [cd_result]. Use [list_methods()] to see the registered
#' methods and which back-ends are installed, and [cd_auto()] to let the
#' recommender choose a method for you.
#'
#' @param data A numeric matrix or data frame of observations (rows) by
#'   variables (columns).
#' @param method A single string: the id of a registered method (see
#'   [list_methods()]).
#' @returns A [cd_result]. When the back-end raises an error, the result carries
#'   an empty graph and the error in its `status`; an absent back-end is a hard
#'   error pointing at the package or module to install.
#' @seealso [cd_auto()], [list_methods()], [cd_score()]
#' @export
#' @examples
#' if (requireNamespace("pcalg", quietly = TRUE)) {
#'   sim <- cd_scenario("linear_gaussian", seed = 1)
#'   res <- cd_discover(sim$data, "pc_pcalg")
#'   res
#' }
cd_discover <- function(data, method) {
  data <- .validate_data(data)
  if (length(method) != 1L || !is.character(method)) {
    stop(call. = FALSE, "`method` must be a single method id string.")
  }
  m <- .get_method(method)
  if (is.null(m)) {
    stop(call. = FALSE, sprintf(
      "Unknown method '%s'. See list_methods()$id for the registered methods.",
      method
    ))
  }
  if (!isTRUE(tryCatch(m@available(), error = function(e) FALSE))) {
    stop(call. = FALSE, sprintf(
      paste0("Method '%s' needs a back-end that is not available in this ",
             "session (%s, %s). Install it and retry."),
      m@id, m@language, m@name
    ))
  }
  res <- m@run(data)
  .assemble_result(res, m, data)
}

# null-coalescing helper.
`%||%` <- function(x, y) if (is.null(x)) y else x
