test_that("cd_result constructs and reports its graph", {
  g <- amat_chain3()
  r <- cd_result(graph = g, method = "demo", method_name = "Demo",
                 family = "constraint")
  expect_true(S7::S7_inherits(r, cd_result))
  expect_equal(r@method, "demo")
  expect_output(print(r), "Demo")
  expect_output(print(r), "directed")
})

test_that("cd_result rejects a non-square graph", {
  bad <- matrix(0, 2, 3)
  expect_error(cd_result(graph = bad, method = "x"), "square")
})

test_that("an empty result is valid and prints", {
  r <- cd_result(method = "failed", status = "error: boom")
  expect_equal(length(r@graph), 0L)
  expect_output(print(r), "error: boom")
})

test_that("cd_edges enumerates directed and undirected edges", {
  g <- amat_chain3()
  g["x1", "x3"] <- 1
  g["x3", "x1"] <- 1  # an undirected x1 -- x3
  e <- cd_edges(g)
  expect_equal(nrow(e), 3L)
  expect_true(any(e$type == "-->"))
  expect_true(any(e$type == "---"))
  directed <- e[e$type == "-->", ]
  expect_true(all(directed$from %in% c("x1", "x2")))
})

test_that("cd_edges of an empty graph has zero rows", {
  expect_equal(nrow(cd_edges(matrix(numeric(0), 0L, 0L))), 0L)
})
