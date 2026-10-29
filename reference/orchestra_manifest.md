# The federation manifest contract (cdzoo-side implementation)

A versioned, hashed, provenance-complete S7 result object,
property-compatible with the federation's reference
`orchestra_manifest`. A
[cd_result](https://max578.github.io/cdzoo/reference/cd_result.md) is
adapted into one through
[`as_orchestra_manifest()`](https://max578.github.io/cdzoo/reference/as_orchestra_manifest.md):
the recovered edges ride in `params`
(`inferential_target = "structure"`), the method, routing rationale,
confidence, and consensus flag ride in `metadata` and the typed
`summary`, and the payload is integrity-hashed so a tampered graph is
detected downstream.

## Value

An S7 object of class `orchestra_manifest`.

## See also

[`as_orchestra_manifest()`](https://max578.github.io/cdzoo/reference/as_orchestra_manifest.md),
[`verify_manifest()`](https://max578.github.io/cdzoo/reference/verify_manifest.md)

## Examples

``` r
g <- matrix(0, 2, 2, dimnames = list(c("x", "y"), c("x", "y")))
g["x", "y"] <- 1
m <- as_orchestra_manifest(cd_result(graph = g, method = "demo"))
m@inferential_target
#> [1] "structure"
m@summary$abstained
#> [1] FALSE
verify_manifest(m)$ok
#> [1] TRUE
```
