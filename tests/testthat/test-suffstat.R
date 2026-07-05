# Discovery from a sufficient statistic, and the counts -> correlation ingress.

test_that("suffstat PC reproduces cd_discover from the statistic alone", {
  skip_if_not_installed("pcalg")
  sim <- cd_scenario("linear_gaussian", seed = 1)
  from_data <- cd_discover(sim$data, "pc_pcalg")
  from_suff <- cd_discover_suffstat(
    stats::cor(sim$data), nrow(sim$data), method = "pc", test = "gauss")
  # the sufficient statistic carries everything PC needs: same graph, no rows
  expect_equal(from_suff@graph, from_data@graph)
  expect_identical(from_suff@provenance$source, "suffstat")
})

test_that("suffstat discovery recovers the true structure (gauss and magnitude)", {
  skip_if_not_installed("pcalg")
  sim <- cd_scenario("linear_gaussian", seed = 1)
  C <- stats::cor(sim$data)
  for (test in c("gauss", "magnitude")) {
    res <- cd_discover_suffstat(C, nrow(sim$data), method = "pc", test = test)
    expect_true(S7::S7_inherits(res, cd_result))
    expect_identical(res@status, "ok")
    expect_gte(cd_score(res, sim$truth)$skeleton_f1, 0.5)
  }
})

test_that("the GGM skeleton needs no back-end and is undirected", {
  sim <- cd_scenario("linear_gaussian", seed = 1)
  res <- cd_discover_suffstat(stats::cor(sim$data), nrow(sim$data),
                              method = "ggm", tau = 0.05)
  expect_identical(res@method, "ggm_suffstat")
  edges <- cd_edges(res)
  expect_gt(nrow(edges), 0L)
  expect_true(all(edges$type == "---"))
})

test_that("cd_correlation_from_counts feeds straight into discovery", {
  # three binary variables: a and b strongly linked, c near-independent
  pairs <- data.frame(
    var_i = c("a", "a", "b"),
    var_j = c("b", "c", "c"),
    n11 = c(900, 110, 105),
    n10 = c(100, 890, 895),
    n01 = c(100, 90, 95),
    n00 = c(8900, 8910, 8905))
  C <- cd_correlation_from_counts(pairs, type = "phi")
  expect_equal(dim(C), c(3L, 3L))
  expect_gte(attr(C, "repair")$eig_min, -1e-8)        # positive-definite
  expect_gt(C["a", "b"], C["a", "c"])                 # a-b is the strong link
  res <- cd_discover_suffstat(C, n = 10000, method = "ggm")
  expect_true(S7::S7_inherits(res, cd_result))
})

test_that("a suffstat result emits and verifies a structure manifest", {
  skip_if_not_installed("pcalg")
  sim <- cd_scenario("linear_gaussian", seed = 1)
  res <- cd_discover_suffstat(stats::cor(sim$data), nrow(sim$data), "pc")
  man <- as_orchestra_manifest(res, seed = 1L)
  expect_identical(man@inferential_target, "structure")
  expect_true(verify_manifest(man)$ok)
})

test_that("cd_discover_suffstat validates its inputs", {
  expect_error(cd_discover_suffstat(matrix(1, 3, 2), 100), "square")
  expect_error(cd_discover_suffstat(diag(3), -1), "positive")
  expect_error(
    cd_correlation_from_counts(data.frame(var_i = "a", var_j = "b")),
    "must have columns")
})

test_that("a non-positive covariance diagonal is rejected before cov2cor", {
  bad <- matrix(c(0, 0.2, 0.2, 1), 2, 2)
  expect_error(cd_discover_suffstat(bad, 100, method = "ggm"),
               "strictly positive diagonal")
})

test_that("cd_correlation_from_counts rejects bad and duplicated counts", {
  neg <- data.frame(var_i = "a", var_j = "b",
                    n11 = -1, n10 = 10, n01 = 10, n00 = 90)
  expect_error(cd_correlation_from_counts(neg), "non-negative")
  dup <- data.frame(
    var_i = c("a", "b"), var_j = c("b", "a"),
    n11 = c(9, 9), n10 = c(1, 1), n01 = c(1, 1), n00 = c(89, 89))
  expect_error(cd_correlation_from_counts(dup), "must appear once")
})

test_that("the GGM skeleton refuses a singular matrix", {
  # two perfectly collinear variables give a singular correlation matrix; the
  # failure rides in the result status (like any back-end failure), not a throw
  C <- matrix(1, 2, 2, dimnames = list(c("a", "b"), c("a", "b")))
  res <- cd_discover_suffstat(C, 1000, method = "ggm")
  expect_match(res@status, "ill-conditioned")
  expect_equal(length(res@graph), 0L)
})
