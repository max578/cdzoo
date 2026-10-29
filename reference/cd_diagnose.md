# Describe the characteristics of a discovery data set

Reports the data characteristics the recommender uses to route a
problem, as a one-row data frame. Use it to see what
[`cd_auto()`](https://max578.github.io/cdzoo/reference/cd_auto.md) sees
before it chooses a method.

## Usage

``` r
cd_diagnose(data)
```

## Arguments

- data:

  A numeric matrix or data frame of observations (rows) by variables
  (columns).

## Value

A one-row data frame of the characteristics described in
[`cd_auto()`](https://max578.github.io/cdzoo/reference/cd_auto.md)'s
routing.

## Details

On large data sets the statistics are computed on a deterministic,
evenly spaced subsample of rows (at most 5000 rows for the normality
test, 2000 for the regression heuristics), so the diagnostics are pure:
repeated calls on the same data return the same characteristics, and the
caller's random-number state is never touched.

## See also

[`cd_auto()`](https://max578.github.io/cdzoo/reference/cd_auto.md)

## Examples

``` r
sim <- cd_scenario("linear_laplace", seed = 1)
cd_diagnose(sim$data)
#>     n p non_gaussian_fraction mean_abs_kurtosis equal_variance_ratio
#> 1 500 6                     1             1.408                3.327
#>   nonlinearity condition_number
#> 1        0.006             23.6
```
