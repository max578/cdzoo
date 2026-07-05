test_that("perfect recovery scores f1 1 and shd 0", {
  truth <- amat_chain3()
  s <- cd_score(truth, truth)
  expect_equal(s$skeleton_f1, 1)
  expect_equal(s$shd, 0)
  expect_equal(s$orient_recall, 1)
})

test_that("an empty estimate misses every edge", {
  truth <- amat_chain3()
  s <- cd_score(matrix(numeric(0), 0L, 0L), truth)
  expect_equal(s$skeleton_f1, 0)
  expect_equal(s$shd, 2)            # two true edges, both deleted
  expect_equal(s$orient_recall, 0)
})

test_that("a reversed edge costs one structural-Hamming move, not two", {
  truth <- amat_chain3()
  est <- truth
  est["x1", "x2"] <- 0
  est["x2", "x1"] <- 1             # reverse x1 -> x2 to x2 -> x1
  s <- cd_score(est, truth)
  expect_equal(s$shd, 1)
  expect_equal(s$skeleton_f1, 1)   # skeleton unchanged
  expect_equal(s$orient_recall, 0.5)
})

test_that("an unoriented true edge is a partial miss in shd", {
  truth <- amat_chain3()
  est <- truth
  est["x2", "x1"] <- 1             # x1 -> x2 becomes x1 -- x2
  s <- cd_score(est, truth)
  expect_equal(s$shd, 1)
  expect_equal(s$orient_recall, 0.5)
})

test_that("cd_score validates the truth", {
  expect_error(cd_score(amat_chain3(), matrix(0, 2, 3)), "square")
})

test_that("weighted estimates are normalised before scoring", {
  truth <- amat_chain3()
  est <- truth
  est["x1", "x2"] <- 2 # a weighted arrow is still an arrow
  s <- cd_score(est, truth)
  expect_equal(s$skeleton_f1, 1)
  expect_equal(s$shd, 0)
  expect_equal(s$orient_recall, 1)
})

test_that("skeleton F1 is undefined against an edgeless truth", {
  empty <- matrix(0, 3, 3, dimnames = dimnames(amat_chain3()))
  s <- cd_score(empty, empty)
  expect_true(is.na(s$skeleton_f1))
  expect_equal(s$shd, 0) # a perfect empty recovery still has zero distance
  s2 <- cd_score(amat_chain3(), empty)
  expect_true(is.na(s2$skeleton_f1))
  expect_equal(s2$shd, 2)
})
