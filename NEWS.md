# cdzoo 0.1.1

## Minor improvements and fixes

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
