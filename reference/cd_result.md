# A causal-discovery result

The object returned by
[`cd_discover()`](https://max578.github.io/cdzoo/reference/cd_discover.md)
and [`cd_auto()`](https://max578.github.io/cdzoo/reference/cd_auto.md).
It holds the recovered graph as an adjacency matrix in the `pcalg`
`amat.cpdag` convention, where `graph[i, j] == 1` and `graph[j, i] == 0`
encodes the directed edge \\i \rightarrow j\\, and
`graph[i, j] == graph[j, i] == 1` encodes an undirected (unoriented)
edge \\i - j\\.

## Usage

``` r
cd_result(
  graph = numeric(0),
  method = NA_character_,
  method_name = "",
  family = NA_character_,
  language = "R",
  output = "cpdag",
  runtime_s = NA_real_,
  status = "ok",
  rationale = "",
  confidence = NA_character_,
  alternatives = list(),
  provenance = list()
)
```

## Arguments

- graph:

  A square numeric adjacency matrix in the `amat.cpdag` convention, with
  variable names as dimnames; empty when the method failed.

- method:

  A single string: the identifier of the method that produced the
  result.

- method_name:

  A single string: the human-readable method name.

- family:

  A single string: the algorithm family (constraint, score, functional,
  continuous-optimisation, hybrid, or density).

- language:

  A single string: the back-end language, `"R"` or `"Python"`.

- output:

  A single string: the native output type, one of `"dag"`, `"cpdag"`, or
  `"pag"`.

- runtime_s:

  A single number: wall-clock runtime in seconds.

- status:

  A single string: `"ok"`, or a short error description.

- rationale:

  A single string: why the recommender chose this method.

- confidence:

  A single string: `"high"`, `"moderate"`, or `"low"`.

- alternatives:

  A list of method labels the recommender considered as alternatives, in
  its preference order.

- provenance:

  A list of call metadata (data characteristics, options).

## Value

An S7 object of class `cd_result`.

## Details

The `rationale`, `confidence`, and `alternatives` properties are
populated by
[`cd_auto()`](https://max578.github.io/cdzoo/reference/cd_auto.md) and
are empty for a single-method
[`cd_discover()`](https://max578.github.io/cdzoo/reference/cd_discover.md)
call.

## See also

Other results:
[`cd_edges()`](https://max578.github.io/cdzoo/reference/cd_edges.md)

## Examples

``` r
g <- matrix(c(0, 0, 1, 0), 2, 2,
            dimnames = list(c("x1", "x2"), c("x1", "x2")))
cd_result(graph = g, method = "pc_pcalg", method_name = "PC (Fisher-Z)")
#> <cd_result>: PC (Fisher-Z) [?, R]
#>   status    : ok
#>   variables : 2 (x1, x2)
#>   edges     : 1 directed, 0 undirected
```
