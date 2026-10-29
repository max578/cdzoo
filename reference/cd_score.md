# Score a recovered graph against a known truth

Compares a discovery result – a
[cd_result](https://max578.github.io/cdzoo/reference/cd_result.md) or a
bare adjacency matrix – with the true graph and returns the skeleton,
distance, and orientation metrics. The truth is typically the `truth`
element of a
[`cd_scenario()`](https://max578.github.io/cdzoo/reference/cd_scenario.md).

## Usage

``` r
cd_score(x, truth)
```

## Arguments

- x:

  A [cd_result](https://max578.github.io/cdzoo/reference/cd_result.md)
  or a square adjacency matrix in `amat.cpdag` convention.

- truth:

  The true graph in `amat.cpdag` convention (for example
  `cd_scenario(...)$truth`).

## Value

A one-row data frame with `skeleton_f1`, `skeleton_precision`,
`skeleton_recall`, `shd`, and `orient_recall`. `skeleton_f1` is `NA`
when the truth has no edges (recall is undefined there); an empty
estimate against a non-empty truth scores 0.

## Details

Both matrices are normalised before scoring, so any non-zero entry
counts as an edge mark and the three metrics see the same graph whether
the input is 0/1 or weighted. When the estimate carries no dimnames but
matches the truth's dimensions, it is scored positionally against the
truth's variable order.

## See also

[`cd_scenario()`](https://max578.github.io/cdzoo/reference/cd_scenario.md),
[`cd_benchmark()`](https://max578.github.io/cdzoo/reference/cd_benchmark.md)

## Examples

``` r
if (requireNamespace("pcalg", quietly = TRUE)) {
  sim <- cd_scenario("linear_gaussian", seed = 1)
  res <- cd_discover(sim$data, "pc_pcalg")
  cd_score(res, sim$truth)
}
#>   skeleton_f1 skeleton_precision skeleton_recall shd orient_recall
#> 1           1                  1               1   3     0.5714286
```
