# The built-in benchmark scenarios

Lists the structural-causal-model scenarios available to
[`cd_scenario()`](https://max578.github.io/cdzoo/reference/cd_scenario.md)
and
[`cd_benchmark()`](https://max578.github.io/cdzoo/reference/cd_benchmark.md).

## Usage

``` r
cd_scenarios()
```

## Value

A data frame with columns `name`, `p`, `n`, `family`, and `description`.

## See also

[`cd_scenario()`](https://max578.github.io/cdzoo/reference/cd_scenario.md),
[`cd_benchmark()`](https://max578.github.io/cdzoo/reference/cd_benchmark.md)

## Examples

``` r
cd_scenarios()
#>               name  p   n                 family
#> 1  linear_gaussian  6 500        linear-Gaussian
#> 2   linear_laplace  6 500    linear-non-Gaussian
#> 3   linear_bimodal  6 500      linear-multimodal
#> 4  linear_scalemix  6 500 linear-heteroscedastic
#> 5    nonlinear_anm  6 500     nonlinear-additive
#> 6    dense_bimodal  6 800       dense-multimodal
#> 7       larger_p10 10 800      larger-multimodal
#> 8          small_n  6 150  low-sample-multimodal
#> 9 regime_switching  5 800  heterogeneous-regimes
#>                                              description
#> 1 Gaussian noise; constraint- and score-based territory.
#> 2   Heavy-tailed Laplace noise; LiNGAM-family territory.
#> 3                        Strongly bimodal mixture noise.
#> 4        Scale-mixture (heteroscedastic-marginal) noise.
#> 5                        Nonlinear additive-noise chain.
#> 6 Denser graph with bimodal noise (edge-density stress).
#> 7        Ten variables with bimodal noise (scalability).
#> 8                  Bimodal noise at a small sample size.
#> 9         Sign-flipping edges across two latent regimes.
```
