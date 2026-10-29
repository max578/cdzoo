# Plot a discovery result as a graph

Draws the recovered graph with the variables on a circle and an arrow
for each directed edge, a plain segment for each undirected one. It uses
base graphics only, so it needs no plotting back-end.

## Arguments

- x:

  A [cd_result](https://max578.github.io/cdzoo/reference/cd_result.md)
  with a non-empty graph.

- ...:

  Further graphical parameters passed to the node points.

## Value

`x`, invisibly.

## Examples

``` r
g <- matrix(0, 3, 3, dimnames = list(paste0("x", 1:3), paste0("x", 1:3)))
g["x1", "x2"] <- 1
g["x2", "x3"] <- 1
plot(cd_result(graph = g, method = "demo"))
```
