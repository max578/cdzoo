# Diverse consensus + agreement column (U4), parallel benchmark (U5), and the
# plot method (U7).

test_that("diverse top-k spans families before repeating one", {
  # non_gaussian route lists icalingam (functional), directlingam (functional),
  # rcd (functional), dagma (continuous_optim); diversity should not pick three
  # functional methods before the continuous-optim one.
  ids <- cdzoo:::.diverse_topk(
    c("icalingam_pcalg", "directlingam_py", "rcd_py", "dagma_linear_py"),
    all_method_ids(), k = 2L)
  fams <- vapply(ids, function(i) cdzoo:::.get_method(i)@family, character(1))
  expect_equal(length(ids), 2L)
  expect_equal(length(unique(fams)), 2L)
})

test_that("diverse top-k fills to k when families run out", {
  ids <- cdzoo:::.diverse_topk(c("pc_pcalg", "fci_pcalg"),
                               c("pc_pcalg", "fci_pcalg"), k = 2L)
  # both are constraint-family, but k = 2 is honoured by filling
  expect_equal(sort(ids), c("fci_pcalg", "pc_pcalg"))
})

test_that("cd_edges exposes per-edge agreement for a consensus result", {
  skip_if_not_installed("pcalg")
  sim <- cd_scenario("linear_laplace", seed = 1)
  con <- cd_auto(sim$data, mode = "consensus", top_k = 2L)
  e <- cd_edges(con, agreement = TRUE)
  expect_true("agreement" %in% names(e))
  if (nrow(e) > 0L) {
    expect_true(all(e$agreement >= 0 & e$agreement <= 1, na.rm = TRUE))
  }
  # a plain result has no agreement matrix, so the column is NA
  plain <- cd_edges(cd_result(graph = amat_chain3(), method = "demo"),
                    agreement = TRUE)
  expect_true(all(is.na(plain$agreement)))
})

test_that("consensus draws a family-diverse panel", {
  skip_if_not_installed("pcalg")
  sim <- cd_scenario("linear_gaussian", seed = 1)
  con <- cd_auto(sim$data, mode = "consensus", top_k = 3L)
  ids <- vapply(con@provenance$runs, function(r) r@method, character(1))
  fams <- vapply(ids, function(i) cdzoo:::.get_method(i)@family, character(1))
  # with three data-method families installed the panel should not be all one
  expect_gte(length(unique(fams)), 2L)
})

test_that("cd_benchmark is deterministic across core counts", {
  skip_if_not_installed("pcalg")
  skip_on_os("windows")
  a <- cd_benchmark(methods = c("pc_pcalg", "ges_pcalg"),
                    scenarios = "linear_gaussian", seeds = 1:2,
                    verbose = FALSE, mc.cores = 1L)
  b <- cd_benchmark(methods = c("pc_pcalg", "ges_pcalg"),
                    scenarios = "linear_gaussian", seeds = 1:2,
                    verbose = FALSE, mc.cores = 2L)
  # runtime_s is wall-clock and need not match; every scored column must
  cols <- setdiff(names(a), "runtime_s")
  expect_equal(a[, cols], b[, cols])
})

test_that("cd_benchmark validates mc.cores", {
  expect_error(
    cd_benchmark(methods = "pc_pcalg", scenarios = "linear_gaussian",
                 seeds = 1L, verbose = FALSE, mc.cores = 0L),
    "mc.cores")
})

test_that("plotting a result draws without error and returns it invisibly", {
  g <- amat_chain3()
  pdf(NULL)
  on.exit(dev.off())
  out <- withVisible(plot(cd_result(graph = g, method = "demo")))
  expect_false(out$visible)
  expect_true(S7::S7_inherits(out$value, cd_result))
})

test_that("plotting an empty result errors clearly", {
  expect_error(plot(cd_result(method = "failed", status = "error: boom")),
               "no graph")
})
