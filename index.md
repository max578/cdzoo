# cdzoo

`cdzoo` puts a portfolio of causal-discovery algorithms behind one
interface. R has strong individual packages – `pcalg`, `bnlearn` – but
no single harness that wraps R *and* Python algorithms in one
convention, with a scenario grid and fair metrics. `cdzoo` provides:

- a **registry** of nineteen discovery methods drawn from `pcalg`,
  `bnlearn`, and Python back-ends (LiNGAM, causal-learn, gCastle, DAGMA)
  reached through `reticulate`, of which sixteen are scored in the
  shipped field benchmark; each returns its estimate in one adjacency
  convention;
- an **evidence-routed recommender**,
  [`cd_auto()`](https://max578.github.io/cdzoo/reference/cd_auto.md),
  that inspects a data set, routes it to a method suited to that regime,
  runs it, and reports its rationale and a confidence label – a
  recommender, not a selector, because causal discovery has no run-time
  ground truth;
- a **scenario grid** of structural-causal-model regimes with known
  DAGs, and **metrics** (skeleton F1, structural Hamming distance,
  orientation recall) to score recovered graphs.

Every back-end is optional. The harness, the scenarios, the metrics, and
the recommender’s routing logic all run on a base installation; a method
runs only when its back-end is present.

## Related packages

- [pcalg](https://CRAN.R-project.org/package=pcalg) learns causal
  structure from observational and interventional data with PC, FCI,
  RFCI and GIES, and estimates causal effects with IDA and adjustment
  criteria.
- [bnlearn](https://CRAN.R-project.org/package=bnlearn) learns the
  structure and parameters of Bayesian networks with constraint-based,
  score-based and hybrid algorithms, and runs inference on the fitted
  network.
- [causalDisco](https://CRAN.R-project.org/package=causalDisco) learns
  causal structure from temporally ordered observational data, adds
  background knowledge to the pcalg, bnlearn and Tetrad algorithms, and
  compares and evaluates the learned graphs.

cdzoo calls pcalg and bnlearn as back-ends rather than replacing them.
It adds Python methods to the same registry, scores every method on
scenarios with known graphs, and recommends a method for a given data
set with the reasons for the choice.

## Installation

``` r

# install.packages("pak")
pak::pak("max578/cdzoo")
```

The R back-ends are installed with
`install.packages(c("pcalg", "bnlearn"))`. The Python back-ends are
reached through `reticulate`; install them into the active Python
environment (for example `lingam`, `causal-learn`, `gcastle`, `dagma`).

`cdzoo` never starts Python just to report availability: the Python
back-ends show as installed once reticulate’s interpreter is initialised
or configured (for example via `RETICULATE_PYTHON`). Set
`options(cdzoo.python_init = TRUE)` to let the availability check
initialise Python eagerly, and call `list_methods(refresh = TRUE)` after
installing a Python module mid-session.

## Usage

``` r

library(cdzoo)

# what is registered, and which back-ends are installed?
list_methods()

# generate data from a known DAG, then recover it with one method
sim <- cd_scenario("linear_laplace", seed = 1)
res <- cd_discover(sim$data, "icalingam_pcalg")
cd_score(res, sim$truth)

# or let the recommender choose, and explain its choice
rec <- cd_auto(sim$data)
rec@method
rec@rationale
```

[`cd_auto()`](https://max578.github.io/cdzoo/reference/cd_auto.md) also
accepts an evaluable density – a `proxymix` mixture or target – rather
than a sample, reading the conditional-independence structure off the
mixture in closed form, the case no sampling-based method can serve.

## Benchmark evidence

`cd_field_benchmark` ships a summary of the sixteen methods across nine
structural-causal-model scenarios, scored against each scenario’s known
DAG. It is the evidence behind the recommender’s routing, and the worked
example in the package vignette.

## Contributing

Bug reports and suggestions are welcome through the [issue
tracker](https://github.com/max578/cdzoo/issues).

## Citation

``` r

citation("cdzoo")
```

## Licence

MIT. See [LICENSE.md](https://max578.github.io/cdzoo/LICENSE.md).
