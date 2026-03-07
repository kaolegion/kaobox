# KaoBox

KaoBox is a **modular cognitive infrastructure** designed to build a deterministic local knowledge kernel.

It provides the architectural foundation for:

* structured knowledge systems
* transaction-safe memory engines
* context-aware retrieval
* structured agents connected to persistent knowledge

KaoBox is **Linux-first, local-first, and deterministic by design**.

---

# Principles

KaoBox is built on strict engineering foundations.

**Modularity**
Every component is isolated and replaceable.

**Determinism**
Behavior must remain predictable and auditable.

**Transactional Integrity**
All state mutations are explicit and controlled.

**Local-first Architecture**
No mandatory cloud dependency.

**Reproducibility**
Systems must remain portable and inspectable.

**Architecture before Interface**

KaoBox is not UI-first.
It is a **programmable cognitive kernel**.

---

# Vision

KaoBox aims to provide an infrastructure capable of:

* Structuring knowledge using Markdown
* Maintaining a robust transactional index
* Generating a coherent knowledge graph
* Prioritizing context dynamically
* Feeding structured agents
* Serving as programmable persistent memory

---

# Project Structure

```
bin/               CLI entrypoints
core/              deterministic kernel
lib/brain/         brain dispatcher & commands
lib/brain/context/ context engine
lib/brain/think/   ranking & reasoning engine
modules/memory/    transactional memory module
state/             runtime system state
logs/              runtime logs
doc/               official documentation
tests/             validation suite
```

---

# Architecture

```
CLI
 ↓
Dispatcher
 ↓
Commands
 ↓
Cognitive Layer
 ↓
Memory Module
 ↓
SQLite + Filesystem
```

### Core Rules

* CLI never talks directly to the database
* Modules remain self-contained
* `core/` never depends on modules
* Transactions are centralized
* System state is explicit and versioned
* Determinism of the core is non-negotiable

---

# Brain Memory Engine

Features:

* SQLite WAL
* FTS5 search
* Transaction control
* Link graph
* Tag system
* File hash & mtime tracking

---

# Context Engine

Context resolution uses layered signals:

* SELF
* GRAPH_OUT
* GRAPH_IN
* RECENT

Ranking formula:

```
score =
    (layer_weight × temporal_decay)
    + session_boost
```

---

# Think Engine

Context-aware retrieval combining:

```
composite_score =
    normalized_fts
    + focus_boost
```

Focus Boost: +5 on active note.

---

# Installation

```
git clone <repo>
cd kaobox
./init.sh
```

---

# Tests

```
./tests/test_memory_index.sh
./tests/test_brain_cli.sh
```

---

# Roadmap

See:

```
doc/roadmap/ROADMAP.md
doc/state/PHASE_HISTORY.md
```

---

# Long-Term Goal

KaoBox aims to become:

* a stable base for local cognitive systems
* an infrastructure for structured agents
* a portable programmable brain kernel
* a deterministic substrate for controlled intelligence

---

# Version

Track: v2.9
Phase: 3.2 — Context Engine Stable
Think Engine: v1 Stable
Status: Operational Cognitive Kernel
