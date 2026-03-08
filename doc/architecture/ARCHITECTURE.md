# KaoBox Architecture

## Overview

KaoBox is a modular cognitive infrastructure designed as a **deterministic brain kernel**.

Root path:
`/opt/kaobox`

The system is layered to enforce:

- Determinism
- Isolation
- Explicit state
- Controlled extensibility

---

# System Layers

---

## Layer 0 — Operating System

Environment:

- Linux
- Bash
- SQLite

KaoBox assumes a controlled POSIX runtime.

---

## Layer 1 — Core (Deterministic Kernel)

Directory:
`core/`

Components:

- env.sh
- init.sh
- logger.sh
- sanity.sh
- shell.sh
- lang/
- state/

Responsibilities:

- Environment bootstrap
- Logging
- System validation
- Localization
- Deterministic runtime configuration

Rules:

Core must:
- Never depend on modules
- Never contain business logic
- Remain minimal and stable

Core = infrastructure only.

---

## Layer 2 — Cognitive Layer (Brain)

Directory:
`lib/brain/`

Components:

- dispatcher.sh
- commands/
- context/
- think/
- renderer.sh
- sanitize.sh
- preflight.sh
- lock.sh

This layer implements the **cognitive runtime**.

Responsibilities:

- command dispatch
- context resolution
- ranking logic
- reasoning orchestration
- rendering output

---

## Context Engine

Location:
`lib/brain/context/`

Components:

- resolver.sh
- scorer.sh
- session.sh

Purpose:
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

Location:
`lib/brain/think/`

Components:
- engine.sh
- ranker.sh

Purpose:
Composite retrieval and ranking.

Dependencies:
- memory/query.sh
- context/session.sh

Ranking formula:
composite_score =
normalized_fts
+ focus_boost

---

## Layer 3 — Modules

Directory:
`modules/`

Modules provide **domain engines**.

Current module:
`modules/memory/`

---

## Memory Module

Location:
`modules/memory/`

Structure:


memory/
├── engine/
│   ├── utils.sh
│   ├── metadata.sh
│   ├── fts.sh
│   ├── tags.sh
│   ├── links.sh
│   └── tx.sh
├── index.sh
├── query.sh
├── gc.sh
└── init.sh

### Features:

- SQLite WAL
- FTS5 search
- transactional indexing
- tag extraction
- markdown link graph
- file hash tracking
- graph adjacency queries
- deterministic path traversal support

### Modules must:

- remain isolated
- not mutate core
- expose explicit interfaces

### Graph Model

The memory module persists explicit graph relations in the links table.

Graph capabilities now include:

- outgoing link inspection
- backlinks inspection
- direct neighbors inspection
- path traversal over indexed markdown links

Batch rebuild uses a two-pass strategy:

1. notes / FTS / tags materialization
2. graph link resolution

This guarantees forward links resolve correctly during deterministic rebuilds.

---

## Layer 4 — CLI Interface

Directory:
> bin/

### Components:

- bin/brain
- bin/kaobox-shell

### The CLI:

- parses user commands
- invokes the brain dispatcher
- never accesses the database directly as business logic owner

---

## Layer 5 — Runtime State

### Directory:
> state/

### Contains:

- version state
- language state
- runtime flags

Mutable by design.

---

## Layer 6 — Documentation

### Directory:
> doc/

### Contains:

- architecture
- roadmap
- phase history
- agent specifications
- test protocols

Documentation is considered part of the system contract.

---

## Brain Graph Surface

### Current graph-facing commands:

- brain graph <note>
- brain backlinks <note>
- brain neighbors <note>
- brain path <from_note> <to_note>

These commands rely on the memory module graph query API, while the CLI remains orchestration-only.

---

## Think Pipeline

User Query
↓
FTS Query (modules/memory/query.sh)
↓
Think Engine (lib/brain/think/engine.sh)
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

It is a programmable cognitive kernel.

Where most systems optimize UI, KaoBox optimizes structured cognition.

---

## Future Extensions

- graph proximity ranking
- semantic ranking layer
- reinforcement signals
- agent orchestration layer

## Status

Phase 3.4 — Graph Navigation
System Status: Stable Cognitive Kernel with Graph Traversal
