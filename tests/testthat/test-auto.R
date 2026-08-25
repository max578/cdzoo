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

test_that("confidence steps down once on a plain substitution (CD-03)", {
  # rcd_py's declared assumptions ("linear non-Gaussian...") do not
  # contradict the firing non_gaussian route, so it is a plain substitution.
  r <- cdzoo:::.route_sampled(
    fake_features(non_gaussian_fraction = 1, mean_abs_kurtosis = 1.4),
    available = "rcd_py")
  expect_equal(r$method, "rcd_py")
  expect_equal(r$confidence, "moderate")
  expect_match(r$rationale, "downgraded from high to moderate")
})

test_that("confidence steps down twice when the substitute's assumptions contradict the route (CD-03)", {
  # gs_bnlearn's declared assumptions are "continuous Gaussian", the exact
  # condition the non_gaussian route just refuted.
  r <- cdzoo:::.route_sampled(
    fake_features(non_gaussian_fraction = 1, mean_abs_kurtosis = 1.4),
    available = "gs_bnlearn")
  expect_equal(r$method, "gs_bnlearn")
  expect_equal(r$confidence, "low")
  expect_match(r$rationale, "downgraded from high to low")
  expect_match(r$rationale, "contradict")
})

test_that("cd_auto survives a suffstat-only registry in route mode (CD-02)", {
  # cd_auto(mode = "route", report = TRUE) must use .method_input() to reduce
  # a raw data matrix to a sufficient statistic when the fallback method only
  # accepts one -- the base installation, where the only always-available
  # method is ggm_suffstat.
  reg <- cdzoo:::.method_registry
  saved <- as.list(reg)
  rm(list = ls(reg), envir = reg)
  on.exit({
    rm(list = ls(reg), envir = reg)
    for (nm in names(saved)) assign(nm, saved[[nm]], envir = reg)
  }, add = TRUE)
  assign("ggm_suffstat", saved[["ggm_suffstat"]], envir = reg)

  sim <- cd_scenario("linear_laplace", seed = 1)
  res <- cd_auto(sim$data)
  expect_true(S7::S7_inherits(res, cd_result))
  expect_equal(res@method, "ggm_suffstat")
  expect_equal(res@status, "ok")
})

test_that("cd_auto reports a recommendation with rationale and confidence", {
  rec <- cd_auto(cd_scenario("linear_laplace", seed = 1)$data, report = FALSE)
  expect_true(S7::S7_inherits(rec, cd_result))
  expect_match(rec@rationale, "normality")
  expect_true(rec@confidence %in% c("high", "moderate", "low"))
  # the deciding thresholds ride in the provenance for auditability
  expect_true(is.list(rec@provenance$thresholds))
  expect_equal(rec@provenance$thresholds$non_gaussian_fraction, 0.5)
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

test_that("alternatives are labels in both modes; consensus runs ride in provenance", {
  skip_if_not_installed("pcalg")
  sim <- cd_scenario("linear_laplace", seed = 1)
  routed <- cd_auto(sim$data, report = FALSE)
  con <- cd_auto(sim$data, mode = "consensus", top_k = 2L)
  for (res in list(routed, con)) {
    expect_true(all(vapply(res@alternatives, is.character, logical(1))))
  }
  expect_gte(length(con@provenance$runs), 1L)
  expect_true(S7::S7_inherits(con@provenance$runs[[1L]], cd_result))
})

# The two-line orchestra gate predicate, re-implemented locally (per the
# fleet's ORCHESTRA_dev/integration/refusal_contract.R:99, not imported --
# a member must never depend on the leader-side gate file) so this test does
# not depend on ORCHESTRA_dev.
.is_orchestra_decline <- function(x) {
  cls <- class(x)
  any(cls == "orchestra_refusal") || any(grepl("_(refusal|abstention)$", cls))
}

test_that("cd_auto(report = FALSE) stamps a decline the orchestra gate recognises", {
  # the exact fleet-gate trigger (ORCHESTRA_dev/integration/test_refusal_contract.R)
  set.seed(1L)
  d <- matrix(stats::rnorm(50), ncol = 5,
             dimnames = list(NULL, paste0("v", 1:5)))
  rec <- cd_auto(d, report = FALSE)
  expect_equal(rec@status, "recommendation only (report = FALSE)")
  expect_true(.is_orchestra_decline(rec))
  expect_true("orchestra_refusal" %in% class(rec))
  expect_true(any(grepl("_abstention$", class(rec))))
})

test_that("an unroutable recommendation ('no back-end installed') is stamped too", {
  sim <- cd_scenario("linear_laplace", seed = 1)
  rec <- with_mocked_bindings(
    cd_auto(sim$data, report = FALSE),
    .available_method_ids = function() character(0)
  )
  expect_equal(rec@status, "no back-end installed")
  expect_true(.is_orchestra_decline(rec))
})

test_that("a suffstat recommendation-only result is stamped too", {
  sim <- cd_scenario("linear_laplace", seed = 1)
  ss <- cd_suffstat(stats::cor(sim$data), nrow(sim$data))
  rec <- cd_auto(ss, report = FALSE)
  expect_equal(rec@status, "recommendation only (report = FALSE)")
  expect_true(.is_orchestra_decline(rec))
})

test_that("a run that actually completes is NOT stamped as a decline", {
  sim <- cd_scenario("linear_laplace", seed = 1)
  res <- cd_auto(sim$data)
  expect_equal(res@status, "ok")
  expect_false(.is_orchestra_decline(res))
})
