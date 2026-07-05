---
title: 'cdzoo: A multi-back-end benchmark harness and evidence-routed recommender for causal discovery in R'
tags:
  - R
  - causal discovery
  - structure learning
  - graphical models
  - reproducible research
authors:
  - name: Max Moldovan
    orcid: 0000-0001-9680-8474
    affiliation: 1
affiliations:
  - name: University of Adelaide, Australia
    index: 1
date: 5 July 2026
bibliography: paper.bib
---

# Summary

`cdzoo` puts a portfolio of causal-structure-discovery algorithms behind one
interface. It wraps R and Python discovery methods in a single adjacency
convention, supplies a grid of structural-causal-model scenarios with known
ground truth, computes fair graph-recovery metrics, and provides an
evidence-routed recommender that inspects a data set and suggests a method
suited to its characteristics. Because causal discovery has no run-time ground
truth, the recommender is deliberately a recommender and not a selector: it
reports why it chose a method and how sure it is, rather than claiming an
optimum. Every back-end is an optional dependency loaded only when used, so the
harness, the scenario grid, the metrics, and the routing logic all run on a base
installation. A sufficient statistic -- a correlation matrix and its sample size
-- is a first-class input alongside a raw data matrix, so aggregated data
(published correlation matrices, privacy-preserving summaries, co-occurrence
counts) can be analysed without row-level access.

# Statement of need

The R ecosystem has strong individual causal-discovery packages -- `pcalg`
[@kalisch2012] and `bnlearn` [@scutari2010] chief among them -- but no unified
harness that wraps R *and* Python algorithms in one convention, with a scenario
grid and fair metrics, and no recommender that routes a data set to a suitable
method on transparent evidence. Practitioners comparing methods must therefore
reconcile heterogeneous outputs (DAGs, CPDAGs, PAGs, weighted matrices) and
differing input conventions by hand, and newcomers have little principled
guidance on which method suits their data.

`cdzoo` addresses this gap. It bridges constraint-based, score-based,
functional-causal-model, and continuous-optimisation families
[@spirtes2000; @chickering2002; @shimizu2006; @zheng2018] behind one
convention-checked interface, scores them against an independent oracle (the
simulated truth), and turns that benchmark evidence into a routing table the
recommender uses. The registry is extensible: a user registers a new method with
one call, and it joins the benchmark and the recommender immediately.

# Design

A discovery result is a typed object carrying the recovered graph in the `pcalg`
`amat.cpdag` convention together with its provenance -- the method that produced
it, and, when the recommender chose it, the routing rationale, a confidence
label, and the alternatives considered. Methods are registry entries declaring
their family, native output type, cost, assumptions, and the input they consume
(a data matrix or a sufficient statistic). The recommender routes on a small set
of transparent data characteristics; the deciding thresholds are recorded in
each recommendation so the choice is auditable. A recovered graph adapts to a
shared, versioned, integrity-hashed manifest, so a discovery result can be
passed to downstream consumers with its provenance intact and verified.

# Acknowledgements

<!-- Funding, contributors, and reviewers to be acknowledged here. -->

# References
