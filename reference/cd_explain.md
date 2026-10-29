# Explain a discovery recommendation in words

Prints a readable account of a
[cd_result](https://max578.github.io/cdzoo/reference/cd_result.md): the
method that ran and its status, the routing rationale and confidence,
the alternatives the recommender considered, the data-characteristic
thresholds that decided the route (when
[`cd_auto()`](https://max578.github.io/cdzoo/reference/cd_auto.md)
produced the result), and – for a `"consensus"` result – the per-edge
agreement among the combined methods. It is the auditable companion to
[`print()`](https://rdrr.io/r/base/print.html), which stays compact.

## Usage

``` r
cd_explain(x)
```

## Arguments

- x:

  A [cd_result](https://max578.github.io/cdzoo/reference/cd_result.md),
  typically from
  [`cd_auto()`](https://max578.github.io/cdzoo/reference/cd_auto.md).

## Value

`x`, invisibly. Called for the account it prints.

## See also

[`cd_auto()`](https://max578.github.io/cdzoo/reference/cd_auto.md),
[cd_result](https://max578.github.io/cdzoo/reference/cd_result.md),
[`cd_edges()`](https://max578.github.io/cdzoo/reference/cd_edges.md)

## Examples

``` r
if (requireNamespace("pcalg", quietly = TRUE)) {
  sim <- cd_scenario("linear_laplace", seed = 1)
  cd_explain(cd_auto(sim$data, report = FALSE))
}
#> Recommendation: ICA-LiNGAM
#>   family    : functional (R)
#>   status    : recommendation only (report = FALSE)
#> 
#> Why this method:
#>   100% of variables depart from normality (mean |excess kurtosis| 1.41);
#>   the LiNGAM family exploits non-Gaussianity for orientation and is fast
#> 
#> Confidence: high
#> 
#> Alternatives considered (preference order):
#>   ICA-LiNGAM, DirectLiNGAM, RCD (latent-robust LiNGAM), DAGMA (linear)
#> 
#> Routing thresholds:
#>   nonlinearity           0.05
#>   non_gaussian_fraction  0.5
#>   condition_number       1000
#>   equal_variance_ratio   2
```
