# manifest.R -- the federation contract-emitting result adapter.
#
# A recovered causal graph must be expressible in the shared, versioned, hashed,
# provenance-complete manifest contract that members of the federation emit and
# consume. This file carries a stand-in `orchestra_manifest` class whose
# property names and integrity hash match the canonical reference implementation
# field for field, so a consumer reads a cdzoo manifest with no special casing.
# The contract is defined here (rather than depended on) because the canonical
# implementation lives in the composition layer, not an installable package.
#
# A recovered graph is, in the contract's terms, an inferred STRUCTURE -- not a
# parameter vector, a prediction, or a decision -- so the emit target is
# "structure". The recovered edges ride in `params` as a tidy edge list; the
# method, family, routing rationale, and -- the carefully-provisioned honesty --
# the routing confidence and whether the result is a single method or a
# consensus ride in the typed `summary` and `metadata`, so a downstream consumer
# always knows how the graph was obtained and how sure the recommender was. The
# payload is integrity-hashed so a tampered graph is detected.

# The manifest schema version this member emits. Tracks the reference
# implementation; bump only with an additive (x.y) or breaking (x.0) change
# there. 2.0.0 (2026-07-05): the integrity hash is computed over version-stable
# bytes (format-2 serialisation, 14-byte header dropped), so a manifest emitted
# under one R version verifies under any other; manifests emitted before this
# change no longer verify and must be re-emitted.
MANIFEST_VERSION <- "2.0.0-draft"

# The inferential-target enum, kept identical to the reference contract so a
# consumer's dispatch never sees an unknown token. "structure" was added (an
# additive, non-breaking extension, like the genomics tokens before it) for a
# recovered causal graph -- the inference cdzoo produces.
.INFERENTIAL_TARGETS <- c("parameters", "predictions",
                          "treatment_effects", "decisions",
                          "breeding_values", "marker_associations",
                          "structure")

#' Payload integrity hash matching the federation contract
#'
#' SHA-256 over the load-bearing data slots only (the schema, version and
#' timestamp are metadata and are not hashed). The `"sha256:"` prefix and the
#' slot ordering match the reference implementation so a manifest hashed by
#' cdzoo verifies under the federation's `verify_manifest()`.
#'
#' Serialisation is pinned to format 2 and its fixed 14-byte header (magic,
#' format, writer/minimum R versions) is dropped before hashing: those bytes are
#' the only version-varying part, so a manifest emitted under one R version
#' verifies under any other. Matches the reference implementation byte for byte.
#'
#' @param params,outputs,weights,obs_target,seed,summary The load-bearing slots.
#' @returns A single `"sha256:"`-prefixed hex string.
#' @noRd
#' @keywords internal
.hash_payload <- function(params, outputs, weights, obs_target, seed,
                          summary = NULL) {
  obj <- list(params, outputs, weights, obs_target, seed, summary)
  raw <- serialize(obj, connection = NULL, version = 2L)
  paste0("sha256:", digest::digest(raw[-seq_len(14L)], algo = "sha256",
                                   serialize = FALSE))
}

#' A typed home for a discovery verdict (contract v1.1)
#'
#' Mirrors the reference contract's `manifest_summary()`: the result's headline
#' label, an abstain flag (set when no graph was recovered), and a list of key
#' metrics. Integrity-hashed with the rest of the payload.
#'
#' @param headline A single non-empty status string.
#' @param abstained A single logical; `TRUE` when the result is not a recovered
#'   graph (for example a recommendation made with no back-end installed).
#' @param metrics A named list of scalar metrics.
#' @param abstain_reason A single string, or `NA`.
#' @returns A classed `manifest_summary` list.
#' @noRd
#' @keywords internal
manifest_summary <- function(headline, abstained = FALSE, metrics = list(),
                             abstain_reason = NA_character_) {
  if (!is.character(headline) || length(headline) != 1L || !nzchar(headline)) {
    stop(call. = FALSE, "`headline` must be a single non-empty string.")
  }
  if (!is.logical(abstained) || length(abstained) != 1L) {
    stop(call. = FALSE, "`abstained` must be a single logical.")
  }
  if (!is.list(metrics)) {
    stop(call. = FALSE, "`metrics` must be a list.")
  }
  structure(list(headline = headline, abstained = isTRUE(abstained),
                 abstain_reason = abstain_reason, metrics = metrics),
            class = "manifest_summary")
}

