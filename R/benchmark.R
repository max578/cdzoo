# benchmark.R -- Run the registry across the scenario grid and score it.

.COST_RANK <- c(fast = 1L, medium = 2L, slow = 3L, very_slow = 4L)

#' Benchmark discovery methods across the scenario grid
#'
#' Runs each installed method across the chosen scenarios and seeds, scores
#' every run against the scenario's known truth with [cd_score()], and returns
#' the per-run results as a tidy data frame. Each run is isolated, so a back-end
#' that errors on a cell records a failed status rather than stopping the
#' benchmark.
#'
#' The default skips methods costlier than `cost_limit` so a first pass is
#' quick; raise the limit to include the slower kernel and search methods. With
#' no back-end installed the result has zero rows. A requested method that
#' cannot run is dropped with a warning naming it and the reason (an unknown id,
#' an absent back-end, or a cost above the limit) -- never silently.
#'
#' @param methods A character vector of method ids to run, or `NULL` (the
#'   default) for every installed method.
#' @param scenarios A character vector of scenario names, or `NULL` (the
#'   default) for all of them.
#' @param seeds An integer vector of seeds; each scenario is realised once per
#'   seed.
#' @param cost_limit A single string: the costliest method tier to include, one
#'   of `"fast"`, `"medium"`, `"slow"`, or `"very_slow"`.
#' @param verbose A single logical: report progress per scenario.
#' @param mc.cores A single positive integer: the number of cores to run the
#'   grid on. The default `1L` runs serially. Each cell is deterministic given
#'   its scenario seed and independent of the others, so the result is identical
#'   for any core count; parallel execution uses [parallel::mclapply()] (which
#'   falls back to serial on Windows).
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
                         verbose = TRUE, mc.cores = 1L) {
  cost_limit <- match.arg(cost_limit)
  limit <- .COST_RANK[[cost_limit]]
  if (length(mc.cores) != 1L || !is.finite(mc.cores) || mc.cores < 1) {
    stop(call. = FALSE, "`mc.cores` must be a single positive integer.")
  }

  # Resolve the method and scenario sets -----------------------------------
  if (is.null(scenarios)) {
    scenarios <- cd_scenarios()$name
  }
  available <- .available_method_ids()

  # Resolve the method set. A requested id that drops out -- unknown, back-end
  # not installed, or over the cost limit -- is named, never silently vanished.
  requested <- !is.null(methods)
  if (!requested) {
    # the default grid runs the data methods; the sufficient-statistic methods
    # reduce to the same computation as their data-method twin on a raw matrix,
    # so they are excluded here to keep the grid free of near-duplicates (ask
    # for them by id to include them).
    methods <- Filter(
      function(id) !identical(.get_method(id)@accepts, "suffstat"), available)
  } else {
    unknown <- Filter(function(id) is.null(.get_method(id)), methods)
    if (length(unknown) > 0L) {
      warning(call. = FALSE, "Dropping unknown method id(s): ",
              paste(unknown, collapse = ", "),
              ". See list_methods()$id for the registered methods.")
    }
    uninstalled <- setdiff(setdiff(methods, unknown), available)
    if (length(uninstalled) > 0L) {
      warning(call. = FALSE,
              "Dropping method(s) whose back-end is not installed: ",
              paste(uninstalled, collapse = ", "), ".")
    }
    methods <- intersect(methods, available)
  }
  capped <- Filter(function(id) {
    .COST_RANK[[.get_method(id)@cost]] > limit
  }, methods)
  if (length(capped) > 0L) {
    if (requested) {
      warning(call. = FALSE, "Dropping requested method(s) over the '",
              cost_limit, "' cost limit: ", paste(capped, collapse = ", "),
              ". Raise `cost_limit` to include them.")
    } else if (verbose) {
      message(sprintf("skipping %s over the '%s' cost limit",
                      paste(capped, collapse = ", "), cost_limit))
    }
  }
  methods <- setdiff(methods, capped)

  # Run and score the grid -------------------------------------------------
  # Every (scenario, seed, method) cell runs in isolation and is deterministic
  # given its scenario seed, so a back-end that errors on a cell records a
  # failed status rather than stopping the sweep, and the cells may run in any
  # order (serially, or across cores) with an identical result.
  if (length(methods) == 0L) {
    return(.empty_benchmark())
  }
  grid <- expand.grid(method = methods, seed = seeds, scenario = scenarios,
                      KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)
  if (verbose) {
    for (sc in scenarios) {
      message(sprintf("scenario %s (%d method(s), %d seed(s))",
                      sc, length(methods), length(seeds)))
    }
  }
  cell <- function(k) {
    .benchmark_cell(grid$scenario[k], grid$seed[k], grid$method[k])
  }
  rows <- if (mc.cores > 1L) {
    parallel::mclapply(seq_len(nrow(grid)), cell,
                       mc.cores = as.integer(mc.cores))
  } else {
    lapply(seq_len(nrow(grid)), cell)
  }
  do.call(rbind, rows)
}

#' Run and score one benchmark cell
#'
#' @param sc A scenario name.
#' @param seed A single seed.
#' @param id A method id.
#' @returns A one-row data frame in the benchmark schema.
#' @noRd
#' @keywords internal
.benchmark_cell <- function(sc, seed, id) {
  sim <- cd_scenario(sc, seed = seed)
  m <- .get_method(id)
  run <- tryCatch(m@run(.method_input(m, sim$data)),
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
  data.frame(
    scenario = sc, family = sim$family, method = id,
    method_family = m@family, language = m@language, seed = seed,
    status = run$status, skeleton_f1 = sc_row$skeleton_f1,
    shd = sc_row$shd, orient_recall = sc_row$orient_recall,
    runtime_s = as.double(run$runtime_s), stringsAsFactors = FALSE
  )
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
