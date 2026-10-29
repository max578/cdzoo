# Edge list of a discovery result

Returns the edges of a
[cd_result](https://max578.github.io/cdzoo/reference/cd_result.md) (or a
bare adjacency matrix) as a data frame, one row per edge, with the
orientation made explicit.

## Usage

``` r
cd_edges(x, agreement = FALSE)
```

## Arguments

- x:

  A [cd_result](https://max578.github.io/cdzoo/reference/cd_result.md)
  or a square adjacency matrix in `amat.cpdag` convention.

- agreement:

  A single logical. When `TRUE` and `x` is a consensus
  [cd_result](https://max578.github.io/cdzoo/reference/cd_result.md)
  carrying per-edge agreement (from
  [`cd_auto()`](https://max578.github.io/cdzoo/reference/cd_auto.md)
  with `mode = "consensus"`), an `agreement` column reports the share of
  the combined methods that found each edge. `NA` where no agreement is
  recorded.

## Value

A data frame with columns `from`, `to`, and `type` (`"-->"` for a
directed edge, `"---"` for an undirected one), and – when
`agreement = TRUE` – an `agreement` column. Zero rows when the graph is
empty.

## See also

Other results:
[`cd_result()`](https://max578.github.io/cdzoo/reference/cd_result.md)

## Examples

``` r
g <- matrix(c(0, 0, 1, 0), 2, 2,
            dimnames = list(c("x1", "x2"), c("x1", "x2")))
cd_edges(cd_result(graph = g, method = "demo"))
#>   from to type
#> 1   x1 x2  -->
```
