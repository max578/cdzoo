test_that("a recovered graph emits a conformant structure manifest", {
  r <- cd_result(graph = amat_chain3(), method = "pc_pcalg",
                 method_name = "PC (Fisher-Z)", family = "constraint")
  m <- as_orchestra_manifest(r)
  expect_true(S7::S7_inherits(m, orchestra_manifest))
  expect_identical(m@inferential_target, "structure")
  expect_identical(m@emitter_package, "cdzoo")
  expect_identical(m@method, "cdzoo:pc_pcalg")
  # the recovered edges ride in the params edge list
  expect_true(all(c("from", "to", "type") %in% names(m@params)))
  expect_equal(nrow(m@params), 2L)              # x1 -> x2 -> x3
  expect_false(m@summary$abstained)
  expect_false(is.null(m@metadata$amat))
  expect_true(verify_manifest(m)$ok)
})

test_that("a tampered payload is detected", {
  m <- as_orchestra_manifest(cd_result(graph = amat_chain3(), method = "demo"))
  expect_true(verify_manifest(m)$ok)
  m@params$to[1] <- "x9"                          # tamper with an edge
  expect_false(verify_manifest(m)$ok)
})

test_that("a result with no recovered graph abstains honestly", {
  rec <- cd_result(method = "golem_gcastle", status = "no back-end installed",
                   rationale = "no decisive signature", confidence = "moderate")
  m <- as_orchestra_manifest(rec)
  expect_identical(m@inferential_target, "structure")
  expect_true(m@summary$abstained)
  expect_match(m@summary$abstain_reason, "back-end")
  expect_equal(nrow(m@params), 0L)
  expect_true(verify_manifest(m)$ok)
})

test_that("a consensus result records its routing provenance", {
  r <- cd_result(graph = amat_chain3(), method = "consensus",
                 method_name = "Consensus of 2 methods",
                 rationale = "non-Gaussian margins", confidence = "high")
  m <- as_orchestra_manifest(r)
  expect_true(m@metadata$consensus)
  expect_identical(m@metadata$confidence, "high")
  expect_match(m@summary$headline, "Consensus")
})

test_that("the emitted manifest is reproducible by content", {
  r <- cd_result(graph = amat_chain3(), method = "demo")
  expect_identical(as_orchestra_manifest(r)@run_id,
                   as_orchestra_manifest(r)@run_id)
})

test_that("a recommendation-only result abstains with an honest reason", {
  skip_if_not_installed("pcalg")
  rec <- cd_auto(cd_scenario("linear_gaussian", seed = 1)$data, report = FALSE)
  expect_match(rec@status, "recommendation only")
  m <- as_orchestra_manifest(rec)
  expect_true(m@summary$abstained)
  expect_match(m@summary$abstain_reason, "recommendation only")
  expect_true(verify_manifest(m)$ok)
})
