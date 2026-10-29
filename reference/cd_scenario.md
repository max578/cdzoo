# Generate a benchmark scenario with known ground truth

Realises one of the built-in structural-causal-model scenarios at a
given seed and returns the data together with the true graph, the
independent oracle a recovered structure is scored against by
[`cd_score()`](https://max578.github.io/cdzoo/reference/cd_score.md).

## Usage

``` r
cd_scenario(name, seed = 1L)
```

## Arguments

- name:

  A single string: the scenario name (see
  [`cd_scenarios()`](https://max578.github.io/cdzoo/reference/cd_scenarios.md)).

- seed:

  A single integer-valued seed for reproducibility; any finite number is
  accepted (a value beyond integer range is folded back into it).

## Value

A list with `data` (the observation matrix), `truth` (the true graph in
`amat.cpdag` convention), `dag` (the raw simulator DAG), `scenario`,
`family`, `p`, and `n`.

## See also

[`cd_scenarios()`](https://max578.github.io/cdzoo/reference/cd_scenarios.md),
[`cd_score()`](https://max578.github.io/cdzoo/reference/cd_score.md),
[`cd_benchmark()`](https://max578.github.io/cdzoo/reference/cd_benchmark.md)

## Examples

``` r
sim <- cd_scenario("linear_gaussian", seed = 1)
dim(sim$data)
#> [1] 500   6
sim$truth
#>    x1 x2 x3 x4 x5 x6
#> x1  0  1  0  0  1  1
#> x2  0  0  1  1  0  0
#> x3  0  0  0  1  0  1
#> x4  0  0  0  0  0  0
#> x5  0  0  0  0  0  0
#> x6  0  0  0  0  0  0
```
