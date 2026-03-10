# KaoBox Phase History

This document tracks architectural milestones.
Each phase represents a structural evolution of the system.

---

# Phase 1 — Structural Foundation ✅

Version : v1.0.0-alpha
Status : COMPLETED

## Scope

- Clean layered architecture
- Deterministic Core separation
- Module isolation
- Documentation baseline
- Roadmap formalization

## Key Decisions

- /opt/kaobox as single source of truth
- Core cannot be modified by modules
- Explicit runtime state directory
- Infrastructure before intelligence
- Modules extend, never mutate

## Exit Criteria (Met)

- Core validated
- CLI structure defined
- Module contract formalized
- Deterministic boundaries enforced

---

# Phase 2 — Production Hardening (Brain v2.8) ✅

Version : v2.8
Status : COMPLETED
Branch : release/brain-v2.8

## Scope

Transform Brain into a concurrency-safe,
production-grade memory engine.

## Delivered

### SQLite Hardening

- WAL mode
- FULL synchronous durability
- BEGIN IMMEDIATE transactional model
- Runtime timeout injection

### Safety & Integrity

- Integrated integrity checks
- Schema validation
- Strict environment validation
- Transaction wrapper architecture

### Maintenance Automation

- Controlled WAL checkpointing
- Automatic PRAGMA optimize
- Transactional garbage collector

## Guarantees Achieved

- Crash-safe writes
- Multi-process safe indexing
- Controlled WAL growth
- Zero output regression

Phase 2 marks the stabilization of the infrastructure layer.

---

# Phase 3 — Operational Intelligence (v2.9)

Status : ACTIVE

Goal :
Build structured operational intelligence
on top of hardened infrastructure.

---

## Phase 3.1 — CLI Stabilization ✅

Delivered :
- Command normalization
- Deterministic CLI dispatcher
- Separation between CLI and business logic
- Shell integration
- Completion system

Impact :
CLI became a thin orchestration layer.

---

## Phase 3.2 — Context & Think Engine ✅

Location :
lib/brain/context/
lib/brain/think/

### Context Engine

Components :
- resolver.sh
- scorer.sh
- session.sh

Delivered :
- Context resolver
- Layered context model
- Temporal decay scoring
- Session focus persistence

Context Layers :
- SELF
- GRAPH_OUT
- GRAPH_IN
- RECENT

### Think Engine

Components :
- engine.sh
- ranker.sh

Delivered :
- Composite ranking model
- Focus boost integration
- Robust TAB parsing
- Strict dependency loading

Ranking Model :
composite_score =
normalized_fts
+ focus_boost

Architectural Impact :
- Introduced contextual awareness
- Preserved deterministic core
- Maintained module isolation

---

## Phase 3.3 — Observability Layer ✅

Date : 2026-03-07

Delivered :
- brain health
- brain stats
- brain session
- brain explain
- runtime diagnostics
- CLI observability commands
- graph command stabilization
- full shellcheck compliance

Capabilities :
- database integrity visibility
- context inspection
- query explainability
- indexing diagnostics

Impact :
The cognitive system became **transparent and inspectable**.

---

## Phase 3.4 — Graph Navigation ✅

Date : 2026-03-08

Delivered :
- graph query API in memory module
- `brain graph`
- `brain backlinks`
- `brain neighbors`
- `brain path`
- deterministic BFS traversal
- portable reference resolution
- two-pass batch reindex for graph correctness
- graph navigation tests
- extended CLI smoke validation

Architectural Impact :
- The markdown graph became directly navigable
- Graph inspection moved from embedded SQL to a reusable query API
- Batch rebuild became robust against lexical ordering of linked notes
- Brain gained explicit path traversal over note relations

Impact :
KaoBox moved from graph awareness to graph navigation.

---

## Phase 3.5 — Graph-Aware Cognition ✅

Date : 2026-03-08

Delivered :
- graph proximity query API (`query_graph_proximity_by_note`)
- graph context expansion in Think Engine
- graph boost integrated into ranking model
- composite ranking model updated
- deterministic integration with existing cognitive pipeline
- new validation tests:
  - `test_graph_proximity.sh`
  - `test_think_graph_boost.sh`
- CLI smoke test extended with `brain think`

Updated Ranking Model :
composite_score =
normalized_fts
+ focus_boost
+ graph_boost

Architectural Impact :
- Graph structure is now used as a ranking signal
- Think Engine became graph-aware
- Context expansion now includes graph proximity

Impact :
KaoBox moved from graph navigation
to **graph-aware cognition**.

---

## Phase 3.6 — Graph Export (CLI Surface) ✅

Date : 2026-03-08

Delivered :

### Export Layer

- canonical graph export module (`modules/memory/export.sh`)
- deterministic graph edge export (`export_graph_edges_tsv`)
- read-only graph export layer
- deterministic ordering guarantees

Export format :

source_path<TAB>target_path

### CLI Exposure

- `brain export graph`
- `brain export graph --format tsv`
- CLI remains orchestration-only

### Tests

- `test_graph_export.sh`
- `test_graph_export_cli.sh`
- CLI smoke test updated
- global test suite updated

Architectural Impact :
- Graph became exportable as a reusable deterministic surface
- Export logic remained module-owned
- CLI preserved orchestration-only responsibilities

Impact :
KaoBox moved from graph-aware cognition
to **deterministic graph export**.

---

## Phase 3.7 — Graph Exploitation ✅

Date : 2026-03-10

Delivered :
- `brain related <note>`
- direct reuse of graph proximity query API
- deterministic direct related notes surface
- CLI remains orchestration-only

Tests :
- `test_graph_related.sh`
- CLI smoke test extended with `brain related`
- global test suite updated

Architectural Impact :
- Direct graph proximity became a first-class user-facing navigation command
- Existing graph query primitives were reused without duplicating graph logic
- CLI remained a thin orchestration surface

Impact :
KaoBox moved from graph export
to **direct graph exploitation**.

---

## Phase 3.8.a — Configurable Graph Weighting ✅

Date : 2026-03-10

Delivered :
- runtime graph boost override via `BRAIN_THINK_GRAPH_BOOST`
- deterministic fallback to `THINK_GRAPH_BOOST`
- additive ranker-only implementation
- no Think Engine orchestration change
- no CLI contract change

Tests :
- `test_think_graph_boost.sh` extended
- default graph boost preserved
- runtime override validated
- invalid override fallback validated
- global test suite passed

Architectural Impact :
- Graph weighting became runtime-configurable
- Existing ranking model remained stable
- Deterministic behavior was preserved through bounded override resolution

Impact :
KaoBox moved from direct graph exploitation
to **configurable graph-aware ranking**.

---

## Phase 3.8.b — Path-Aware Context Expansion ✅

Date : 2026-03-10

Delivered :
- bounded graph context query API (`query_graph_context_by_note`)
- deterministic BFS shortest-path expansion from active focus
- Think Engine support for path-aware graph context
- distance-aware graph weighting in ranker
- compatibility preserved with direct graph boost behavior
- no CLI contract change

Tests :
- `test_think_graph_boost.sh` extended
- direct neighbor ranking preserved
- indirect path ranking validated
- distance-aware weighting validated
- runtime override compatibility validated
- global test suite passed

Architectural Impact :
- Think Engine now expands graph context beyond direct neighbors
- Path-derived context remains module-owned and deterministically bounded
- Ranking model now integrates graph distance without breaking existing direct proximity behavior

Impact :
KaoBox moved from configurable graph-aware ranking
to **path-aware cognitive expansion**.

