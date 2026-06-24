# registry.R -- The method registry and its back-end adapters.
#
# Every algorithm is wrapped behind one interface and returns its estimate in a
# single convention, so it can be called for any discovery task or benchmark.
# Methods live in a package-level registry; the built-ins are added at load time
# and users add their own with register_method().
#
# OUTPUT CONVENTION (pcalg amat.cpdag, enforced + smoke-tested):
#   amat[i, j] == 1 & amat[j, i] == 0  =>  i -> j ;  both 1  =>  i -- j.

# The registry is a private environment keyed by method id.
.method_registry <- new.env(parent = emptyenv())

#' Register a discovery method
#'
#' Adds a [cd_method] to the registry so it can be run by [cd_discover()] and
#' considered by [cd_auto()]. Registering a method with the id of an existing one
#' replaces it.
#'
#' @param method A [cd_method] to register.
#' @returns The method id, invisibly.
#' @family registry
#' @export
#' @examples
#' m <- cd_method(
#'   id = "noop", name = "No-op", family = "constraint",
#'   available = function() TRUE,
#'   run = function(data) list(amat = NULL, runtime_s = 0, status = "ok")
#' )
#' register_method(m)
#' "noop" %in% list_methods()$id
register_method <- function(method) {
  if (!S7::S7_inherits(method, cd_method)) {
    stop(call. = FALSE, "`method` must be a `cd_method` object.")
  }
  assign(method@id, method, envir = .method_registry)
  invisible(method@id)
}

#' Fetch a registered method by id
#'
#' @param id A single method id.
#' @returns The [cd_method], or `NULL` when no such method is registered.
#' @noRd
#' @keywords internal
.get_method <- function(id) {
  if (exists(id, envir = .method_registry, inherits = FALSE)) {
    get(id, envir = .method_registry, inherits = FALSE)
  } else {
    NULL
  }
}

#' Ids of the methods whose back-end is usable in this session
#'
#' @returns A character vector of available method ids.
#' @noRd
#' @keywords internal
.available_method_ids <- function() {
  ids <- ls(.method_registry)
  if (length(ids) == 0L) {
    return(character(0))
  }
  keep <- vapply(ids, function(i) {
    isTRUE(tryCatch(.get_method(i)@available(), error = function(e) FALSE))
  }, logical(1))
  ids[keep]
}

#' The registered discovery methods
#'
#' Returns every registered method as a [cd_method] list, or -- with
#' `as_data_frame = TRUE` -- a data frame summarising the registry and which
#' back-ends are installed in the current session.
#'
#' @param as_data_frame A single logical. When `TRUE` (the default) a data frame
#'   is returned; when `FALSE` a named list of [cd_method] objects.
#' @returns A data frame with columns `id`, `name`, `family`, `language`,
#'   `cost`, and `installed`, or a named list of [cd_method] objects.
#' @family registry
#' @export
#' @examples
#' list_methods()
list_methods <- function(as_data_frame = TRUE) {
  ids <- ls(.method_registry)
  methods <- lapply(ids, .get_method)
  names(methods) <- ids
  if (!as_data_frame) {
    return(methods)
  }
  if (length(ids) == 0L) {
    return(data.frame(
      id = character(0), name = character(0), family = character(0),
      language = character(0), cost = character(0), installed = logical(0),
      stringsAsFactors = FALSE
    ))
  }
  out <- data.frame(
    id = vapply(methods, function(m) m@id, character(1)),
    name = vapply(methods, function(m) m@name, character(1)),
    family = vapply(methods, function(m) m@family, character(1)),
    language = vapply(methods, function(m) m@language, character(1)),
    cost = vapply(methods, function(m) m@cost, character(1)),
    installed = vapply(methods, function(m) {
      isTRUE(tryCatch(m@available(), error = function(e) FALSE))
    }, logical(1)),
    stringsAsFactors = FALSE
  )
  out[order(out$id), , drop = FALSE]
}

# ---------------------------------------------------------------------------
# Python back-end helpers (reticulate discovers its own interpreter; no path is
# hard-coded, so the user's RETICULATE_PYTHON / virtualenv settings are honoured)
# ---------------------------------------------------------------------------

.py_state <- new.env(parent = emptyenv())

.py_ready <- function() {
  if (!requireNamespace("reticulate", quietly = TRUE)) {
    return(FALSE)
  }
  ok <- tryCatch(reticulate::py_available(initialize = TRUE),
                 error = function(e) FALSE)
  if (isTRUE(ok) && is.null(.py_state$silenced)) {
    # quieten the back-ends' own logging so a discovery call does not flood the
    # console; done once per session.
    tryCatch(
      reticulate::py_run_string("import logging; logging.disable(logging.WARNING)"),
      error = function(e) NULL
    )
    .py_state$silenced <- TRUE
  }
  isTRUE(ok)
}

