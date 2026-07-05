# metrics.R -- Fair, convention-pinned scoring against a known truth.
#
# THE CONVENTION (estimates and truth alike, pcalg amat.cpdag):
#   amat[i, j] == 1 & amat[j, i] == 0   means   i -> j
#   amat[i, j] == 1 & amat[j, i] == 1   means   i -- j  (undirected / unoriented)
#
# Three metrics tell different, honest parts of the story: skeleton F1 (adjacency
# recovery, fair to every output type), structural Hamming distance (rewards
# correct orientation; an unoriented edge that the truth directs is a half-right
# answer that pays one move), and orientation recall (of the true arrows, the
# share correctly directed). The metrics are computed in base R so scoring needs
# no discovery back-end installed.

#' Edge state of a variable pair in amat.cpdag convention
#'
#' @param a An adjacency matrix.
#' @param i,j Variable indices, `i < j`.
#' @returns 0 (none), 1 (i -> j), 2 (j -> i), or 3 (undirected).
#' @noRd
#' @keywords internal
.edge_state <- function(a, i, j) {
  a_ij <- a[i, j] != 0
  a_ji <- a[j, i] != 0
  if (!a_ij && !a_ji) {
    0L
  } else if (a_ij && a_ji) {
    3L
  } else if (a_ij) {
    1L
  } else {
    2L
  }
}

#' Undirected-skeleton confusion against the truth
#'
#' @param est,truth Adjacency matrices in `amat.cpdag` convention.
#' @returns A list with `precision`, `recall`, `f1`, `tp`, `fp`, and `fn`.
#' @noRd
#' @keywords internal
.skeleton_scores <- function(est, truth) {
  ix <- upper.tri(truth)
  ut <- ((truth + t(truth)) > 0)
  ue <- ((est + t(est)) > 0)
  tp <- sum(ue[ix] & ut[ix])
  fp <- sum(ue[ix] & !ut[ix])
  fn <- sum(!ue[ix] & ut[ix])
  prec <- if (tp + fp > 0) tp / (tp + fp) else NA_real_
  rec <- if (tp + fn > 0) tp / (tp + fn) else NA_real_
  f1 <- if (is.na(rec)) {
    NA_real_ # the truth has no edges, so recall (and F1) is undefined
  } else if (is.na(prec)) {
    0 # an empty estimate against a non-empty truth misses everything
  } else if (prec + rec > 0) {
    2 * prec * rec / (prec + rec)
  } else {
    0
  }
  list(precision = prec, recall = rec, f1 = f1, tp = tp, fp = fp, fn = fn)
}

#' Structural Hamming distance between two partially-directed graphs
#'
#' Counts the variable pairs whose edge state (none, one of the two directions,
#' or undirected) differs between the estimate and the truth -- the number of
#' single-edge edits (insert, delete, or reorient) that reconcile them.
#'
#' @param est,truth Adjacency matrices in `amat.cpdag` convention.
#' @returns A single integer.
#' @noRd
#' @keywords internal
.shd_pdag <- function(est, truth) {
  p <- nrow(truth)
  d <- 0L
  for (i in seq_len(p)) {
    for (j in seq_len(p)) {
      if (i >= j) {
        next
      }
      if (.edge_state(est, i, j) != .edge_state(truth, i, j)) {
        d <- d + 1L
      }
    }
  }
  d
}

#' Orientation recall: share of true arrows correctly directed
#'
#' @param est,truth Adjacency matrices in `amat.cpdag` convention.
#' @returns A single number in `[0, 1]`, or `NA` when the truth has no directed
#'   edge.
#' @noRd
#' @keywords internal
.orient_recall <- function(est, truth) {
  p <- nrow(truth)
  correct <- 0L
  total <- 0L
  for (i in seq_len(p)) {
    for (j in seq_len(p)) {
      if (i == j) {
        next
      }
      true_ij <- truth[i, j] == 1 && truth[j, i] == 0
      if (true_ij) {
        total <- total + 1L
        if (est[i, j] == 1 && est[j, i] == 0) {
          correct <- correct + 1L
        }
      }
    }
  }
  if (total == 0L) NA_real_ else correct / total
}

#' Align an estimate to the truth's variable order
#'
#' @param est An estimate adjacency matrix (possibly empty).
#' @param truth The truth adjacency matrix.
#' @returns `est` reordered to the truth's labels, or a zero matrix of the
#'   truth's size when `est` is empty.
#' @noRd
#' @keywords internal
.align_amat <- function(est, truth) {
  p <- nrow(truth)
  if (length(est) == 0L) {
    return(matrix(0, p, p, dimnames = dimnames(truth)))
  }
  lab_t <- colnames(truth)
  lab_e <- colnames(est)
  if (!is.null(lab_t) && !is.null(lab_e) && all(lab_t %in% lab_e)) {
    est <- est[lab_t, lab_t, drop = FALSE]
  }
  est
}

#' Score a recovered graph against a known truth
#'
#' Compares a discovery result -- a [cd_result] or a bare adjacency matrix -- with
#' the true graph and returns the skeleton, distance, and orientation metrics. The
#' truth is typically the `truth` element of a [cd_scenario()].
#'
#' Both matrices are normalised before scoring, so any non-zero entry counts as
#' an edge mark and the three metrics see the same graph whether the input is
#' 0/1 or weighted. When the estimate carries no dimnames but matches the
#' truth's dimensions, it is scored positionally against the truth's variable
#' order.
#'
#' @param x A [cd_result] or a square adjacency matrix in `amat.cpdag`
#'   convention.
#' @param truth The true graph in `amat.cpdag` convention (for example
#'   `cd_scenario(...)$truth`).
#' @returns A one-row data frame with `skeleton_f1`, `skeleton_precision`,
#'   `skeleton_recall`, `shd`, and `orient_recall`. `skeleton_f1` is `NA` when
#'   the truth has no edges (recall is undefined there); an empty estimate
#'   against a non-empty truth scores 0.
#' @seealso [cd_scenario()], [cd_benchmark()]
#' @export
#' @examples
#' if (requireNamespace("pcalg", quietly = TRUE)) {
#'   sim <- cd_scenario("linear_gaussian", seed = 1)
#'   res <- cd_discover(sim$data, "pc_pcalg")
#'   cd_score(res, sim$truth)
#' }
cd_score <- function(x, truth) {
  est <- if (S7::S7_inherits(x, cd_result)) x@graph else x
  if (!is.matrix(truth) || nrow(truth) != ncol(truth)) {
    stop(call. = FALSE, "`truth` must be a square adjacency matrix.")
  }
  est <- .align_amat(est, truth)
  if (!all(dim(est) == dim(truth))) {
    return(data.frame(
      skeleton_f1 = NA_real_, skeleton_precision = NA_real_,
      skeleton_recall = NA_real_, shd = NA_real_, orient_recall = NA_real_,
      stringsAsFactors = FALSE
    ))
  }
  # any non-zero entry is an edge mark, so the skeleton, distance, and
  # orientation metrics all see the same graph for weighted input
  est <- (est != 0) * 1
  truth <- (truth != 0) * 1
  ss <- .skeleton_scores(est, truth)
  data.frame(
    skeleton_f1 = ss$f1,
    skeleton_precision = ss$precision,
    skeleton_recall = ss$recall,
    shd = .shd_pdag(est, truth),
    orient_recall = .orient_recall(est, truth),
    stringsAsFactors = FALSE
  )
}
