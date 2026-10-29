# Benchmark discovery methods across the scenario grid

Runs each installed method across the chosen scenarios and seeds, scores
every run against the scenario's known truth with
[`cd_score()`](https://max578.github.io/cdzoo/reference/cd_score.md),
and returns the per-run results as a tidy data frame. Each run is
isolated, so a back-end that errors on a cell records a failed status
rather than stopping the benchmark.

## Usage

``` r
cd_benchmark(
  methods = NULL,
  scenarios = NULL,
  seeds = 1:4,
  cost_limit = c("medium", "fast", "slow", "very_slow"),
  verbose = TRUE,
  mc.cores = 1L
)
```

## Arguments

- methods:

  A character vector of method ids to run, or `NULL` (the default) for
  every installed method.

- scenarios:

  A character vector of scenario names, or `NULL` (the default) for all
  of them.

- seeds:

  An integer vector of seeds; each scenario is realised once per seed.

- cost_limit:

  A single string: the costliest method tier to include, one of
  `"fast"`, `"medium"`, `"slow"`, or `"very_slow"`.

- verbose:

  A single logical: report progress per scenario.

- mc.cores:

  A single positive integer: the number of cores to run the grid on. The
  default `1L` runs serially. Each cell is deterministic given its
  scenario seed and independent of the others, so the result is
  identical for any core count; parallel execution uses
  [`parallel::mclapply()`](https://rdrr.io/r/parallel/mclapply.html)
  (which falls back to serial on Windows).

## Value

A data frame with one row per (scenario, method, seed) run, with columns
`scenario`, `family`, `method`, `method_family`, `language`, `seed`,
`status`, `skeleton_f1`, `shd`, `orient_recall`, and `runtime_s`.

## Details

The default skips methods costlier than `cost_limit` so a first pass is
quick; raise the limit to include the slower kernel and search methods.
With no back-end installed the result has zero rows. A requested method
that cannot run is dropped with a warning naming it and the reason (an
unknown id, an absent back-end, or a cost above the limit) – never
silently.

## See also

[`cd_scenario()`](https://max578.github.io/cdzoo/reference/cd_scenario.md),
[`cd_score()`](https://max578.github.io/cdzoo/reference/cd_score.md),
[`list_methods()`](https://max578.github.io/cdzoo/reference/list_methods.md)

## Examples

``` r
if (requireNamespace("pcalg", quietly = TRUE)) {
  res <- cd_benchmark(
    methods = "pc_pcalg",
    scenarios = "linear_gaussian",
    seeds = 1:2, verbose = FALSE
  )
  res[, c("scenario", "method", "skeleton_f1", "shd")]
}
#>          scenario   method skeleton_f1 shd
#> 1 linear_gaussian pc_pcalg           1   3
#> 2 linear_gaussian pc_pcalg           1   0
```
