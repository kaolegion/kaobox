# KaoBox TODO

Version: v2.9
Aligned with Phase 4.0 completion

---

# DONE (Phase 3.3)

- [x] brain health
- [x] brain stats
- [x] brain session
- [x] brain explain
- [x] brain context --trace
- [x] runtime diagnostics
- [x] CLI observability commands
- [x] graph command stabilization
- [x] shellcheck cleanup
- [x] deterministic CLI dispatcher

Phase 3.3 delivered the **Observability Layer**.

---

# DONE (Phase 3.4 — Graph Navigation)

Goal achieved: exploit the note graph for contextual navigation.

- [x] `brain graph <note>` refactored on memory query API
- [x] `brain backlinks <note>`
- [x] `brain neighbors <note>`
- [x] `brain path <noteA> <noteB>`
- [x] Graph traversal API in memory module
- [x] Deterministic BFS path resolution
- [x] Two-pass batch reindex for reliable graph resolution
- [x] Graph navigation test suite
- [x] CLI graph smoke coverage

Outcome : Graph is now a **first-class navigation surface** in Brain.

---

# DONE (Phase 3.5 — Graph-Aware Cognition)

Goal achieved: promote graph structure from navigation layer
to active cognitive ranking signal.

- [x] Graph proximity query API (`query_graph_proximity_by_note`)
- [x] Graph context expansion in Think Engine
- [x] Graph proximity boost in ranking model
- [x] Composite ranking model implemented :
normalized_fts + focus_boost + graph_boost

- [x] Deterministic integration with existing ranking pipeline
- [x] Test suite additions:
  - `test_graph_proximity.sh`
  - `test_think_graph_boost.sh`
- [x] CLI smoke test extended with `brain think`

Outcome:

The markdown graph is now used as a **cognitive relevance signal**
in addition to navigation.

---

# DONE (Phase 3.6 — Graph Export)

Goal achieved: expose the Brain graph as a deterministic export surface.

## Export Layer

- [x] Canonical graph export module (`modules/memory/export.sh`)
- [x] Deterministic edge export (`export_graph_edges_tsv`)
- [x] Read-only export layer
- [x] Deterministic ordering guarantees

## CLI Exposure

- [x] `brain export graph`
- [x] `brain export graph --format tsv`
- [x] CLI orchestration-only implementation

## Tests

- [x] Export validation test (`test_graph_export.sh`)
- [x] Export CLI integration test (`test_graph_export_cli.sh`)
- [x] CLI smoke test updated
- [x] Global test suite updated

Outcome:

KaoBox now exposes a **deterministic graph export surface**
accessible through the Brain CLI and reusable by external tools.

---

# DONE (Phase 3.7 — Graph Exploitation)

Goal achieved: expose direct graph proximity as a user-facing navigation command.

## Delivered

- [x] `brain related <note>`
- [x] Direct reuse of graph proximity query API
- [x] Read-only deterministic related notes surface
- [x] CLI remains orchestration-only

## Tests

- [x] Related command validation test (`test_graph_related.sh`)
- [x] CLI smoke test extended with `brain related`
- [x] Global test suite updated

Outcome:

KaoBox now exposes a **deterministic related notes command**
built on top of direct graph proximity.

---

# DONE (Phase 3.8.a — Configurable Graph Weighting)

Goal achieved: make graph weighting configurable without breaking the
existing ranking contract.

## Delivered

- [x] Runtime graph boost override via `BRAIN_THINK_GRAPH_BOOST`
- [x] Deterministic fallback to `THINK_GRAPH_BOOST`
- [x] No change to Think Engine orchestration contract
- [x] No CLI surface change
- [x] Additive implementation in `lib/brain/think/ranker.sh`

## Tests

- [x] `test_think_graph_boost.sh` extended
- [x] Default graph boost preserved
- [x] Runtime override validated
- [x] Invalid override fallback validated
- [x] Global test suite passed

Outcome:

