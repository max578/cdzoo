# benchmark.R -- Run the registry across the scenario grid and score it.

.COST_RANK <- c(fast = 1L, medium = 2L, slow = 3L, very_slow = 4L)

#' Benchmark discovery methods across the scenario grid
#'
#' Runs each installed method across the chosen scenarios and seeds, scores every
#' run against the scenario's known truth with [cd_score()], and returns the
#' per-run results as a tidy data frame. Each run is isolated, so a back-end that
#' errors on a cell records a failed status rather than stopping the benchmark.
#'
#' The default skips methods costlier than `cost_limit` so a first pass is quick;
#' raise the limit to include the slower kernel and search methods. With no
#' back-end installed the result has zero rows.
#'
#' @param methods A character vector of method ids to run, or `NULL` (the
#'   default) for every installed method.
#' @param scenarios A character vector of scenario names, or `NULL` (the default)
#'   for all of them.
#' @param seeds An integer vector of seeds; each scenario is realised once per
#'   seed.
#' @param cost_limit A single string: the costliest method tier to include, one
#'   of `"fast"`, `"medium"`, `"slow"`, or `"very_slow"`.
#' @param verbose A single logical: report progress per scenario.
#' @returns A data frame with one row per (scenario, method, seed) run, with
#'   columns `scenario`, `family`, `method`, `method_family`, `language`,
#'   `seed`, `status`, `skeleton_f1`, `shd`, `orient_recall`, and `runtime_s`.
#' @seealso [cd_scenario()], [cd_score()], [list_methods()]
#' @export
#' @examples
#' if (requireNamespace("pcalg", quietly = TRUE)) {
#'   res <- cd_benchmark(
#'     methods = "pc_pcalg",
#'     scenarios = "linear_gaussian",
#'     seeds = 1:2, verbose = FALSE
#'   )
#'   res[, c("scenario", "method", "skeleton_f1", "shd")]
#' }
cd_benchmark <- function(methods = NULL, scenarios = NULL, seeds = 1:4,
                         cost_limit = c("medium", "fast", "slow", "very_slow"),
                         verbose = TRUE) {
  cost_limit <- match.arg(cost_limit)
  limit <- .COST_RANK[[cost_limit]]

  if (is.null(scenarios)) {
    scenarios <- cd_scenarios()$name
  }
  available <- .available_method_ids()
  if (is.null(methods)) {
    methods <- available
  } else {
    methods <- intersect(methods, available)
  }
  methods <- Filter(function(id) {
    .COST_RANK[[.get_method(id)@cost]] <= limit
  }, methods)

  rows <- vector("list", 0L)
  if (length(methods) == 0L) {
    return(.empty_benchmark())
  }

  for (sc in scenarios) {
    if (verbose) {
      message(sprintf("scenario %s (%d method(s), %d seed(s))",
                      sc, length(methods), length(seeds)))
    }
    for (seed in seeds) {
      sim <- cd_scenario(sc, seed = seed)
      for (id in methods) {
        m <- .get_method(id)
        run <- tryCatch(m@run(sim$data),
                        error = function(e) {
                          list(amat = NULL, runtime_s = NA_real_,
                               status = paste0("error: ", conditionMessage(e)))
                        })
        sc_row <- if (identical(run$status, "ok")) {
          cd_score(.coerce_amat(run$amat, colnames(sim$data)), sim$truth)
        } else {
          data.frame(skeleton_f1 = NA_real_, skeleton_precision = NA_real_,
                     skeleton_recall = NA_real_, shd = NA_real_,
                     orient_recall = NA_real_)
        }
        rows[[length(rows) + 1L]] <- data.frame(
          scenario = sc, family = sim$family, method = id,
          method_family = m@family, language = m@language, seed = seed,
          status = run$status, skeleton_f1 = sc_row$skeleton_f1,
          shd = sc_row$shd, orient_recall = sc_row$orient_recall,
          runtime_s = as.double(run$runtime_s), stringsAsFactors = FALSE
        )
      }
    }
  }
  do.call(rbind, rows)
}

#' Empty benchmark result
#'
#' @returns A zero-row benchmark data frame with the standard columns.
#' @noRd
#' @keywords internal
.empty_benchmark <- function() {
  data.frame(
    scenario = character(0), family = character(0), method = character(0),
    method_family = character(0), language = character(0), seed = integer(0),
    status = character(0), skeleton_f1 = numeric(0), shd = numeric(0),
    orient_recall = numeric(0), runtime_s = numeric(0),
    stringsAsFactors = FALSE
  )
}
