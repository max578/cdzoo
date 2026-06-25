# Orchestra membership — cdzoo

> **This project (cdzoo) is a MEMBER of the Orchestra** (one coordination
> structure). Joined 2026-06-24; **fully enrolled 2026-06-25** (manifest emitter +
> conductoR node `tool_discover` + capability atlas + machine roster +
> member-awareness). The leader-node is **ORCHESTRA_dev** (governance, roster,
> contracts, the manifest spec, publication); the technical inference hub is
> **flexyBayes** (the dependency-DAG sink). This file is cdzoo's back-pointer to
> that charter and a map of my siblings.

- **My role:** **causal-discovery layer** — a unified registry of causal-structure
  discovery algorithms behind one adjacency convention (`amat.cpdag`), a
  known-truth scenario grid, fair graph-recovery metrics, and an **evidence-routed
  recommender** (`cd_auto`). I am the federation's causal-structure-recovery entry
  point: given observational data, I recover (or recommend a method to recover) the
  causal/graphical structure other members then reason over.
- **Contracts I emit:** the canonical **`orchestra_manifest`** with
  `inferential_target = "structure"` — a recovered graph is an inferred *structure*,
  not a parameter vector, a prediction, or a decision, so the contract gained the
  additive **`structure`** token at my enrolment (existing manifests unchanged;
  `MANIFEST_VERSION` unbumped). The recovered edges ride in `params` (a tidy edge
  list); the method, the routing rationale, **the routing confidence, and whether
  the graph is a single method or a consensus** ride in the typed `summary` +
  `metadata`; the full adjacency (and, for a consensus, the per-edge agreement)
  rides in `metadata` for a consumer that wants the matrix. A consumer therefore
  always knows *how* the graph was obtained and *how sure* the recommender was. The
  payload is integrity-hashed; **interop is verified against the reference contract**
  (a reference-class manifest rebuilt from my fields passes `verify_manifest()` and
  `consume_manifest()`, with full property parity, and the federation conformance
  suite carries a cdzoo case).
- **I am conductable:** the leader carries `tool_discover` (a conductoR node) and a
  kill-tested demo (`integration/conductor/{cdzoo_node.R,conductor_cdzoo_demo.R}`);
  the conductor's typed edge set gained `"structure"` so a score can route a
  discovery node. A reference-side `as_orchestra_manifest()` method lifts a
  `cd_result` into the reference manifest the engine type-checks.
- **My recommender (the differentiator):** `cd_auto` is a **recommender, not a
  selector.** optimix's `auto` compares observable objective values and returns the
  winner; causal discovery has **no run-time ground truth**, so I route on data
  characteristics (`cd_diagnose`: non-Gaussianity / a curvature heuristic /
  equal-variance / a latent-structure hint), run the benchmark-suited method, and
  report *why* + a confidence label + the alternatives — and offer a consensus when
  unsure. Honesty is the feature.
- **My registry (16 methods):** pcalg (PC, GES, ICA-LiNGAM, FCI) and bnlearn (HC,
  Tabu, GS, IAMB, PC-stable, MMHC) in R; DirectLiNGAM, RCD, PC+KCI, NOTEARS, GOLEM,
  DAGMA in Python via `reticulate`. Each is a `Suggests`-gated adapter, so the
  harness, scenarios, metrics, and routing logic run with no back-end installed.
  The routing preferences are grounded in the shipped `cd_field_benchmark`.
- **My edge:** cdzoo → proxymix (`Suggests`-only, the `gmm_independence_graph`
  evaluable-density route, acyclic); cdzoo → decideR / a downstream consumer via the
  manifest (a recovered structure feeds an analysis or a decision). I take no hard
  dependency on another member. proxymix does **not** depend on cdzoo (one-way).
- **What binds me (charter invariants):**
  - *Standalone-functional* — every back-end (and proxymix) is a `Suggests:`
    adapter loaded lazily; `R CMD check` is clean with none installed.
  - *Grounding-first* — `cd_field_benchmark` is read from the real study cache, not
    re-typed; the scenario truth (the simulated DAG) is the independent oracle for
    `cd_score`; the manifest interop is verified against the reference contract.
  - *Firewall* — **causal discovery is firewalled from stable proxymix.** I carry no
    GMM-LiNGAM / GMM-PC discovery bridge (those stay research probes); my only
    proxymix link is the graduated `gmm_independence_graph` route. No GRDC-funded
    asset in or out.
  - *Leader-directed* — I align to the leader-node's contract + roster; I may propose
    innovations (a cairn), the leader arbitrates.
- **Governance:** cdzoo is a **Max-owned personal package** (`max578/cdzoo`, MIT);
  the AAGI-AUS canon does not apply.

## My siblings (the roster — so I am informed about the others)

| Member | Role | Class |
|---|---|---|
| flexyBayes | inference hub (owns C1/C4/C5/C7) | open |
| PESTO | calibration + manifest source (C2) | open |
| kernR | kernel causal / distributional inference (TACI engine) | open |
| proxymix | KL-optimal Gaussian-mixture proxy; my `gmm_independence_graph` route | open |
| gretaR | engine — torch MCMC | open |
| koine | synthesis — fourth opinion | open |
| terroir | data collector (C6) | open (MIT) |
| kalmix | state-space / change-point / N-of-1 ITS causal | open (MIT) |
| masque | data sovereignty (clones) | open |
| apsimR | external engine — APSIM Next Gen | open (MIT-src) |
| flexyBayesOrchestra | composition layer | open |
| decideR | decision layer (consumes the manifest) | open |
| gpfield | spatial — change-of-support GP; emits `orchestra_manifest` | open (MIT) |
| grainPlan | grain decision-orchestration (on decideR) | open (MIT) |
| optimix | optimisation meta-layer; emits `orchestra_manifest` | open (MIT) |
| **cdzoo** | **causal-discovery harness + recommender (this package); emits `orchestra_manifest` (`structure`)** | open (MIT) |

**Canonical charter:** `ORCHESTRA_dev/ORCHESTRA.md`. **Contract:**
`ORCHESTRA_dev/integration/orchestra_manifest.R` (the `structure` token added for
this enrolment). **Machine roster:** `ORCHESTRA_dev/constellation.yaml`.
