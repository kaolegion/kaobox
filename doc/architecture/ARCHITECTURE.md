# KaoBox Architecture

## Overview

KaoBox is a modular cognitive infrastructure designed as a deterministic brain kernel.

Root path:

/opt/kaobox

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
core/
init.sh
state/
lang/

Responsibilities:

- Environment bootstrap
- Logging system
- Sanity validation
- Localization
- Locking
- Deterministic execution

Core must:

- Not depend on modules
- Not contain business logic
- Remain minimal and stable

Core = infrastructure only.

---

## Layer 2 — Cognitive Layer (lib/brain/)

    - context/
    - think/

Directory:
modules/

Modules contain domain engines.

Current module:
modules/memory/

### Memory Module Structure

memory/
├── engine/      → low-level indexing logic
├── context/     → adaptive contextual ranking engine
├── index.sh
├── query.sh
├── gc.sh
└── init.sh

Modules must:

- Be isolated
- Not mutate core
- Expose explicit interfaces
- Remain composable

---

## Context Engine (Phase 3.2)

Location:
modules/memory/context/

Components:

- resolver.sh → Collect contextual layers
- scorer.sh   → Adaptive weighted ranking
- session.sh  → Active node persistence

## Think Engine (Phase 3.2+)

Location:
lib/brain/context/

Components:

- engine.sh  → orchestration
- ranker.sh  → composite scoring

### Think Model

FTS relevance (memory/query.sh)
+ Session focus boost
= Composite ranking

Future:
+ Graph proximity boost
+ Tag similarity
+ Temporal blending

### Context Layers

- SELF
- GRAPH_OUT
- GRAPH_IN
- RECENT

### Ranking Model

Score =
    (Layer Weight × Temporal Decay)
    + Session Boost

Layer Weights:

- SELF      → 4
- GRAPH_OUT → 3
- GRAPH_IN  → 2
- RECENT    → 1

Temporal Decay:

- 0–1 days   → 100%
- 2–7 days   → 70%
- 8–30 days  → 40%
- >30 days   → 20%

Session Boost:

- +5 if note is active focus

This creates an adaptive contextual graph.

---

## Layer 3 — CLI Interface

## Think Engine

Location:
lib/brain/think/

Purpose:
Composite retrieval and ranking layer.

Dependencies:
- memory/query.sh
- context/session.sh

Scoring:
normalized_fts + focus_boost

---

## Layer 4 — Runtime State

Directory:
state/

Contains:

- version state
- language state
- runtime flags

Mutable by design.

---

## Layer 5 — Documentation

Directory:
doc/

Contains:

- Architecture definitions
- Agent specifications
- Roadmap
- Phase history
- Test protocols

Documentation is considered part of the system contract.

---

# Design Principles

1. Deterministic Core  
2. Modular Engines  
3. Explicit State  
4. Minimal Coupling  
5. Infrastructure First  
6. Intelligence as Layered Emergence  

---

# Architectural Identity

KaoBox is not a workspace.

It is a programmable cognitive kernel.

Where most systems optimize UI,
KaoBox optimizes structured cognition.

---

# Future Extensions

- Hybrid semantic ranking (FTS integration)
- Usage reinforcement learning
- Multi-module orchestration
- Agentic execution layer

# Think Pipeline

User Query
   ↓
FTS Query (modules/memory/query.sh)
   ↓
Think Engine (lib/brain/think/engine.sh)
   ↓
Ranker (composite scoring)
   ↓
Renderer

---

# Status

Phase 3.2 — Context Engine: STABLE
