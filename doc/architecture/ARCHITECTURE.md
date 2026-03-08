# KaoBox Architecture

## Overview

KaoBox is a modular cognitive infrastructure designed as a **deterministic brain kernel**.

Root path :
`/opt/kaobox`

The system is layered to enforce :
- Determinism
- Isolation
- Explicit state
- Controlled extensibility

---

# System Layers

---

## Layer 0 — Operating System

Environment :
- Linux
- Bash
- SQLite

KaoBox assumes a controlled POSIX runtime.

---

## Layer 1 — Core (Deterministic Kernel)

Directory :
`core/`

Components :
- env.sh
- init.sh
- logger.sh
- sanity.sh
- shell.sh
- lang/
- state/

Responsibilities :
- Environment bootstrap
- Logging
- System validation
- Localization
- Deterministic runtime configuration

Rules :

Core must :
- Never depend on modules
- Never contain business logic
- Remain minimal and stable

Core = infrastructure only.

---

## Layer 2 — Cognitive Layer (Brain)

Directory :
`lib/brain/`

Components :
- dispatcher.sh
- commands/
- context/
- think/
- renderer.sh
- sanitize.sh
- preflight.sh
- lock.sh

This layer implements the **cognitive runtime**.

Responsibilities :
- command dispatch
- context resolution
- ranking logic
- reasoning orchestration
- rendering output

---

## Context Engine

Location :
`lib/brain/context/`

Components :
- resolver.sh
- scorer.sh
- session.sh

Purpose :
Build contextual signals for ranking.

### Context Layers

- SELF
- GRAPH_OUT
- GRAPH_IN
- RECENT

### Ranking Model

Score =

(Layer Weight × Temporal Decay)  
+ Session Boost

---

## Think Engine

Location :
`lib/brain/think/`

Components :
- engine.sh
- ranker.sh

Purpose :
Composite retrieval and ranking.

Dependencies :
- memory/query.sh
- context/session.sh

Ranking formula :
composite_score =
normalized_fts

focus_boost

graph_boost

---

## Layer 3 — Modules

Directory :
`modules/`

Modules provide **domain engines**.

Current module :
`modules/memory/`

---

## Memory Module

Location :
`modules/memory/`

Structure :
memory/
├── engine/
│ ├── utils.sh
│ ├── metadata.sh
│ ├── fts.sh
│ ├── tags.sh
│ ├── links.sh
│ └── tx.sh
├── index.sh
├── query.sh
├── gc.sh
├── init.sh
└── export.sh

### Features

- SQLite WAL
- FTS5 search
- transactional indexing
- tag extraction
- markdown link graph
- file hash tracking
- graph adjacency queries
- deterministic path traversal support

### Modules must

- remain isolated
- not mutate core
- expose explicit interfaces

---

## Graph Model

The memory module persists explicit graph relations in the `links` table.

Graph capabilities include :
- outgoing link inspection
- backlinks inspection
- neighbor inspection
- path traversal over indexed markdown links
- graph proximity queries

Batch rebuild uses a two-pass strategy :
1. notes / FTS / tags materialization
2. graph link resolution

This guarantees forward links resolve correctly during deterministic rebuilds.

---

## Graph Export Layer (Phase 3.6)

Location :
`modules/memory/export.sh`

Purpose :
Provide a **canonical deterministic export surface** for the Brain graph.

Current export capability :
- `export_graph_edges_tsv`

Output format :
source_path<TAB>target_path

Design properties:
- read-only
- deterministic ordering
- module-owned graph extraction
- reusable export foundation

### CLI Exposure

The export layer is exposed through the Brain CLI :
brain export graph
brain export graph --format tsv

Architectural rule:

Graph extraction logic **must remain inside the memory module**.

The CLI must remain **orchestration-only** and must not duplicate export logic.

This separation ensures that :
- modules own business logic
- the CLI remains a thin orchestration layer
- deterministic behavior is preserved

### Future renderers

Possible downstream integrations :
- JSON graph export
- Graphviz DOT export
- visualization pipelines
- timeline graph tools

This layer allows KaoBox to expose its internal knowledge graph to external systems without breaking deterministic guarantees.

---

## Layer 4 — CLI Interface

Directory :
`bin/`

Component :
- bin/brain
- bin/kaobox-shell

The CLI :
- parses user commands
- invokes the brain dispatcher
- never accesses the database directly as business logic owner

---

## Layer 5 — Runtime State

Directory :
`state/`

Contains :
- version state
- language state
- runtime flags

Mutable by design.

---

## Layer 6 — Documentation

Directory :
`doc/`

Contains :
- architecture
- roadmap
- phase history
- agent specifications
- test protocols

Documentation is considered part of the **system contract**.

---

## Brain Graph Surface

Current graph-facing commands :
> brain graph <note>
> brain backlinks <note>
> brain neighbors <note>
> brain path <from_note> <to_note>
> brain export graph

These commands rely on the memory module graph APIs while the CLI remains orchestration-only.

---

## Think Pipeline

User Query  
↓  
FTS Query (`modules/memory/query.sh`)  
↓  
Think Engine (`lib/brain/think/engine.sh`)  
↓  
Ranker  
↓  
Renderer  
↓  
CLI Output

---

## Design Principles

- Deterministic Core
- Modular Engines
- Explicit State
- Minimal Coupling
- Infrastructure First
- Intelligence as Layered Emergence

---

## Architectural Identity

KaoBox is not a workspace.

It is a programmable **cognitive kernel**.

Where most systems optimize UI, KaoBox optimizes structured cognition.

---

## Future Extensions

- semantic ranking layer
- reinforcement signals
- agent orchestration layer

---

## Status

Phase 3.6 — Graph Export (CLI Surface)

System Status :

Stable cognitive kernel with :
- deterministic memory engine
- graph traversal capabilities
- graph-aware ranking
- deterministic graph export exposed through CLI