#' The federation manifest contract (cdzoo-side implementation)
#'
#' A versioned, hashed, provenance-complete S7 result object,
#' property-compatible with the federation's reference `orchestra_manifest`. A
#' [cd_result] is adapted into one through [as_orchestra_manifest()]: the
#' recovered edges ride in `params` (`inferential_target = "structure"`), the
#' method, routing rationale, confidence, and consensus flag ride in `metadata`
#' and the typed `summary`, and the payload is integrity-hashed so a tampered
#' graph is detected downstream.
#'
#' @usage NULL
#' @returns An S7 object of class `orchestra_manifest`.
#' @seealso [as_orchestra_manifest()], [verify_manifest()]
#' @examples
#' g <- matrix(0, 2, 2, dimnames = list(c("x", "y"), c("x", "y")))
#' g["x", "y"] <- 1
#' m <- as_orchestra_manifest(cd_result(graph = g, method = "demo"))
#' m@inferential_target
#' m@summary$abstained
#' verify_manifest(m)$ok
#' @export
orchestra_manifest <- S7::new_class(
  "orchestra_manifest",
  package = "cdzoo",
  properties = list(
    manifest_version   = S7::new_property(S7::class_character,
                                          default = MANIFEST_VERSION),
    emitter_package    = S7::class_character,
    emitter_version    = S7::class_character,
    inferential_target = S7::class_character,
    run_id             = S7::class_character,
    method             = S7::class_character,
    seed               = S7::new_property(S7::class_integer,
                                          default = NA_integer_),
    params             = S7::new_property(S7::class_data.frame,
                                          default = data.frame()),
    outputs            = S7::new_property(S7::class_any, default = NULL),
    weights            = S7::new_property(S7::class_any, default = NULL),
    obs_target         = S7::new_property(S7::class_any, default = NULL),
    obs_schema         = S7::new_property(S7::class_any, default = NULL),
    summary            = S7::new_property(S7::class_any, default = NULL),
    consumed_manifests = S7::new_property(S7::class_list, default = list()),
    metadata           = S7::new_property(S7::class_list, default = list()),
    timestamp          = S7::class_POSIXct,
    data_hash          = S7::class_character
  ),
  validator = function(self) {
    errs <- character(0)
    if (length(self@run_id) != 1L || !nzchar(self@run_id)) {
      errs <- c(errs, "`run_id` must be a single non-empty string")
    }
    if (length(self@inferential_target) != 1L ||
        !self@inferential_target %in% .INFERENTIAL_TARGETS) {
      errs <- c(errs, sprintf("`inferential_target` must be one of %s",
                              paste(.INFERENTIAL_TARGETS, collapse = ", ")))
    }
    if (length(self@data_hash) != 1L) {
      errs <- c(errs, "`data_hash` must be a single string")
    }
    if (!is.null(self@summary) && !inherits(self@summary, "manifest_summary")) {
      errs <- c(errs, "`summary`, when set, must be a manifest_summary() object")
    }
    if (length(errs) == 0L) NULL else paste(errs, collapse = "; ")
  }
)

#' Verify a manifest's payload integrity
#'
#' Recomputes the payload hash from the object's own load-bearing slots and
#' compares it to the stored `data_hash`. A mismatch means the payload was
#' modified after emission. Matches the reference contract's
#' `verify_manifest()`.
#'
#' @param m An `orchestra_manifest` object.
#' @returns A list with logical `ok` and a human-readable `message`.
#' @seealso [as_orchestra_manifest()]
#' @export
#' @examples
#' g <- matrix(c(0, 0, 1, 0), 2, 2,
#'             dimnames = list(c("x1", "x2"), c("x1", "x2")))
#' m <- as_orchestra_manifest(cd_result(graph = g, method = "demo"))
#' verify_manifest(m)
verify_manifest <- function(m) {
  if (!S7::S7_inherits(m, orchestra_manifest)) {
    return(list(ok = FALSE, message = "not an orchestra_manifest"))
  }
  recomputed <- .hash_payload(m@params, m@outputs, m@weights,
                              m@obs_target, m@seed, m@summary)
  ok <- identical(recomputed, m@data_hash)
  list(ok = ok,
       message = if (ok) "data_hash verified"
                 else "data_hash MISMATCH -- manifest payload was modified")
}

