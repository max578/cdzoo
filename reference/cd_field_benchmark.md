# Field benchmark of causal-discovery methods across scenarios

A summary of sixteen established causal-discovery methods run across the
nine structural-causal-model scenarios of
[`cd_scenarios()`](https://max578.github.io/cdzoo/reference/cd_scenarios.md),
each method scored against the scenario's known DAG and averaged over
random-graph seeds. It is the evidence that grounds the routing
preferences in
[`cd_auto()`](https://max578.github.io/cdzoo/reference/cd_auto.md), and
the worked example in the package vignette.

## Usage

``` r
cd_field_benchmark
```

## Format

A data frame with 143 rows and 11 columns:

- scenario:

  Scenario name (see
  [`cd_scenarios()`](https://max578.github.io/cdzoo/reference/cd_scenarios.md)).

- scenario_family:

  The scenario's structural-causal-model family.

- method:

  Method id (see
  [`list_methods()`](https://max578.github.io/cdzoo/reference/list_methods.md)).

- method_name:

  Human-readable method name.

- family:

  Algorithm family.

- shd:

  Mean structural Hamming distance to the true DAG (lower is better).

- shd_sd:

  Standard deviation of the structural Hamming distance across seeds.

- skeleton_f1:

  Mean skeleton (adjacency) F1 (higher is better).

- orient_recall:

  Mean orientation recall.

- runtime_s:

  Mean wall-clock runtime in seconds.

- n_seed:

  Number of random-graph seeds averaged.

## Details

One row per (scenario, method). The kernel conditional-independence
method (`pc_kci_cl`) was not run on the ten-variable scenario, so that
one (scenario, method) cell is absent, giving 143 rows.

## See also

[`cd_benchmark()`](https://max578.github.io/cdzoo/reference/cd_benchmark.md),
[`cd_auto()`](https://max578.github.io/cdzoo/reference/cd_auto.md),
[`cd_scenarios()`](https://max578.github.io/cdzoo/reference/cd_scenarios.md)

## Examples

``` r
# overall ranking by mean structural Hamming distance across scenarios
agg <- aggregate(shd ~ method_name, data = cd_field_benchmark, FUN = mean)
agg[order(agg$shd), ]
#>                   method_name       shd
#> 5                       GOLEM 0.9444444
#> 1              DAGMA (linear) 1.2361111
#> 9                  ICA-LiNGAM 1.5277778
#> 11           NOTEARS (linear) 1.8611111
#> 2                DirectLiNGAM 2.4722222
#> 16               Tabu (BIC-g) 3.0833333
#> 7       Hill-Climbing (BIC-g) 3.3750000
#> 10                       MMHC 3.4027778
#> 15 RCD (latent-robust LiNGAM) 4.3333333
#> 13       PC + KCI (kernel CI) 4.7812500
#> 12              PC (Fisher-Z) 4.8472222
#> 6                 Grow-Shrink 4.8611111
#> 8                        IAMB 4.9722222
#> 4                   GES (BIC) 5.1666667
#> 14                  PC-stable 5.5972222
#> 3                         FCI 7.8611111
```