KaoBox now supports **configurable graph weighting**
while preserving deterministic ranking behavior.

---

# DONE (Phase 3.8.b — Path-Aware Context Expansion)

Goal achieved: extend graph-aware cognition beyond direct neighbors
through bounded path-aware context expansion.

## Delivered

- [x] Bounded graph context query API (`query_graph_context_by_note`)
- [x] Deterministic BFS shortest-path expansion from active focus
- [x] Think Engine support for path-aware graph context
- [x] Distance-aware graph weighting in ranker
- [x] Compatibility preserved with existing direct graph boost behavior
- [x] No CLI contract change
- [x] CLI remains orchestration-only

## Tests

- [x] `test_think_graph_boost.sh` extended
- [x] Direct neighbor ranking preserved
- [x] Indirect path results validated
- [x] Distance-aware weighting validated
- [x] Runtime override remains compatible
- [x] Global test suite passed

Outcome:

KaoBox now supports **bounded path-aware cognitive expansion**
while preserving deterministic ranking behavior.

---

# DONE (Phase 3.8.c — Ambiguous Note Resolution Policy)

Goal achieved: make note resolution strict and deterministic for graph-facing commands.

## Delivered

- [x] Strict resolver candidate ranking in `modules/memory/query.sh`
- [x] Explicit deterministic rejection of ambiguous best-match note references
- [x] Graph command propagation for resolver errors:
  - `brain graph`
  - `brain backlinks`
  - `brain neighbors`
  - `brain related`
  - `brain path`
- [x] No uncontrolled refactor
- [x] CLI remains orchestration-only

## Tests

- [x] New resolver contract validation test (`test_note_ref_resolution.sh`)
- [x] `test_graph_related.sh` extended with ambiguous note rejection coverage
- [x] Global test suite updated
- [x] Full deterministic validation passed

Outcome:

KaoBox now enforces a **strict deterministic ambiguous note resolution policy**
for graph-facing note resolution surfaces.

---

# DONE (Phase 3.9 — CLI Regression Contract)

Goal achieved: strengthen the Brain CLI contract with explicit regression coverage
for graph-facing and cognition-facing commands.

## Delivered

- [x] Dedicated CLI regression contract test (`test_cli_regression_contract.sh`)
- [x] Explicit graph-facing CLI success coverage:
  - `brain graph`
  - `brain backlinks`
  - `brain neighbors`
  - `brain related`
  - `brain path`
- [x] Explicit cognition-facing CLI success coverage:
  - `brain think`
- [x] Deterministic ambiguous resolver error propagation coverage through CLI commands
- [x] Global test suite updated
- [x] CLI remains orchestration-only

## Tests

- [x] New contract test added to full suite
- [x] Targeted validation passed
- [x] Full deterministic validation passed

Outcome:

KaoBox now enforces a **stronger CLI regression contract**
for graph-facing and cognition-facing surfaces.

---

# DONE (Phase 4.0 — Cognitive Ranking Explainability)

Goal achieved: expose deterministic explainability for Think Engine ranking.

## Delivered

- [x] `brain think --trace <query>`
- [x] Deterministic Think trace output
- [x] Active focus visibility in Think trace
- [x] Graph context visibility in Think trace
- [x] Score component visibility:
  - relevance
  - focus boost
  - graph boost
  - graph distance
  - composite
- [x] No uncontrolled refactor
- [x] CLI remains orchestration-only

## Tests

- [x] New explainability validation test (`test_think_trace.sh`)
- [x] Global test suite updated
- [x] Targeted validation passed
- [x] Full deterministic validation passed

Outcome:

KaoBox now exposes a **deterministic cognitive ranking explainability surface**
through the Think CLI.

---

# Phase 3.8 — Graph Expansion

Goal: deepen graph exploitation beyond direct related notes.

## Remaining

- [x] Stronger ambiguous note resolution policy

Outcome:
Phase 3.8 is now complete.

---

# Short Term (Stabilization Layer)

- [x] CLI regression test suite
