# Discover a causal graph from a sufficient statistic

Runs constraint-based discovery directly on a correlation (or
covariance) matrix and its sample size, returning a
[cd_result](https://max578.github.io/cdzoo/reference/cd_result.md) in
the same `amat.cpdag` convention as
[`cd_discover()`](https://max578.github.io/cdzoo/reference/cd_discover.md).
This is the entry point for data that arrives already aggregated – a
published correlation matrix, a privacy-preserving summary, or the
output of
[`cd_correlation_from_counts()`](https://max578.github.io/cdzoo/reference/cd_correlation_from_counts.md)
– with no row-level observation matrix to pass to
[`cd_discover()`](https://max578.github.io/cdzoo/reference/cd_discover.md).

## Usage

``` r
cd_discover_suffstat(
  C,
  n,
  method = c("pc", "fci", "ggm"),
  test = c("gauss", "magnitude"),
  alpha = 0.05,
  tau = 0.05
)
```

## Arguments

- C:

  A square correlation or covariance matrix; covariance input is
  standardised. Variable names are taken from its dimnames.

- n:

  A single positive number: the sample size the statistic summarises.

- method:

  One of `"pc"` (default), `"fci"`, or `"ggm"`.

- test:

  One of `"gauss"` (default) or `"magnitude"`.

- alpha:

  The Fisher-Z significance level for `test = "gauss"`.

- tau:

  The partial-correlation magnitude threshold for `test = "magnitude"`
  and for `method = "ggm"`.

## Value

A [cd_result](https://max578.github.io/cdzoo/reference/cd_result.md)
whose `provenance$source` is `"suffstat"`.

## Details

`method = "ggm"` returns the Gaussian-graphical-model skeleton (an
undirected edge wherever the partial correlation given all other
variables clears `tau`) and needs no back-end. `method = "pc"` and
`method = "fci"` run the PC and FCI algorithms from `pcalg` and add such
orientation as the data identify; FCI additionally allows latent
confounders.

`test = "gauss"` uses the Fisher-Z significance test at level `alpha`,
as
[`cd_discover()`](https://max578.github.io/cdzoo/reference/cd_discover.md)
does. `test = "magnitude"` instead prunes an edge when the partial
correlation magnitude falls below `tau`; use it when `n` is so large
that a significance test would call every pair dependent.

## See also

[`cd_discover()`](https://max578.github.io/cdzoo/reference/cd_discover.md),
[`cd_correlation_from_counts()`](https://max578.github.io/cdzoo/reference/cd_correlation_from_counts.md),
[`cd_score()`](https://max578.github.io/cdzoo/reference/cd_score.md)

## Examples

``` r
if (requireNamespace("pcalg", quietly = TRUE)) {
  sim <- cd_scenario("linear_gaussian", seed = 1)
  # discover from the sufficient statistic alone -- no row-level data
  res <- cd_discover_suffstat(stats::cor(sim$data), nrow(sim$data), "pc")
  cd_score(res, sim$truth)
}
#>   skeleton_f1 skeleton_precision skeleton_recall shd orient_recall
#> 1           1                  1               1   3     0.5714286
```
