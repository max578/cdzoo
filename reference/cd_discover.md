# Discover a causal graph with one method

Runs a single registered discovery method on a data set and returns the
recovered graph as a
[cd_result](https://max578.github.io/cdzoo/reference/cd_result.md). Use
[`list_methods()`](https://max578.github.io/cdzoo/reference/list_methods.md)
to see the registered methods and which back-ends are installed, and
[`cd_auto()`](https://max578.github.io/cdzoo/reference/cd_auto.md) to
let the recommender choose a method for you.

## Usage

``` r
cd_discover(data, method)
```

## Arguments

- data:

  A numeric matrix or data frame of observations (rows) by variables
  (columns).

- method:

  A single string: the id of a registered method (see
  [`list_methods()`](https://max578.github.io/cdzoo/reference/list_methods.md)).

## Value

A [cd_result](https://max578.github.io/cdzoo/reference/cd_result.md).
When the back-end raises an error, the result carries an empty graph and
the error in its `status`; an absent back-end is a hard error pointing
at the package or module to install.

## Details

A method that consumes a sufficient statistic (its `accepts` is
`"suffstat"`, such as `"pc_suffstat"`) can still be run here on a data
matrix: the data is reduced to its correlation matrix and sample size
first. To run such a method on an already-aggregated statistic instead,
use
[`cd_discover_suffstat()`](https://max578.github.io/cdzoo/reference/cd_discover_suffstat.md).

## See also

[`cd_auto()`](https://max578.github.io/cdzoo/reference/cd_auto.md),
[`list_methods()`](https://max578.github.io/cdzoo/reference/list_methods.md),
[`cd_score()`](https://max578.github.io/cdzoo/reference/cd_score.md)

## Examples

``` r
if (requireNamespace("pcalg", quietly = TRUE)) {
  sim <- cd_scenario("linear_gaussian", seed = 1)
  res <- cd_discover(sim$data, "pc_pcalg")
  res
}
#> <cd_result>: PC (Fisher-Z) [constraint, R]
#>   status    : ok
#>   variables : 6 (x1, x2, x3, x4, x5, x6)
#>   edges     : 7 directed, 0 undirected
#>   runtime   : 0.00973s
```
