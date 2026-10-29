# A sufficient statistic as a discovery input

Wraps a correlation (or covariance) matrix and its sample size as a
tagged object that
[`cd_auto()`](https://max578.github.io/cdzoo/reference/cd_auto.md)
accepts in place of a data matrix, so the recommender can route and run
on data that arrives already aggregated. The matrix is validated and
standardised exactly as
[`cd_discover_suffstat()`](https://max578.github.io/cdzoo/reference/cd_discover_suffstat.md)
does.

## Usage

``` r
cd_suffstat(C, n)
```

## Arguments

- C:

  A square correlation or covariance matrix; covariance input is
  standardised. Variable names are taken from its dimnames.

- n:

  A single positive number: the sample size the statistic summarises.

## Value

An object of class `cd_suffstat`: a list with the validated correlation
matrix `C` and the sample size `n`.

## See also

[`cd_auto()`](https://max578.github.io/cdzoo/reference/cd_auto.md),
[`cd_discover_suffstat()`](https://max578.github.io/cdzoo/reference/cd_discover_suffstat.md)

## Examples

``` r
sim <- cd_scenario("linear_gaussian", seed = 1)
ss <- cd_suffstat(stats::cor(sim$data), nrow(sim$data))
ss$n
#> [1] 500
```
