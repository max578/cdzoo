test_that("cd_diagnose is deterministic and leaves the RNG state untouched", {
  set.seed(7)
  d <- matrix(stats::rnorm(6000L * 4L), 6000L, 4L)
  set.seed(99)
  before <- get(".Random.seed", envir = globalenv())
  one <- cd_diagnose(d)
  expect_identical(get(".Random.seed", envir = globalenv()), before)
  two <- cd_diagnose(d)
  expect_identical(one, two)
})

test_that("cd_diagnose flags non-Gaussian margins", {
  ng <- cd_diagnose(cd_scenario("linear_laplace", seed = 1)$data)
  g <- cd_diagnose(cd_scenario("linear_gaussian", seed = 1)$data)
  expect_gt(ng$non_gaussian_fraction, 0.5)
  expect_lt(g$non_gaussian_fraction, 0.5)
  expect_gt(ng$mean_abs_kurtosis, g$mean_abs_kurtosis)
})

test_that("the curvature heuristic is larger on a nonlinear mechanism", {
  nl <- cd_diagnose(cd_scenario("nonlinear_anm", seed = 1)$data)
  lin <- cd_diagnose(cd_scenario("linear_gaussian", seed = 1)$data)
  expect_gt(nl$nonlinearity, lin$nonlinearity)
})

test_that("cd_diagnose returns one tidy row", {
  d <- cd_diagnose(cd_scenario("linear_bimodal", seed = 1)$data)
  expect_s3_class(d, "data.frame")
  expect_equal(nrow(d), 1L)
  expect_true(all(c("non_gaussian_fraction", "equal_variance_ratio",
                    "nonlinearity", "condition_number") %in% names(d)))
})

test_that("validation rejects degenerate input", {
  expect_error(cd_diagnose(matrix(1, 10, 1)), "two variables")
  expect_error(cd_diagnose(matrix(1:4, 2, 2)), "five observations")
})