#' Emit a discovery result as a federation manifest
#'
#' The federation's emit / adapt generic. The [cd_result] method turns a
#' recovered graph into the shared `orchestra_manifest` contract:
#' `inferential_target = "structure"`, the recovered edges carried as a tidy
#' `params` edge list, and the provenance -- which method ran, the routing
#' rationale, the routing confidence, and whether the result is a single method
#' or a consensus -- in the typed `summary` and `metadata`. The full adjacency
#' matrix (and, for a consensus, the per-edge agreement) rides in `metadata` for
#' a consumer that wants the matrix rather than the edge list. When no graph was
#' recovered (an absent back-end), the manifest abstains and says so. The
#' payload is integrity-hashed so a consumer can verify it with
#' [verify_manifest()].
#'
#' @param x A [cd_result].
#' @param ... Further arguments passed to methods. The [cd_result] method
#' accepts `run_id` (an optional character run identifier; a content hash is
#' derived
#' when omitted, so two identical results get the same identifier) and `seed`
#' (an optional integer recorded for reproducibility).
#' @returns An `orchestra_manifest` S7 object.
#' @seealso [verify_manifest()], [cd_auto()], [cd_discover()]
#' @export
#' @examples
#' g <- matrix(c(0, 0, 1, 0), 2, 2,
#'             dimnames = list(c("x1", "x2"), c("x1", "x2")))
#' as_orchestra_manifest(cd_result(graph = g, method = "demo",
#'                                 method_name = "Demo", family = "constraint"))
as_orchestra_manifest <- S7::new_generic("as_orchestra_manifest", "x")

S7::method(as_orchestra_manifest, cd_result) <-
  function(x, ..., run_id = NULL, seed = NA_integer_) {
    edges <- cd_edges(x)
    ec <- .edge_counts(x@graph)
    recovered <- identical(x@status, "ok") && length(x@graph) > 0L
    label <- if (nzchar(x@method_name)) x@method_name else x@method
    consensus <- identical(x@method, "consensus")
    p <- if (length(x@graph) > 0L) nrow(x@graph) else NA_integer_

    summ <- manifest_summary(
      headline = if (recovered) {
        sprintf("%d edges (%d directed, %d undirected) via %s",
                nrow(edges), ec$directed, ec$undirected, label)
      } else {
        sprintf("no graph recovered (%s)", x@status)
      },
      abstained = !recovered,
      abstain_reason = if (!recovered) x@status else NA_character_,
      metrics = list(
        method        = x@method,
        family        = x@family,
        language      = x@language,
        n_edges       = nrow(edges),
        n_directed    = ec$directed,
        n_undirected  = ec$undirected,
        confidence    = x@confidence,
        consensus     = consensus,
        p             = p))

    meta <- list(
      derived      = FALSE,
      method       = x@method,
      family       = x@family,
      language     = x@language,
      output       = x@output,
      rationale    = x@rationale,
      confidence   = x@confidence,
      consensus    = consensus,
      # the full adjacency for a consumer that wants the matrix, not the edge
      # list
      amat         = if (length(x@graph) > 0L) x@graph else NULL,
      agreement    = x@provenance$agreement,
      alternatives = x@alternatives)

    ev <- as.character(utils::packageVersion("cdzoo"))
    seed <- as.integer(seed)
    dh <- .hash_payload(edges, NULL, NULL, NULL, seed, summ)
    rid <- run_id %||%
      paste0("cdzoo-", substr(sub("^sha256:", "", dh), 1L, 12L))

    orchestra_manifest(
      manifest_version   = MANIFEST_VERSION,
      emitter_package    = "cdzoo",
      emitter_version    = ev,
      inferential_target = "structure",
      run_id             = rid,
      method             = paste0("cdzoo:", x@method),
      seed               = seed,
      params             = edges,
      summary            = summ,
      consumed_manifests = list(),
      metadata           = meta,
      timestamp          = Sys.time(),
      data_hash          = dh)
  }
