# Emit a discovery result as a federation manifest

The federation's emit / adapt generic. The
[cd_result](https://max578.github.io/cdzoo/reference/cd_result.md)
method turns a recovered graph into the shared `orchestra_manifest`
contract: `inferential_target = "structure"`, the recovered edges
carried as a tidy `params` edge list, and the provenance – which method
ran, the routing rationale, the routing confidence, and whether the
result is a single method or a consensus – in the typed `summary` and
`metadata`. The full adjacency matrix (and, for a consensus, the
per-edge agreement) rides in `metadata` for a consumer that wants the
matrix rather than the edge list. When no graph was recovered (an absent
back-end), the manifest abstains and says so. The payload is
integrity-hashed so a consumer can verify it with
[`verify_manifest()`](https://max578.github.io/cdzoo/reference/verify_manifest.md).

## Usage

``` r
as_orchestra_manifest(x, ...)
```

## Arguments

- x:

  A [cd_result](https://max578.github.io/cdzoo/reference/cd_result.md).

- ...:

  Further arguments passed to methods. The
  [cd_result](https://max578.github.io/cdzoo/reference/cd_result.md)
  method accepts `run_id` (an optional character run identifier; a
  content hash is derived when omitted, so two identical results get the
  same identifier) and `seed` (an optional integer recorded for
  reproducibility).

## Value

An `orchestra_manifest` S7 object.

## See also

[`verify_manifest()`](https://max578.github.io/cdzoo/reference/verify_manifest.md),
[`cd_auto()`](https://max578.github.io/cdzoo/reference/cd_auto.md),
[`cd_discover()`](https://max578.github.io/cdzoo/reference/cd_discover.md)

## Examples

``` r
g <- matrix(c(0, 0, 1, 0), 2, 2,
            dimnames = list(c("x1", "x2"), c("x1", "x2")))
as_orchestra_manifest(cd_result(graph = g, method = "demo",
                                method_name = "Demo", family = "constraint"))
#> <cdzoo::orchestra_manifest>
#>  @ manifest_version  : chr "2.0.0-draft"
#>  @ emitter_package   : chr "cdzoo"
#>  @ emitter_version   : chr "0.2.0.9000"
#>  @ inferential_target: chr "structure"
#>  @ run_id            : chr "cdzoo-ca3ace1de21f"
#>  @ method            : chr "cdzoo:demo"
#>  @ seed              : int NA
#>  @ params            :'data.frame':  1 obs. of  3 variables:
#>  .. $ from: chr "x1"
#>  .. $ to  : chr "x2"
#>  .. $ type: chr "-->"
#>  @ outputs           : NULL
#>  @ weights           : NULL
#>  @ obs_target        : NULL
#>  @ obs_schema        : NULL
#>  @ summary           :List of 4
#>  .. $ headline      : chr "1 edges (1 directed, 0 undirected) via Demo"
#>  .. $ abstained     : logi FALSE
#>  .. $ abstain_reason: chr NA
#>  .. $ metrics       :List of 9
#>  ..  ..$ method      : chr "demo"
#>  ..  ..$ family      : chr "constraint"
#>  ..  ..$ language    : chr "R"
#>  ..  ..$ n_edges     : int 1
#>  ..  ..$ n_directed  : int 1
#>  ..  ..$ n_undirected: int 0
#>  ..  ..$ confidence  : chr NA
#>  ..  ..$ consensus   : logi FALSE
#>  ..  ..$ p           : int 2
#>  .. - attr(*, "class")= chr "manifest_summary"
#>  @ consumed_manifests: list()
#>  @ metadata          :List of 11
#>  .. $ derived     : logi FALSE
#>  .. $ method      : chr "demo"
#>  .. $ family      : chr "constraint"
#>  .. $ language    : chr "R"
#>  .. $ output      : chr "cpdag"
#>  .. $ rationale   : chr ""
#>  .. $ confidence  : chr NA
#>  .. $ consensus   : logi FALSE
#>  .. $ amat        : num [1:2, 1:2] 0 0 1 0
#>  ..  ..- attr(*, "dimnames")=List of 2
#>  ..  .. ..$ : chr [1:2] "x1" "x2"
#>  ..  .. ..$ : chr [1:2] "x1" "x2"
#>  .. $ agreement   : NULL
#>  .. $ alternatives: list()
#>  @ timestamp         : POSIXct[1:1], format: "2026-10-29 03:52:17"
#>  @ data_hash         : chr "sha256:ca3ace1de21fa2244d2d5239265d0b32abb70dbb1437d3a3d5f352cce5b902cd"
```
