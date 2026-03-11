# KaoBox

KaoBox is a modular deterministic cognitive system for Linux.

It implements a **deterministic brain runtime** designed to manage :
- knowledge
- notes
- projects
- context
- graph relations
- cognitive workflows
- future agent orchestration

Root path :
> /opt/kaobox

---

# Brain CLI

Main entrypoint :
> brain <command>

Examples :
brain status
brain search "query"
brain think "query"
brain think --trace "query"
brain graph test
brain backlinks test
brain neighbors test
brain related test
brain path test-modular test
brain export graph
brain reindex

---

# Architecture

Main layers :
- `core/` → deterministic infrastructure
- `lib/brain/` → cognitive runtime
- `modules/` → domain engines
- `bin/` → CLI entrypoints
- `doc/` → architecture and roadmap
- `tests/` → validation suite

---

# Current State

Track: **v2.9**

Current phase :
**Phase 4.0 — Cognitive Ranking Explainability**

## Delivered capabilities

### Memory engine

- transactional indexing
- FTS5 retrieval
- tag extraction
- markdown link graph extraction
- deterministic rebuild

### Graph layer

- graph navigation
- backlinks
- neighbors
- related notes
- path traversal (BFS)
- graph proximity queries
- graph export
- bounded graph context expansion
- strict ambiguous note rejection for graph note resolution

### Think engine

- context-aware ranking
- focus-aware search
- graph-aware ranking
- configurable graph weighting
- path-aware context expansion
- deterministic think trace explainability
- CLI regression contract coverage

Ranking model :
composite = normalized_fts + focus_boost + graph_boost

Runtime graph weighting supports:
- default graph boost via `THINK_GRAPH_BOOST`
- runtime override via `BRAIN_THINK_GRAPH_BOOST`
- deterministic fallback to `THINK_GRAPH_BOOST` when override is invalid

Path-aware context expansion supports:
- bounded traversal depth from active focus
- deterministic shortest-path context discovery
- distance-aware graph weighting
- compatibility with existing direct graph boost behavior

Current path-aware graph weighting semantics:
- distance 1 → full graph boost
- distance 2 → decayed graph boost
- distance 3 → decayed graph boost
- bounded minimum boost remains deterministic

Think trace explainability supports:
- `brain think --trace <query>`
- active focus visibility
- graph context visibility
- score component visibility
- deterministic ranking explanation output

---

# Graph Commands

brain graph <note>
brain backlinks <note>
brain neighbors <note>
brain related <note>
brain path <from_note> <to_note>

These commands operate on the indexed markdown graph stored in the memory engine.

`brain related <note>` exposes deterministic direct graph proximity
as a read-only CLI surface.

Graph note resolution is now strict and deterministic:
- unique best match → resolved
- no match → explicit error
- ambiguous best match set → explicit deterministic rejection with candidate list

---

# Graph Export

KaoBox provides a **deterministic graph export surface**.

### CLI

brain export graph
brain export graph --format tsv

### Implementation

Export logic is implemented in :
modules/memory/export.sh

Current canonical export :
export_graph_edges_tsv

### Output format

source_path<TAB>target_path

### Properties

- read-only export
- deterministic ordering
- module-owned implementation
- CLI remains orchestration-only

This export layer is designed to support future integrations such as :

- Graphviz
- JSON graph export
- visual graph exploration
- timeline visualization systems

---

# Testing

Run the full test suite :
./tests/run_all.sh

Expected result :
[SUCCESS] All tests passed

The test suite validates :
- logger infrastructure
- memory indexing
- graph navigation
- graph proximity
- graph related command
- graph path traversal
- note reference resolution contract
- ambiguous note rejection for graph commands
- graph-aware ranking
- configurable graph weighting override/fallback
- path-aware context expansion
- think trace explainability
- graph export determinism
- graph export CLI surface
- CLI smoke commands
- CLI regression contract coverage

---

# Principles

KaoBox follows strict engineering principles :
- deterministic core
- modular isolation
- explicit state
- no hidden side effects
- shell-first architecture
- infrastructure before intelligence

---

# Vision

KaoBox is not only a note system.

It is a **deterministic cognitive infrastructure** designed to evolve toward :
- graph-aware cognition
- temporal memory
- cognitive session engines
- agent orchestration systems
