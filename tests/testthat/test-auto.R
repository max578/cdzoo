test_that("the router sends non-Gaussian data to the LiNGAM family", {
  r <- cdzoo:::.route_sampled(
    fake_features(non_gaussian_fraction = 1, mean_abs_kurtosis = 1.4),
    all_method_ids())
  expect_equal(r$method, "icalingam_pcalg")
  expect_equal(r$confidence, "high")
  expect_match(r$rationale, "normality")
})

test_that("the router sends equal-variance Gaussian data to continuous-optim", {
  r <- cdzoo:::.route_sampled(
    fake_features(non_gaussian_fraction = 0, equal_variance_ratio = 1.2),
    all_method_ids())
  expect_equal(r$method, "golem_gcastle")
})

test_that("the router sends a nonlinear signal to a kernel CI test", {
  r <- cdzoo:::.route_sampled(
    fake_features(nonlinearity = 0.3), all_method_ids())
  expect_equal(r$method, "pc_kci_cl")
})

test_that("the router sends a latent hint to a confounder-robust method", {
  r <- cdzoo:::.route_sampled(
    fake_features(condition_number = 5000), all_method_ids())
  expect_equal(r$method, "fci_pcalg")
  expect_equal(r$confidence, "low")
})

test_that("the default route is the strongest overall method", {
  r <- cdzoo:::.route_sampled(
    fake_features(equal_variance_ratio = 5), all_method_ids())
  expect_equal(r$method, "golem_gcastle")
})

test_that("an absent preferred method falls back and says so", {
  r <- cdzoo:::.route_sampled(
    fake_features(non_gaussian_fraction = 1), available = "pc_pcalg")
  expect_equal(r$method, "pc_pcalg")
  expect_equal(r$ideal, "icalingam_pcalg")
  expect_match(r$rationale, "not installed")
})

test_that("cd_auto reports a recommendation with rationale and confidence", {
  rec <- cd_auto(cd_scenario("linear_laplace", seed = 1)$data, report = FALSE)
  expect_true(S7::S7_inherits(rec, cd_result))
  expect_match(rec@rationale, "normality")
  expect_true(rec@confidence %in% c("high", "moderate", "low"))
})

test_that("cd_auto reads structure off an evaluable density", {
  skip_if_not_installed("proxymix")
  g <- proxymix::gmm(weights = 1, means = list(c(0, 0, 0)),
                     covariances = list(diag(3)))
  res <- cd_auto(g)
  expect_equal(res@family, "density")
  expect_equal(res@status, "ok")
  expect_equal(dim(res@graph), c(3L, 3L))
  expect_true(isSymmetric(unname(res@graph)))
})

test_that("cd_auto consensus returns a combined graph with agreement", {
  skip_if_not_installed("pcalg")
  sim <- cd_scenario("linear_laplace", seed = 1)
  res <- cd_auto(sim$data, mode = "consensus", top_k = 2L)
  expect_equal(res@method, "consensus")
  expect_equal(dim(res@graph), c(sim$p, sim$p))
  expect_true(!is.null(res@provenance$agreement))
})
