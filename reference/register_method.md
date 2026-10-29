# Register a discovery method

Adds a
[cd_method](https://max578.github.io/cdzoo/reference/cd_method.md) to
the registry so it can be run by
[`cd_discover()`](https://max578.github.io/cdzoo/reference/cd_discover.md)
and considered by
[`cd_auto()`](https://max578.github.io/cdzoo/reference/cd_auto.md).
Registering a method with the id of an existing one replaces it.

## Usage

``` r
register_method(method)
```

## Arguments

- method:

  A [cd_method](https://max578.github.io/cdzoo/reference/cd_method.md)
  to register.

## Value

The method id, invisibly.

## See also

Other registry:
[`cd_method()`](https://max578.github.io/cdzoo/reference/cd_method.md),
[`list_methods()`](https://max578.github.io/cdzoo/reference/list_methods.md)

## Examples

``` r
m <- cd_method(
  id = "noop", name = "No-op", family = "constraint",
  available = function() TRUE,
  run = function(data) list(amat = NULL, runtime_s = 0, status = "ok")
)
register_method(m)
"noop" %in% list_methods()$id
#> [1] TRUE
```
