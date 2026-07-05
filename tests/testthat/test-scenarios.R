test_that("cd_scenarios lists the nine scenarios", {
  s <- cd_scenarios()
  expect_equal(nrow(s), 9L)
  expect_true(all(c("linear_gaussian", "linear_laplace", "regime_switching")
                  %in% s$name))
})

test_that("cd_scenario is reproducible at a fixed seed", {
  a <- cd_scenario("linear_bimodal", seed = 42)
  b <- cd_scenario("linear_bimodal", seed = 42)
  expect_identical(a$data, b$data)
  c <- cd_scenario("linear_bimodal", seed = 43)
  expect_false(identical(a$data, c$data))
})

test_that("every scenario generates data and a truth in convention", {
  for (nm in cd_scenarios()$name) {
    sim <- cd_scenario(nm, seed = 1)
    expect_equal(ncol(sim$data), sim$p)
    expect_equal(nrow(sim$data), sim$n)
    expect_equal(dim(sim$truth), c(sim$p, sim$p))
    # truth is t(dag): an entry is a directed edge, never the diagonal
    expect_true(all(diag(sim$truth) == 0))
    expect_true(all(sim$truth %in% c(0, 1)))
  }
})

test_that("an unknown scenario errors helpfully", {
  expect_error(cd_scenario("not_a_scenario"), "Unknown scenario")
})

test_that("large seeds do not overflow the derived graph seed", {
  for (s in list(300000L, 2e6, 3e9)) {
    sim <- expect_silent(cd_scenario("linear_gaussian", seed = s))
    expect_equal(dim(sim$truth), c(sim$p, sim$p))
  }
  expect_error(cd_scenario("linear_gaussian", seed = Inf), "finite")
  expect_error(cd_scenario("linear_gaussian", seed = c(1, 2)), "single")
})
