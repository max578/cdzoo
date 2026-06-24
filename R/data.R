# data.R -- Documentation for the shipped data sets.

#' Field benchmark of causal-discovery methods across scenarios
#'
#' A summary of sixteen established causal-discovery methods run across the nine
#' structural-causal-model scenarios of [cd_scenarios()], each method scored
#' against the scenario's known DAG and averaged over random-graph seeds. It is
#' the evidence that grounds the routing preferences in [cd_auto()], and the
#' worked example in the package vignette.
#'
#' One row per (scenario, method). The kernel conditional-independence method
#' (`pc_kci_cl`) was not run on the ten-variable scenario, so that one
#' (scenario, method) cell is absent, giving 143 rows.
#'
#' @format A data frame with 143 rows and 11 columns:
#' \describe{
#'   \item{scenario}{Scenario name (see [cd_scenarios()]).}
#'   \item{scenario_family}{The scenario's structural-causal-model family.}
#'   \item{method}{Method id (see [list_methods()]).}
#'   \item{method_name}{Human-readable method name.}
#'   \item{family}{Algorithm family.}
#'   \item{shd}{Mean structural Hamming distance to the true DAG (lower is
#'     better).}
#'   \item{shd_sd}{Standard deviation of the structural Hamming distance across
#'     seeds.}
#'   \item{skeleton_f1}{Mean skeleton (adjacency) F1 (higher is better).}
#'   \item{orient_recall}{Mean orientation recall.}
#'   \item{runtime_s}{Mean wall-clock runtime in seconds.}
#'   \item{n_seed}{Number of random-graph seeds averaged.}
#' }
#' @seealso [cd_benchmark()], [cd_auto()], [cd_scenarios()]
#' @examples
#' # overall ranking by mean structural Hamming distance across scenarios
#' agg <- aggregate(shd ~ method_name, data = cd_field_benchmark, FUN = mean)
#' agg[order(agg$shd), ]
"cd_field_benchmark"
