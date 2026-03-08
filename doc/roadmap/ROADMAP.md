# KaoBox Roadmap

Version: v2.9  
Last Update: 2026-03-08

---

# Vision

Infrastructure before intelligence.  
Stability before expansion.  
Determinism before automation.

KaoBox is a modular deterministic system orchestrator
with a hardened cognitive memory engine (Brain)
and an emerging structured agent layer.

---

# Phase 1 — Structural Foundation ✅

Objectives :
- Clean layered architecture
- Deterministic Core
- Strict separation between Core and Modules
- Environment contract stabilization
- Modular engine design
- Documentation baseline

Memory :
- Brain module initialized
- SQL-only emission model
- Transaction wrapper architecture
- Explicit schema ownership

Status : COMPLETE

---

# Phase 2 — Production Hardening (Brain v2.8) ✅

Objective :
Transform Brain into a production-grade,
concurrency-safe memory engine.

Delivered :

## SQLite Hardening

- WAL mode enabled
- FULL synchronous durability
- BEGIN IMMEDIATE transactional control
- Runtime `.timeout` injection

## Safety Layer

- Integrity check integrated into `brain doctor`
- Schema validation
- Strict environment validation

## Maintenance Automation

- Intelligent WAL checkpoint (batch only)
- Automatic `PRAGMA optimize` post-batch
- Transactional garbage collector

## Guarantees

- Crash-safe writes
- Multi-process safe indexing
- Controlled WAL growth
- Zero output regression

Tag : v2.8  
Branch : release/brain-v2.8  
Status : STABLE

---

# Phase 3 — Operational Intelligence (v2.9)

Objective :
Build a stable operational cognitive layer
on top of the hardened infrastructure.

---

## Phase 3.1 — CLI Stabilization ✅

Delivered :
- Command normalization
- Deterministic dispatcher
- Argument validation consistency
- Shell integration
- CLI completion system

Status : COMPLETE

---

## Phase 3.2 — Context Engine ✅

Location :
lib/brain/context/

Delivered :
- Context resolver
- Adaptive scoring model
- Session focus tracking
- Layered ranking system

Context Layers :
- SELF
- GRAPH_OUT
- GRAPH_IN
- RECENT

Scoring Model :
Score =
    (Layer Weight × Temporal Decay)
    + Session Boost

Outcome :
Context-aware memory navigation
without breaking Core determinism.

Status : STABLE

---

## Phase 3.3 — Observability & Diagnostics ✅

Delivered :
- `brain health`
- `brain stats`
- `brain session`
- `brain explain`
- CLI introspection tools
- runtime diagnostics
- graph command stabilization
- shellcheck cleanup

Capabilities :
- runtime database inspection
- context visibility
- query introspection
- indexing diagnostics

Outcome :
Transparent operational intelligence layer.

Status : COMPLETE

---

## Phase 3.4 — Graph Navigation ✅

Delivered :
- refactored `brain graph <note>`
- `brain backlinks <note>`
- `brain neighbors <note>`
- `brain path <from_note> <to_note>`
- graph traversal API in `modules/memory/query.sh`
- deterministic BFS path traversal
- portable note reference resolution
- two-pass batch reindex for reliable link resolution
- graph navigation tests
- CLI smoke coverage extended

Capabilities :
- direct graph inspection
- backlinks navigation
- neighbor inspection
- shortest-path style traversal over explicit links

Outcome :
The indexed markdown graph became a first-class Brain navigation layer.

Status : COMPLETE

---

## Phase 3.5 — Graph-Aware Cognition ✅

Goal :
Promote graph structure from navigation layer
to an active cognitive ranking signal.

Delivered :
- graph proximity query API (`query_graph_proximity_by_note`)
- graph context expansion in think engine
- graph boost integrated into ranking model
- composite scoring model for think results
- deterministic integration without breaking core guarantees
- new validation tests:
  - `test_graph_proximity.sh`
  - `test_think_graph_boost.sh`
- CLI smoke test extended with `brain think`

Ranking Model:

composite =
    normalized_fts
    + focus_boost
    + graph_boost

Constraint respected :
Graph intelligence remains modular.  
Core determinism preserved.

Outcome :
The markdown graph is now used not only for navigation
but also as a cognitive relevance signal
in the Think Engine.

Status: COMPLETE

---

# Phase 4 — Adaptive Layer

Goal :
Introduce controlled adaptive intelligence
above deterministic infrastructure.

Planned :
- Hybrid semantic ranking (FTS + graph)
- Context-aware execution policies
- Cross-note graph reinforcement
- Multi-module orchestration
- Structured planning layer
- Agent task routing

Constraint:

Adaptive logic must remain modular.  
Core must remain deterministic.

Expected outcome :
Semi-autonomous structured agent.

Status: PLANNED

---

# Phase 5 — Distributed Brain (Long-Term)

Vision :

Extend KaoBox beyond a single runtime.

Goals :
- Multi-brain instances
- State replication
- Remote orchestration
- Snapshot & recovery layer
- External toolchain integration

Expected outcome :
Distributed agentic infrastructure.

Status: VISION

---

# Core Design Principles

- SQL-only engine emission
- Deterministic transaction boundaries
- No hidden state
- Modular isolation
- Crash-safe by design
- Explicit state mutation
- Versioned architectural milestones

---

# Current State Summary

Brain v2.9 now provides :
- transactional memory engine
- context-aware retrieval
- graph-based note relations
- runtime observability tools
- direct graph navigation and path traversal

KaoBox evolution path :
Infrastructure maturity  
→ Operational intelligence  
→ Graph-aware cognition (current state)  
→ Structured adaptive cognition
