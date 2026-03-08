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
brain graph test
brain backlinks test
brain neighbors test
brain path test-modular test
brain reindex


---

# Architecture

Main layers:

- `core/` → deterministic infrastructure
- `lib/brain/` → cognitive runtime
- `modules/` → domain engines
- `bin/` → CLI entrypoints
- `doc/` → architecture and roadmap
- `tests/` → validation suite

---

# Current State

Track: **v2.9**

Current phase: **Phase 3.5 — Graph-Aware Cognition**

## Delivered capabilities

Memory engine :
- transactional indexing
- FTS5 retrieval
- tag extraction
- markdown link graph extraction
- deterministic rebuild

Graph layer :
- graph navigation
- backlinks
- neighbors
- path traversal (BFS)
- graph proximity queries

Think engine :
- context-aware ranking
- focus-aware search
- graph-aware ranking

Ranking model :
composite = normalized_fts + focus_boost + graph_boost

---

# Graph Commands

brain graph <note>
brain backlinks <note>
brain neighbors <note>
brain path <from_note> <to_note>

These commands operate on the indexed markdown graph stored in the memory engine.

---

# Testing

Run the full test suite :
./tests/run_all.sh

Expected result :
[SUCCESS] All tests passed


The test suite validates:

- logger infrastructure
- memory indexing
- graph navigation
- graph proximity
- graph-aware ranking
- CLI smoke commands

---

# Principles

KaoBox follows strict engineering principles:

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