# Locate a top-level module without importing it (so a mere availability probe
# does not pull in a heavy back-end such as torch). importlib.util.find_spec on a
# top-level name reads the module's spec without executing it.
.py_module_available <- function(module) {
  if (!requireNamespace("reticulate", quietly = TRUE)) {
    return(FALSE)
  }
  if (!isTRUE(tryCatch(reticulate::py_available(initialize = TRUE),
                       error = function(e) FALSE))) {
    return(FALSE)
  }
  ok <- tryCatch({
    il <- reticulate::import("importlib.util", convert = TRUE)
    !is.null(il$find_spec(module))
  }, error = function(e) FALSE)
  isTRUE(ok)
}

# a writable, contiguous float64 numpy copy, kept as a Python object, because
# some back-ends mutate the input and an R-backed array is read-only.
.as_np <- function(data) {
  np <- reticulate::import("numpy", convert = FALSE)
  np$array(data, dtype = "float64", order = "C")$copy()
}

# ---------------------------------------------------------------------------
# convention converters (each smoke-tested by the registry conventions test)
# ---------------------------------------------------------------------------

# bnlearn amat(bn): arc i->j is amat[i,j]=1, amat[j,i]=0; undirected = both 1.
.bn_to_amat <- function(bn, labels) {
  a <- bnlearn::amat(bn)
  a <- a[labels, labels]
  storage.mode(a) <- "double"
  a
}

# lingam adjacency_matrix_[i,j] != 0 means j -> i (row=child, col=parent); our
# amat[i,j]=1 means i->j, so amat = t(B != 0). Non-finite entries (e.g. RCD's
# confounded ones) are treated as no determinable edge.
.lingam_B_to_amat <- function(B, labels, thresh = 1e-6) {
  B[!is.finite(B)] <- 0
  a <- t((abs(B) > thresh) * 1)
  dimnames(a) <- list(labels, labels)
  storage.mode(a) <- "double"
  a
}

# gcastle / dagma weighted or 0/1 matrix M[i,j] != 0 means i -> j. Already ours.
.weighted_to_amat <- function(W, labels, thresh = 0.1) {
  W[!is.finite(W)] <- 0
  a <- (abs(W) > thresh) * 1
  dimnames(a) <- list(labels, labels)
  storage.mode(a) <- "double"
  a
}

# causal-learn GeneralGraph endpoint matrix G: G[i,j]=-1 & G[j,i]=1 => i -> j;
# G[i,j]=G[j,i]=-1 => i -- j; G[i,j]=G[j,i]=1 => i <-> j (bidirected, latent).
.cl_graph_to_amat <- function(G, labels) {
  p <- nrow(G)
  a <- matrix(0, p, p)
  for (i in seq_len(p)) {
    for (j in seq_len(p)) {
      if (i >= j) {
        next
      }
      gij <- G[i, j]
      gji <- G[j, i]
      if (gij == 0 && gji == 0) {
        next
      }
      if (gij == -1 && gji == 1) {
        a[i, j] <- 1
      } else if (gij == 1 && gji == -1) {
        a[j, i] <- 1
      } else {
        a[i, j] <- 1
        a[j, i] <- 1
      }
    }
  }
  dimnames(a) <- list(labels, labels)
  a
}

# pcalg PAG (amat.pag, marks: 0 none, 1 circle, 2 arrowhead, 3 tail). Reduce to
# the skeleton; orient i->j only when a definite tail-arrowhead pair is present.
.pag_to_amat <- function(amat_pag, labels) {
  p <- nrow(amat_pag)
  a <- matrix(0, p, p)
  for (i in seq_len(p)) {
    for (j in seq_len(p)) {
      if (i >= j) {
        next
      }
      if (amat_pag[i, j] == 0 && amat_pag[j, i] == 0) {
        next
      }
      tail_i <- amat_pag[j, i] == 3
      head_j <- amat_pag[i, j] == 2
      tail_j <- amat_pag[i, j] == 3
      head_i <- amat_pag[j, i] == 2
      if (tail_i && head_j) {
        a[i, j] <- 1
      } else if (tail_j && head_i) {
        a[j, i] <- 1
      } else {
        a[i, j] <- 1
        a[j, i] <- 1
      }
    }
  }
  dimnames(a) <- list(labels, labels)
  a
}

