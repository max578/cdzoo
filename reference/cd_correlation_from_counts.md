# Assemble a correlation matrix from pairwise binary counts

Builds a positive-definite correlation matrix over a set of binary
variables from their pairwise two-by-two co-occurrence counts – the
aggregated form in which co-occurrence data (comorbidity, market-basket,
species co-occurrence) is usually published. The result feeds straight
into
[`cd_discover_suffstat()`](https://max578.github.io/cdzoo/reference/cd_discover_suffstat.md).

## Usage

``` r
cd_correlation_from_counts(pairs, type = c("phi", "tetra"), repair = TRUE)
```

## Arguments

- pairs:

  A data frame with one row per variable pair and columns `var_i`,
  `var_j` (the two variable identifiers) and `n11`, `n10`, `n01`, `n00`
  (the counts of: both present, the first only, the second only, both
  absent).

- type:

  `"phi"` (default; the Pearson correlation of the two indicators,
  base R) or `"tetra"` (the latent-Gaussian tetrachoric correlation,
  which needs the `psych` package).

- repair:

  Whether to project an indefinite matrix to the nearest
  positive-definite correlation matrix. Defaults to `TRUE`.

## Value

A correlation matrix with a `"repair"` attribute recording the minimum
eigenvalue before and after repair, the Frobenius distortion, and the
pair and variable counts.

## Details

A matrix assembled pair by pair is not guaranteed positive
semi-definite, so it is repaired to the nearest positive-definite
correlation matrix by eigenvalue clipping when `repair = TRUE`; the
eigenvalue floor reached and the repair distortion are recorded in the
result's `"repair"` attribute.

Every unordered variable pair must appear exactly once; a repeated pair
is an error rather than a silent overwrite. A pair that is absent from
`pairs` is taken to have zero correlation (the off-diagonal entry stays
zero before repair).

## See also

[`cd_discover_suffstat()`](https://max578.github.io/cdzoo/reference/cd_discover_suffstat.md)

## Examples

``` r
pairs <- data.frame(
  var_i = "a", var_j = "b",
  n11 = 900, n10 = 100, n01 = 100, n00 = 8900)
cd_correlation_from_counts(pairs)
#>           a         b
#> a 1.0000000 0.8888889
#> b 0.8888889 1.0000000
#> attr(,"repair")
#> attr(,"repair")$eig_min_raw
#> [1] 0.1111111
#> 
#> attr(,"repair")$eig_min
#> [1] 0.1111111
#> 
#> attr(,"repair")$distortion
#> [1] 0
#> 
#> attr(,"repair")$n_pairs
#> [1] 1
#> 
#> attr(,"repair")$n_vars
#> [1] 2
#> 
#> attr(,"repair")$type
#> [1] "phi"
#> 
```
