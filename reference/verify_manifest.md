# Verify a manifest's payload integrity

Recomputes the payload hash from the object's own load-bearing slots and
compares it to the stored `data_hash`. A mismatch means the payload was
modified after emission. Matches the reference contract's
`verify_manifest()`.

## Usage

``` r
verify_manifest(m)
```

## Arguments

- m:

  An `orchestra_manifest` object.

## Value

A list with logical `ok` and a human-readable `message`.

## See also

[`as_orchestra_manifest()`](https://max578.github.io/cdzoo/reference/as_orchestra_manifest.md)

## Examples

``` r
g <- matrix(c(0, 0, 1, 0), 2, 2,
            dimnames = list(c("x1", "x2"), c("x1", "x2")))
m <- as_orchestra_manifest(cd_result(graph = g, method = "demo"))
verify_manifest(m)
#> $ok
#> [1] TRUE
#> 
#> $message
#> [1] "data_hash verified"
#> 
```
