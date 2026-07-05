test_that("the Python availability check never initialises Python itself", {
  skip_if_not_installed("reticulate")
  skip_if(isTRUE(reticulate::py_available(initialize = FALSE)),
          "Python already initialised in this session")
  old_opt <- options(cdzoo.python_init = FALSE)
  old_env <- Sys.getenv("RETICULATE_PYTHON", unset = NA)
  Sys.unsetenv("RETICULATE_PYTHON")
  on.exit({
    options(old_opt)
    if (!is.na(old_env)) {
      Sys.setenv(RETICULATE_PYTHON = old_env)
    }
  }, add = TRUE)
  expect_false(cdzoo:::.py_module_available("lingam"))
  # the check must not have initialised Python as a side effect
  expect_false(isTRUE(reticulate::py_available(initialize = FALSE)))
})

test_that("Python availability probes are memoised and refreshable", {
  skip_if_not_installed("reticulate")
  assign("modules", list(fake_module_xyz = TRUE),
         envir = cdzoo:::.py_state)
  expect_true(cdzoo:::.py_module_available("fake_module_xyz"))
  list_methods(refresh = TRUE)
  expect_length(cdzoo:::.py_state$modules, 0L)
})

test_that("cd_method validates family and cost", {
  ok <- cd_method(id = "ok", family = "score", cost = "fast",
                  available = function() TRUE,
                  run = function(data) list(amat = NULL))
  expect_true(S7::S7_inherits(ok, cd_method))
  expect_error(cd_method(id = "x", family = "nonsense",
                         available = function() TRUE, run = identity),
               "family")
  expect_error(cd_method(id = "x", cost = "instant",
                         available = function() TRUE, run = identity),
               "cost")
  expect_error(cd_method(id = "", available = function() TRUE, run = identity),
               "non-empty")
})

test_that("the registry ships the sixteen built-in methods", {
  m <- list_methods()
  expect_s3_class(m, "data.frame")
  # the sixteen built-ins are always present (other tests may add their own)
  expect_true(all(all_method_ids() %in% m$id))
  builtin <- m[m$id %in% all_method_ids(), ]
  expect_true(all(builtin$family %in% c("constraint", "score", "functional",
                                        "continuous_optim", "hybrid")))
  expect_true(all(c("R", "Python") %in% builtin$language))
})

test_that("register_method adds and replaces by id", {
  noop <- cd_method(id = "noop_test", name = "No-op", family = "constraint",
                    available = function() TRUE,
                    run = function(data) list(amat = NULL, runtime_s = 0,
                                              status = "ok"))
  register_method(noop)
  expect_true("noop_test" %in% list_methods()$id)
  expect_error(register_method("not a method"), "cd_method")
})

test_that("the lingam converter honours the row=child convention", {
  # adjacency_matrix_[child, parent] != 0 ; here child 2, parent 1 => x1 -> x2
  b <- matrix(0, 2, 2)
  b[2, 1] <- 0.8
  a <- cdzoo:::.lingam_B_to_amat(b, c("x1", "x2"))
  expect_equal(a["x1", "x2"], 1)
  expect_equal(a["x2", "x1"], 0)
})

test_that("the weighted converter reads i -> j off a weight matrix", {
  w <- matrix(0, 2, 2)
  w[1, 2] <- 0.7
  a <- cdzoo:::.weighted_to_amat(w, c("x1", "x2"))
  expect_equal(a["x1", "x2"], 1)
  expect_equal(a["x2", "x1"], 0)
})

test_that("the causal-learn endpoint converter orients i -> j", {
  g <- matrix(0, 2, 2)
  g[1, 2] <- -1
  g[2, 1] <- 1
  a <- cdzoo:::.cl_graph_to_amat(g, c("x1", "x2"))
  expect_equal(a["x1", "x2"], 1)
  expect_equal(a["x2", "x1"], 0)
})

test_that("the PAG converter orients on a tail-arrowhead pair", {
  pag <- matrix(0, 2, 2)
  pag[2, 1] <- 3  # tail at x1
  pag[1, 2] <- 2  # arrowhead at x2  => x1 -> x2
  a <- cdzoo:::.pag_to_amat(pag, c("x1", "x2"))
  expect_equal(a["x1", "x2"], 1)
  expect_equal(a["x2", "x1"], 0)
})
