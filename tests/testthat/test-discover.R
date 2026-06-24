test_that("cd_discover rejects an unknown method", {
  sim <- cd_scenario("linear_gaussian", seed = 1)
  expect_error(cd_discover(sim$data, "no_such_method"), "Unknown method")
})

test_that("cd_discover rejects an unavailable back-end with guidance", {
  register_method(cd_method(
    id = "off_test", name = "Off", family = "constraint",
    available = function() FALSE,
    run = function(data) list(amat = NULL, runtime_s = 0, status = "ok")))
  sim <- cd_scenario("linear_gaussian", seed = 1)
  expect_error(cd_discover(sim$data, "off_test"), "not available")
})

test_that("cd_discover validates its data", {
  expect_error(cd_discover(matrix(1, 10, 1), "pc_pcalg"), "two variables")
  bad <- cd_scenario("linear_gaussian", seed = 1)$data
  bad[1, 1] <- NA
  expect_error(cd_discover(bad, "pc_pcalg"), "non-finite")
})

test_that("cd_discover runs a real method end to end", {
  skip_if_not_installed("pcalg")
  sim <- cd_scenario("linear_gaussian", seed = 1)
  res <- cd_discover(sim$data, "pc_pcalg")
  expect_true(S7::S7_inherits(res, cd_result))
  expect_equal(res@status, "ok")
  expect_equal(dim(res@graph), c(sim$p, sim$p))
  sc <- cd_score(res, sim$truth)
  expect_gte(sc$skeleton_f1, 0.5)
})

test_that("cd_benchmark scores a method across seeds", {
  skip_if_not_installed("pcalg")
  res <- cd_benchmark(methods = "pc_pcalg", scenarios = "linear_gaussian",
                      seeds = 1:2, verbose = FALSE)
  expect_equal(nrow(res), 2L)
  expect_true(all(res$status == "ok"))
  expect_true(all(c("skeleton_f1", "shd", "orient_recall") %in% names(res)))
})

test_that("cd_benchmark with no installed method returns zero rows", {
  res <- cd_benchmark(methods = "off_test", scenarios = "linear_gaussian",
                      seeds = 1, verbose = FALSE)
  expect_equal(nrow(res), 0L)
})
