# Recommend and run a causal-discovery method for a data set

Inspects a data set with
[`cd_diagnose()`](https://max578.github.io/cdzoo/reference/cd_diagnose.md)'s
transparent characteristics, routes it to a discovery method suited to
that regime, runs the best installed method on the route, and returns
the recovered graph together with the routing rationale and a confidence
label. Because causal discovery has no run-time ground truth, this is a
recommender, not a selector: it reports why it chose and how sure it is,
and – in `"consensus"` mode – returns a stability-weighted union of
several methods with per-edge agreement.

## Usage

``` r
cd_auto(
  data,
  mode = c("route", "consensus"),
  report = TRUE,
  top_k = 3L,
  threshold = 0.05,
  density_components = 4L
)
```

## Arguments

- data:

  A numeric matrix or data frame of observations by variables, an
  evaluable-density object (a proxymix `gmm` / `gmm_fit` /
  `gmm_target`), or a sufficient statistic
  ([`cd_suffstat()`](https://max578.github.io/cdzoo/reference/cd_suffstat.md)).

- mode:

  `"route"` (run the single recommended method) or `"consensus"` (run
  the top `top_k` installed methods on the route and return their
  stability-weighted union).

- report:

  A single logical. When `TRUE` (the default) the recommended method is
  run and its graph returned; when `FALSE` only the recommendation is
  returned, with an empty graph and the status
  `"recommendation only (report = FALSE)"`.

- top_k:

  The number of methods to combine in `"consensus"` mode.

- threshold:

  The partial-correlation edge threshold for the density route.

- density_components:

  The number of mixture components to fit when routing an evaluable
  target density.

## Value

A [cd_result](https://max578.github.io/cdzoo/reference/cd_result.md)
whose `rationale`, `confidence`, and `alternatives` (always a list of
method labels, in the route's preference order) record the
recommendation. In `"consensus"` mode the per-edge agreement and the
individual member results are stored in the result's `provenance` (as
`agreement` and `runs`).

## Details

The route is decided by four data-characteristic thresholds, checked in
this order and reported in the result's `provenance$thresholds`: a
curvature heuristic above `0.05` routes to a kernel
conditional-independence test; a non-Gaussian margin fraction of `0.5`
or more routes to the LiNGAM family; a correlation condition number
above `1000` (a latent-structure hint) routes to a confounder-robust
method; and a residual-variance ratio below `2` routes to the
equal-variance continuous-optimisation methods. Failing all four, the
benchmark's strongest overall method is used.

When `data` is an evaluable density rather than a sample – a proxymix
`gmm`, `gmm_fit`, or `gmm_target` (requires the suggested proxymix
package) – the conditional-independence (Markov) structure is read off
the mixture in closed form, the route for the case where a density can
be evaluated but not sampled.

When `data` is a sufficient statistic
([`cd_suffstat()`](https://max578.github.io/cdzoo/reference/cd_suffstat.md),
a correlation matrix and its sample size), the recommender routes among
the sufficient-statistic methods. A correlation matrix carries only the
latent-structure hint, so the rationale states plainly that the
non-Gaussianity, nonlinearity, and equal-variance tests could not be
run.

## See also

[`cd_diagnose()`](https://max578.github.io/cdzoo/reference/cd_diagnose.md),
[`cd_discover()`](https://max578.github.io/cdzoo/reference/cd_discover.md),
[`list_methods()`](https://max578.github.io/cdzoo/reference/list_methods.md)

## Examples

``` r
if (requireNamespace("pcalg", quietly = TRUE)) {
  sim <- cd_scenario("linear_laplace", seed = 1)
  rec <- cd_auto(sim$data, report = FALSE)
  rec@rationale
}
#> [1] "100% of variables depart from normality (mean |excess kurtosis| 1.41); the LiNGAM family exploits non-Gaussianity for orientation and is fast"
```