# time a back-end call, capturing an error as a status rather than aborting.
.timed <- function(expr_fun) {
  t0 <- Sys.time()
  out <- tryCatch(
    expr_fun(),
    error = function(e) structure(list(), err = conditionMessage(e))
  )
  rt <- as.numeric(Sys.time() - t0, units = "secs")
  err <- attr(out, "err")
  if (!is.null(err)) {
    return(list(amat = NULL, runtime_s = rt,
                status = paste0("error: ", substr(err, 1L, 80L))))
  }
  list(amat = out, runtime_s = rt, status = "ok")
}

# ---------------------------------------------------------------------------
# built-in methods -- registered once from .onLoad
# ---------------------------------------------------------------------------

.has_pkg <- function(pkg) {
  function() requireNamespace(pkg, quietly = TRUE)
}

.has_py <- function(module) {
  function() .py_module_available(module)
}

#' Register the built-in discovery methods
#'
#' Called once from `.onLoad`. Each method is gated on its back-end package or
#' Python module, so a method whose back-end is absent registers but reports
#' itself unavailable.
#'
#' @returns `NULL`, invisibly.
#' @noRd
#' @keywords internal
.register_builtin_methods <- function() {
  # ---- pcalg (R) ----
  register_method(cd_method(
    id = "pc_pcalg", name = "PC (Fisher-Z)", family = "constraint",
    language = "R", output = "cpdag",
    citation = "Spirtes, Glymour & Scheines (2000); Colombo & Maathuis (2014)",
    cost = "fast", assumptions = "causal sufficiency; linear-Gaussian CI test",
    available = .has_pkg("pcalg"),
    run = function(data) {
      .timed(function() {
        suff <- list(C = stats::cor(data), n = nrow(data))
        fit <- pcalg::pc(suff, pcalg::gaussCItest, alpha = 0.05,
                         labels = colnames(data), verbose = FALSE)
        methods::as(fit@graph, "matrix")
      })
    }
  ))
  register_method(cd_method(
    id = "ges_pcalg", name = "GES (BIC)", family = "score",
    language = "R", output = "cpdag", citation = "Chickering (2002)",
    cost = "fast", assumptions = "causal sufficiency; Gaussian BIC score",
    available = .has_pkg("pcalg"),
    run = function(data) {
      .timed(function() {
        sc <- methods::new("GaussL0penObsScore", data = data)
        fit <- pcalg::ges(sc)
        a <- methods::as(fit$essgraph, "matrix") * 1
        dimnames(a) <- list(colnames(data), colnames(data))
        a
      })
    }
  ))
  register_method(cd_method(
    id = "icalingam_pcalg", name = "ICA-LiNGAM", family = "functional",
    language = "R", output = "dag",
    citation = "Shimizu, Hoyer, Hyvarinen & Kerminen (2006)",
    cost = "fast",
    assumptions = "linear; non-Gaussian noise; no latent confounders",
    available = .has_pkg("pcalg"),
    run = function(data) {
      .timed(function() {
        fit <- pcalg::lingam(data)
        .weighted_to_amat(t(fit$Bpruned), colnames(data), thresh = 1e-6)
      })
    }
  ))
  register_method(cd_method(
    id = "fci_pcalg", name = "FCI", family = "constraint",
    language = "R", output = "pag",
    citation = "Spirtes, Meek & Richardson (1995)",
    cost = "fast", assumptions = "allows latent confounders; outputs a PAG",
    available = .has_pkg("pcalg"),
    run = function(data) {
      .timed(function() {
        suff <- list(C = stats::cor(data), n = nrow(data))
        fit <- pcalg::fci(suff, pcalg::gaussCItest, alpha = 0.05,
                          labels = colnames(data), verbose = FALSE)
        .pag_to_amat(fit@amat, colnames(data))
      })
    }
  ))

  # ---- bnlearn (R) ----
  bn_name <- list(hc = "Hill-Climbing (BIC-g)", tabu = "Tabu (BIC-g)",
                  gs = "Grow-Shrink", iamb = "IAMB",
                  pc.stable = "PC-stable", mmhc = "MMHC")
  bn_family <- list(hc = "score", tabu = "score", gs = "constraint",
                    iamb = "constraint", pc.stable = "constraint",
                    mmhc = "hybrid")
  for (alg in names(bn_name)) {
    local({
      a <- alg
      register_method(cd_method(
        id = paste0(a, "_bnlearn"), name = bn_name[[a]],
        family = bn_family[[a]], language = "R",
        output = if (a %in% c("hc", "tabu", "mmhc")) "dag" else "cpdag",
        citation = "Scutari (2010); Tsamardinos, Brown & Aliferis (2006)",
        cost = "fast", assumptions = "continuous Gaussian (BIC-g / correlation CI)",
        available = .has_pkg("bnlearn"),
        run = function(data) {
          .timed(function() {
            df <- as.data.frame(data)
            fn <- getExportedValue("bnlearn", a)
            bn <- fn(df)
            .bn_to_amat(bn, colnames(data))
          })
        }
      ))
    })
  }

  # ---- lingam (Python) ----
  register_method(cd_method(
    id = "directlingam_py", name = "DirectLiNGAM", family = "functional",
    language = "Python", output = "dag",
    citation = "Shimizu et al. (2011)", cost = "fast",
    assumptions = "linear; non-Gaussian noise; no latent confounders",
    available = .has_py("lingam"),
    run = function(data) {
      .timed(function() {
        .py_ready()
        lg <- reticulate::import("lingam", convert = TRUE)
        m <- lg$DirectLiNGAM()
        m$fit(data)
        .lingam_B_to_amat(m$adjacency_matrix_, colnames(data))
      })
    }
  ))
  register_method(cd_method(
    id = "rcd_py", name = "RCD (latent-robust LiNGAM)", family = "functional",
    language = "Python", output = "dag",
    citation = "Maeda & Shimizu (2020)", cost = "medium",
    assumptions = "linear non-Gaussian; robust to some latent confounders",
    available = .has_py("lingam"),
    run = function(data) {
      .timed(function() {
        .py_ready()
        lg <- reticulate::import("lingam", convert = TRUE)
        m <- lg$RCD()
        m$fit(data)
        .lingam_B_to_amat(m$adjacency_matrix_, colnames(data))
      })
    }
  ))

  # ---- causal-learn (Python) ----
  register_method(cd_method(
    id = "pc_kci_cl", name = "PC + KCI (kernel CI)", family = "constraint",
    language = "Python", output = "cpdag",
    citation = "Zhang et al. (2011); Spirtes et al. (2000)", cost = "slow",
    assumptions = "causal sufficiency; kernel CI for nonlinear dependence",
    available = .has_py("causallearn"),
    run = function(data) {
      .timed(function() {
        .py_ready()
        clpc <- reticulate::import(
          "causallearn.search.ConstraintBased.PC", convert = TRUE)
        cg <- clpc$pc(data, 0.05, "kci", show_progress = FALSE)
        .cl_graph_to_amat(cg$G$graph, colnames(data))
      })
    }
  ))

  # ---- gcastle (Python) ----
  register_method(cd_method(
    id = "notears_gcastle", name = "NOTEARS (linear)",
    family = "continuous_optim", language = "Python", output = "dag",
    citation = "Zheng, Aragam, Ravikumar & Xing (2018)", cost = "medium",
    assumptions = "linear; acyclicity-constrained least squares",
    available = .has_py("castle"),
    run = function(data) {
      .timed(function() {
        .py_ready()
        ca <- reticulate::import("castle.algorithms", convert = TRUE)
        m <- ca$Notears()
        m$learn(data)
        .weighted_to_amat(m$causal_matrix, colnames(data), thresh = 0.5)
      })
    }
  ))
  register_method(cd_method(
    id = "golem_gcastle", name = "GOLEM", family = "continuous_optim",
    language = "Python", output = "dag",
    citation = "Ng, Ghassami & Zhang (2020)", cost = "slow",
    assumptions = "linear; likelihood with a soft acyclicity penalty",
    available = .has_py("castle"),
    run = function(data) {
      .timed(function() {
        .py_ready()
        ca <- reticulate::import("castle.algorithms", convert = TRUE)
        m <- ca$GOLEM(num_iter = 1e4L)
        m$learn(data)
        .weighted_to_amat(m$causal_matrix, colnames(data), thresh = 0.3)
      })
    }
  ))

  # ---- dagma (Python) ----
  register_method(cd_method(
    id = "dagma_linear_py", name = "DAGMA (linear)",
    family = "continuous_optim", language = "Python", output = "dag",
    citation = "Bello, Aragam & Ravikumar (2022)", cost = "fast",
    assumptions = "linear; log-det acyclicity characterisation",
    available = .has_py("dagma"),
    run = function(data) {
      .timed(function() {
        .py_ready()
        dg <- reticulate::import("dagma.linear", convert = TRUE)
        m <- dg$DagmaLinear(loss_type = "l2")
        w <- m$fit(.as_np(data), lambda1 = 0.02)
        .weighted_to_amat(w, colnames(data), thresh = 0.3)
      })
    }
  ))

  invisible(NULL)
}
