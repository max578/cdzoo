# Package index

## Discover a graph

Run a method, or let the recommender choose one.

- [`cd_discover()`](https://max578.github.io/cdzoo/reference/cd_discover.md)
  : Discover a causal graph with one method
- [`cd_auto()`](https://max578.github.io/cdzoo/reference/cd_auto.md) :
  Recommend and run a causal-discovery method for a data set
- [`cd_diagnose()`](https://max578.github.io/cdzoo/reference/cd_diagnose.md)
  : Describe the characteristics of a discovery data set
- [`cd_explain()`](https://max578.github.io/cdzoo/reference/cd_explain.md)
  : Explain a discovery recommendation in words

## Discovery from a sufficient statistic

Run discovery on an aggregated correlation matrix rather than row-level
data.

- [`cd_discover_suffstat()`](https://max578.github.io/cdzoo/reference/cd_discover_suffstat.md)
  : Discover a causal graph from a sufficient statistic
- [`cd_correlation_from_counts()`](https://max578.github.io/cdzoo/reference/cd_correlation_from_counts.md)
  : Assemble a correlation matrix from pairwise binary counts
- [`cd_suffstat()`](https://max578.github.io/cdzoo/reference/cd_suffstat.md)
  : A sufficient statistic as a discovery input

## Results

The discovery-result object and its accessors.

- [`cd_result()`](https://max578.github.io/cdzoo/reference/cd_result.md)
  : A causal-discovery result
- [`cd_edges()`](https://max578.github.io/cdzoo/reference/cd_edges.md) :
  Edge list of a discovery result
- [`plot.cd_result`](https://max578.github.io/cdzoo/reference/plot.cd_result.md)
  : Plot a discovery result as a graph

## Federation manifest

Emit and verify a versioned, integrity-hashed result manifest.

- [`as_orchestra_manifest()`](https://max578.github.io/cdzoo/reference/as_orchestra_manifest.md)
  : Emit a discovery result as a federation manifest
- [`verify_manifest()`](https://max578.github.io/cdzoo/reference/verify_manifest.md)
  : Verify a manifest's payload integrity
- [`orchestra_manifest`](https://max578.github.io/cdzoo/reference/orchestra_manifest.md)
  : The federation manifest contract (cdzoo-side implementation)

## The method registry

Inspect and extend the portfolio of methods.

- [`list_methods()`](https://max578.github.io/cdzoo/reference/list_methods.md)
  : The registered discovery methods
- [`register_method()`](https://max578.github.io/cdzoo/reference/register_method.md)
  : Register a discovery method
- [`cd_method()`](https://max578.github.io/cdzoo/reference/cd_method.md)
  : A causal-discovery method specification

## Scenarios, metrics, and benchmarking

Generate known-truth data and score recovered graphs.

- [`cd_scenario()`](https://max578.github.io/cdzoo/reference/cd_scenario.md)
  : Generate a benchmark scenario with known ground truth
- [`cd_scenarios()`](https://max578.github.io/cdzoo/reference/cd_scenarios.md)
  : The built-in benchmark scenarios
- [`cd_score()`](https://max578.github.io/cdzoo/reference/cd_score.md) :
  Score a recovered graph against a known truth
- [`cd_benchmark()`](https://max578.github.io/cdzoo/reference/cd_benchmark.md)
  : Benchmark discovery methods across the scenario grid
- [`cd_field_benchmark`](https://max578.github.io/cdzoo/reference/cd_field_benchmark.md)
  : Field benchmark of causal-discovery methods across scenarios
