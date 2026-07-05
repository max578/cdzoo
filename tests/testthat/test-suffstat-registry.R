# Registry integration + cd_auto for sufficient statistics (U1/U2), and
# cd_explain (U3).

test_that("the suffstat methods are registered with accepts = suffstat", {
  m <- list_methods()
  expect_true(all(c("pc_suffstat", "fci_suffstat", "ggm_suffstat") %in% m$id))
  expect_true("accepts" %in% names(m))
  suff <- m[m$id %in% c("pc_suffstat", "fci_suffstat", "ggm_suffstat"), ]
  expect_true(all(suff$accepts == "suffstat"))
  # ggm needs no back-end, so it is always installed
  expect_true(m$installed[m$id == "ggm_suffstat"])
})

test_that("cd_method rejects an unknown accepts value", {
  expect_error(
    cd_method(id = "x", accepts = "nonsense",
              available = function() TRUE, run = identity),
    "accepts")
})

test_that("cd_discover runs a suffstat method by reducing the data", {
  skip_if_not_installed("pcalg")
  sim <- cd_scenario("linear_gaussian", seed = 1)
  viareg <- cd_discover(sim$data, "pc_suffstat")
  viadirect <- cd_discover_suffstat(stats::cor(sim$data), nrow(sim$data), "pc")
  # the registered method and the direct front door compute the same graph
  expect_equal(viareg@graph, viadirect@graph)
})

test_that("the default benchmark excludes suffstat methods but honours a request", {
  skip_if_not_installed("pcalg")
  # the default set runs every installed data method; bnlearn's mmhc emits a
  # benign "vstructure not applicable" diagnostic on some data, muffled here so
  # the test asserts the method-set behaviour rather than back-end chatter.
  def <- suppressWarnings(
    cd_benchmark(scenarios = "linear_gaussian", seeds = 1L, verbose = FALSE))
  expect_false(any(grepl("_suffstat$", def$method)))
  asked <- cd_benchmark(methods = "ggm_suffstat", scenarios = "linear_gaussian",
                        seeds = 1L, verbose = FALSE)
  expect_true(all(asked$method == "ggm_suffstat"))
})

test_that("cd_suffstat validates and standardises its input", {
  sim <- cd_scenario("linear_gaussian", seed = 1)
  ss <- cd_suffstat(stats::cov(sim$data), nrow(sim$data))
  expect_s3_class(ss, "cd_suffstat")
  expect_equal(diag(ss$C), rep(1, ncol(sim$data)), ignore_attr = TRUE)
  expect_error(cd_suffstat(matrix(1, 3, 2), 100), "square")
  expect_error(cd_suffstat(diag(3), -1), "positive")
})

test_that("cd_auto recommends and runs on a sufficient statistic", {
  skip_if_not_installed("pcalg")
  sim <- cd_scenario("linear_gaussian", seed = 1)
  ss <- cd_suffstat(stats::cor(sim$data), nrow(sim$data))
  rec <- cd_auto(ss, report = FALSE)
  expect_match(rec@rationale, "sufficient statistic")
  expect_true(rec@method %in% c("pc_suffstat", "fci_suffstat", "ggm_suffstat"))

  run <- cd_auto(ss)
  expect_equal(run@status, "ok")
  expect_equal(run@provenance$source, "suffstat")
  # routing on the statistic reproduces the direct suffstat discovery
  direct <- cd_discover_suffstat(ss$C, ss$n, method = sub("_suffstat$", "",
                                                          run@method))
  expect_equal(run@graph, direct@graph)
})

test_that("cd_auto consensus on a suffstat combines the installed methods", {
  skip_if_not_installed("pcalg")
  sim <- cd_scenario("linear_gaussian", seed = 1)
  ss <- cd_suffstat(stats::cor(sim$data), nrow(sim$data))
  con <- cd_auto(ss, mode = "consensus", top_k = 2L)
  expect_equal(con@method, "consensus")
  expect_true(!is.null(con@provenance$agreement))
  expect_gte(length(con@provenance$runs), 1L)
})

test_that("a suffstat recommendation emits a verifiable structure manifest", {
  skip_if_not_installed("pcalg")
  sim <- cd_scenario("linear_gaussian", seed = 1)
  res <- cd_auto(cd_suffstat(stats::cor(sim$data), nrow(sim$data)))
  man <- as_orchestra_manifest(res, seed = 1L)
  expect_identical(man@inferential_target, "structure")
  expect_true(verify_manifest(man)$ok)
})

test_that("cd_explain prints an account and returns its input invisibly", {
  skip_if_not_installed("pcalg")
  sim <- cd_scenario("linear_laplace", seed = 1)
  rec <- cd_auto(sim$data, report = FALSE)
  expect_output(cd_explain(rec), "Recommendation")
  expect_output(cd_explain(rec), "Why this method")
  expect_output(cd_explain(rec), "Routing thresholds")
  out <- withVisible(cd_explain(rec))
  expect_false(out$visible)
  expect_true(S7::S7_inherits(out$value, cd_result))
})

test_that("cd_explain rejects a non-result", {
  expect_error(cd_explain(list()), "cd_result")
})
