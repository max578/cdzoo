# cdzoo (development version)

## Bug fixes

* The confidence label a route reports is now revised when the route's
  preferred method is not installed and a substitute runs instead: one step
  down the high/moderate/low ladder for a plain substitution, a second step
  when the substitute's declared `assumptions` contradict the data signature
  that fired the route (for example a route that fired on non-Gaussian data,
  substituted with a method that assumes Gaussian margins). The downgrade and
  its reason are stated in the recommendation's rationale (CD-03).
* `cd_auto(mode = "route", report = TRUE)` no longer errors when the only
  available method accepts a sufficient statistic rather than raw data (the
  base installation, where `ggm_suffstat` is always available): the final
  route call now reduces the input through `.method_input()` like every other
  call site (CD-02).

# cdzoo 0.2.0

## New features

* A sufficient statistic is now a first-class discovery input. `cd_method`
  gains an `accepts` field (`"data"` or `"suffstat"`), and the constraint
  methods `pc_suffstat`, `fci_suffstat`, and `ggm_suffstat` are registered so
  they appear in `list_methods()` (which gains an `accepts` column) and are
  routable by `cd_auto()`. A `"suffstat"` method can also be run on a data
  matrix through `cd_discover()`, which reduces the data to its sufficient
  statistic first.
* `cd_auto()` accepts a sufficient statistic, `cd_suffstat(C, n)`, and routes
  it among the sufficient-statistic methods. A correlation matrix carries only
  the latent-structure hint, so the recommendation states plainly that the
  non-Gaussianity, nonlinearity, and equal-variance tests could not be run --
  honest about what an aggregated input does and does not support. `report`,
  `mode = "consensus"`, and manifest emission all work on this input.
* `cd_explain()` prints a readable account of a recommendation -- the method
  and status, the routing rationale and confidence, the alternatives
  considered, the thresholds that decided the route, and (for a consensus) the
  per-edge agreement -- the auditable companion to the compact `print()`.
* `cd_auto(mode = "consensus")` now draws a family-diverse panel of methods
  rather than several near-identical members of one family, for a
  better-grounded agreement signal, and `cd_edges(res, agreement = TRUE)`
  reports the per-edge agreement of a consensus result.
* `cd_benchmark(mc.cores = )` runs the scenario grid across cores. Each cell is
  deterministic given its scenario seed and independent of the others, so the
  result is identical for any core count.
* A `plot()` method for `cd_result` draws the recovered graph (variables on a
  circle, arrows for directed edges) using base graphics only -- no plotting
  back-end required.
* A second vignette, *Discovery from sufficient statistics*, works an example
  from co-occurrence counts through a correlation matrix, discovery, a routed
  recommendation, and a verifiable manifest.

# cdzoo 0.1.1

## Breaking changes

* The federation manifest's integrity hash is now computed over version-stable
  bytes (serialisation pinned to format 2, its version-carrying header dropped
  before hashing), matching the updated reference contract
  (`MANIFEST_VERSION` `2.0.0-draft`). A manifest emitted under one R version
  now verifies under any other. Manifests emitted before this change no longer
  verify and must be re-emitted:

  ```r
  # before: verify_manifest(old_manifest)$ok could be FALSE on another R version
  # after:  re-emit from the original result
  m <- as_orchestra_manifest(result)
  verify_manifest(m)$ok
  ```

* `cd_result@alternatives` now always holds method labels, in both `"route"`
  and `"consensus"` modes; the consensus member results moved to
  `provenance$runs`:

  ```r
  # before: con@alternatives held cd_result objects in consensus mode
  # after:
  con <- cd_auto(x, mode = "consensus")
  con@alternatives       # method labels
  con@provenance$runs    # the member cd_result objects
  ```

## Minor improvements and fixes

* `cd_auto()` records the four data-characteristic thresholds that decided the
  route in the result's `provenance$thresholds`, and documents them, so every
  recommendation carries the rule it was made under.
* `cd_discover_suffstat()` runs an order-independent (`"stable"`) skeleton
  search on the Fisher-Z branch too, so the recovered graph no longer depends
  on the variable ordering; it rejects a covariance with a non-positive
  diagonal, and the Gaussian-graphical-model skeleton refuses a matrix too
  ill-conditioned to invert rather than returning noise.
* `cd_correlation_from_counts()` rejects negative, missing, or duplicated
  pairwise counts instead of silently mishandling them.
* The Python back-end availability check is passive and memoised: `cdzoo`
  never initialises Python (which can trigger interpreter provisioning) just
  to report availability. Back-ends show as installed once reticulate's
  interpreter is initialised or configured; `options(cdzoo.python_init = TRUE)`
  opts into eager initialisation, and `list_methods(refresh = TRUE)` re-probes
  after a mid-session install.
