# cd-method.R -- The method specification.
#
# A cd_method bundles the metadata the recommender reads with the adapter that
# runs a back-end algorithm and returns its estimate in the shared adjacency
# convention. Methods live in a package-level registry; the built-ins are added
# at load time and users add their own with register_method().

#' A causal-discovery method specification
#'
#' Bundles the metadata that drives selection -- family, language, native output
#' type, cost, and assumptions -- with the adapter that runs a back-end
#' algorithm on a data matrix and returns its estimate in the shared
#' `amat.cpdag` convention. The `available` predicate reports whether the
#' back-end can run in the current session, so a method whose package or Python
#' module is absent is skipped rather than failing.
#'
#' @param id A single string identifying the method; this is the value passed to
#'   `method =` in [cd_discover()].
#' @param name A single string giving the human-readable method name.
#' @param family A single string naming the algorithm family, one of
#'   `"constraint"`, `"score"`, `"functional"`, `"continuous_optim"`,
#'   `"hybrid"`, or `"density"`.
#' @param language A single string, `"R"` or `"Python"`.
#' @param output A single string giving the native output type, one of `"dag"`,
#'   `"cpdag"`, or `"pag"`.
#' @param citation A single string citing the method's source.
#' @param cost A single string giving the rough computational cost, one of
#'   `"fast"`, `"medium"`, `"slow"`, or `"very_slow"`.
#' @param assumptions A single string describing the method's modelling
#'   assumptions.
#' @param accepts A single string naming the input the method's `run` consumes,
#'   `"data"` (the default; a numeric observation matrix) or `"suffstat"` (a
#'   sufficient statistic, the list `list(C, n)` of a correlation matrix and its
#'   sample size). A `"suffstat"` method can still be called on a data matrix --
#'   [cd_discover()] reduces the data to its sufficient statistic first.
#' @param available A function of no arguments returning a single logical: can
#'   the method run in the current session?
#' @param run A function taking the method's input (a numeric data matrix, or a
#'   `list(C, n)` sufficient statistic when `accepts = "suffstat"`) and
#'   returning a list with elements `amat` (the estimate in `amat.cpdag`
#'   convention, or `NULL`), `runtime_s`, and `status`.
#'
#' @returns An S7 object of class `cd_method`.
#' @family registry
#' @export
#' @examples
#' cd_method(
#'   id = "demo", name = "Demo", family = "constraint",
#'   available = function() TRUE,
#'   run = function(data) list(amat = NULL, runtime_s = 0, status = "ok")
#' )
cd_method <- S7::new_class(
  name = "cd_method",
  package = "cdzoo",
  properties = list(
    id = S7::class_character,
    name = S7::new_property(S7::class_character, default = ""),
    family = S7::new_property(S7::class_character, default = "constraint"),
    language = S7::new_property(S7::class_character, default = "R"),
    output = S7::new_property(S7::class_character, default = "cpdag"),
    citation = S7::new_property(S7::class_character, default = ""),
    cost = S7::new_property(S7::class_character, default = "fast"),
    assumptions = S7::new_property(S7::class_character, default = ""),
    accepts = S7::new_property(S7::class_character, default = "data"),
    available = S7::class_function,
    run = S7::class_function
  ),
  validator = function(self) {
    if (length(self@id) != 1L || is.na(self@id) || !nzchar(self@id)) {
      return("`id` must be a single non-empty string")
    }
    ok_family <- c("constraint", "score", "functional", "continuous_optim",
                   "hybrid", "density")
    if (!self@family %in% ok_family) {
      return(paste0("`family` must be one of ",
                    paste(ok_family, collapse = ", ")))
    }
    ok_cost <- c("fast", "medium", "slow", "very_slow")
    if (!self@cost %in% ok_cost) {
      return(paste0("`cost` must be one of ", paste(ok_cost, collapse = ", ")))
    }
    if (!self@accepts %in% c("data", "suffstat")) {
      return("`accepts` must be either \"data\" or \"suffstat\"")
    }
    NULL
  }
)

#' @export
S7::method(print, cd_method) <- function(x, ...) {
  cat(sprintf("<cd_method '%s'>: %s [%s, %s]\n",
              x@id, if (nzchar(x@name)) x@name else x@id,
              x@family, x@language))
  cat(sprintf("  output     : %s\n", x@output))
  cat(sprintf("  cost       : %s\n", x@cost))
  if (!identical(x@accepts, "data")) {
    cat(sprintf("  accepts    : %s\n", x@accepts))
  }
  cat(sprintf("  available  : %s\n",
              if (isTRUE(tryCatch(x@available(), error = function(e) FALSE))) {
                "yes"
              } else {
                "no (back-end not installed)"
              }))
  if (nzchar(x@assumptions)) {
    cat(sprintf("  assumptions: %s\n", x@assumptions))
  }
  invisible(x)
}
