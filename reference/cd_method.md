# A causal-discovery method specification

Bundles the metadata that drives selection – family, language, native
output type, cost, and assumptions – with the adapter that runs a
back-end algorithm on a data matrix and returns its estimate in the
shared `amat.cpdag` convention. The `available` predicate reports
whether the back-end can run in the current session, so a method whose
package or Python module is absent is skipped rather than failing.

## Usage

``` r
cd_method(
  id = character(0),
  name = "",
  family = "constraint",
  language = "R",
  output = "cpdag",
  citation = "",
  cost = "fast",
  assumptions = "",
  accepts = "data",
  available = function() NULL,
  run = function() NULL
)
```

## Arguments

- id:

  A single string identifying the method; this is the value passed to
  `method =` in
  [`cd_discover()`](https://max578.github.io/cdzoo/reference/cd_discover.md).

- name:

  A single string giving the human-readable method name.

- family:

  A single string naming the algorithm family, one of `"constraint"`,
  `"score"`, `"functional"`, `"continuous_optim"`, `"hybrid"`, or
  `"density"`.

- language:

  A single string, `"R"` or `"Python"`.

- output:

  A single string giving the native output type, one of `"dag"`,
  `"cpdag"`, or `"pag"`.

- citation:

  A single string citing the method's source.

- cost:

  A single string giving the rough computational cost, one of `"fast"`,
  `"medium"`, `"slow"`, or `"very_slow"`.

- assumptions:

  A single string describing the method's modelling assumptions.

- accepts:

  A single string naming the input the method's `run` consumes, `"data"`
  (the default; a numeric observation matrix) or `"suffstat"` (a
  sufficient statistic, the list `list(C, n)` of a correlation matrix
  and its sample size). A `"suffstat"` method can still be called on a
  data matrix –
  [`cd_discover()`](https://max578.github.io/cdzoo/reference/cd_discover.md)
  reduces the data to its sufficient statistic first.

- available:

  A function of no arguments returning a single logical: can the method
  run in the current session?

- run:

  A function taking the method's input (a numeric data matrix, or a
  `list(C, n)` sufficient statistic when `accepts = "suffstat"`) and
  returning a list with elements `amat` (the estimate in `amat.cpdag`
  convention, or `NULL`), `runtime_s`, and `status`.

## Value

An S7 object of class `cd_method`.

## See also

Other registry:
[`list_methods()`](https://max578.github.io/cdzoo/reference/list_methods.md),
[`register_method()`](https://max578.github.io/cdzoo/reference/register_method.md)

## Examples

``` r
cd_method(
  id = "demo", name = "Demo", family = "constraint",
  available = function() TRUE,
  run = function(data) list(amat = NULL, runtime_s = 0, status = "ok")
)
#> <cd_method 'demo'>: Demo [constraint, R]
#>   output     : cpdag
#>   cost       : fast
#>   available  : yes
```