* The scenario simulators now draw their noise under the documented scenario
  seed (previously a lazy-evaluation quirk drew it under the graph-derived
  stream, coupling the noise to the graph settings). Scenario realisations at
  a fixed seed change accordingly; the scenario truths are unaffected.
* `cd_score()` normalises its inputs so any non-zero entry counts as an edge
  mark -- a weighted adjacency matrix now scores its orientations too -- and
  `skeleton_f1` is `NA` (previously 0) when the truth has no edges, where
  recall is undefined.

* `cd_diagnose()` -- and therefore `cd_auto()`'s routing -- is now deterministic
  and leaves the caller's random-number state untouched: on large data sets the
  normality and regression heuristics read an evenly spaced, deterministic
  subsample instead of a random one. Repeated calls on the same data return the
  same characteristics and the same recommendation.
* `cd_scenario()` accepts any finite seed; seeds above about 271,000 previously
  failed with an integer-overflow error. Realisations at all previously-valid
  seeds are unchanged.
* `cd_auto(report = FALSE)` now labels its result
  `"recommendation only (report = FALSE)"` instead of `"ok"`, so a
  recommendation-only result -- and the manifest it emits -- states honestly
  that no graph was recovered.
* `cd_benchmark()` now warns about requested methods it drops (an unknown id,
  an absent back-end, or a cost above `cost_limit`) instead of dropping them
  silently.
* The citation file reads the version from the installed package rather than
  hard-coding it, and the pkgdown reference index gained the
  sufficient-statistic and federation-manifest functions added in 0.1.0.

# cdzoo 0.1.0

## New features

* `cd_discover_suffstat()` runs constraint-based discovery directly on a
  sufficient statistic -- a correlation or covariance matrix and its sample size
  -- and returns a `cd_result` in the same `amat.cpdag` convention as
  `cd_discover()`. This is cdzoo's front door for data that arrives already
  aggregated (a published correlation matrix, a privacy-preserving summary, or
  pairwise co-occurrence counts) with no row-level observation matrix to pass to
  `cd_discover()`. `method = "ggm"` returns the partial-correlation
  (Gaussian-graphical-model) skeleton and needs no back-end; `method = "pc"` and
  `method = "fci"` add orientation through `pcalg`, with `"fci"` allowing latent
  confounders.
* A magnitude-based conditional-independence test (`test = "magnitude"`) prunes
  an edge when the partial-correlation magnitude falls below `tau`, the correct
  behaviour at population sample sizes where a significance test
  (`test = "gauss"`, the default) would call every pair dependent.
* `cd_correlation_from_counts()` assembles a positive-definite correlation matrix
  from pairwise binary two-by-two counts (the phi coefficient, base R, or the
  latent-Gaussian tetrachoric correlation via the optional `psych` package),
  repairing an indefinite matrix to the nearest positive-definite correlation
  matrix by eigenvalue clipping. Its output feeds straight into
  `cd_discover_suffstat()`, so the whole counts -> correlation -> discovery ->
  `as_orchestra_manifest()` path composes.

# cdzoo 0.0.0.9000

* Initial development version. cdzoo provides a single typed interface over a
  portfolio of causal-discovery algorithms drawn from several R and Python
  back-ends, a structural-causal-model scenario grid with known ground truth,
  fair graph-recovery metrics, and an evidence-routed recommender.

## Features

* `cd_discover()` runs one registered method and returns a `cd_result` carrying
  the recovered graph in a single `amat.cpdag` adjacency convention, with timing
  and status.
* `cd_auto()` inspects a data set's characteristics with `cd_diagnose()`, routes
  it to a method suited to that regime, runs the best installed method on the
  route, and reports its rationale and a confidence label. `mode = "consensus"`
  returns a stability-weighted union of several methods with per-edge agreement.
  Given an evaluable density rather than a sample -- a `proxymix` mixture or
  target -- it reads the conditional-independence structure off the mixture in
  closed form.
* `list_methods()` and `register_method()` expose and extend the registry of
  sixteen built-in methods, drawn from `pcalg`, `bnlearn`, and Python back-ends
  reached through `reticulate`. Each method is gated on its back-end, so the
  harness, scenarios, metrics, and routing logic run with no suggested package
  installed.
* `cd_scenario()` and `cd_scenarios()` generate benchmark data from known DAGs,
  and `cd_score()` and `cd_benchmark()` score recovered graphs with skeleton F1,
  structural Hamming distance, and orientation recall.
* `cd_field_benchmark` ships a summary of the sixteen methods across the nine
  scenarios, the evidence behind the recommender's routing preferences.
* `as_orchestra_manifest()` adapts a `cd_result` into a versioned, integrity-hashed
  `orchestra_manifest` (`inferential_target = "structure"`): the recovered edges
  ride in `params`, and the method, routing rationale, confidence, and
  single-method-versus-consensus flag ride in the typed `summary` and `metadata`,
  so a recovered graph can be passed downstream with its provenance and verified
  with `verify_manifest()`.
