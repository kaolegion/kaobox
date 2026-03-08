# KaoBox Agent Specification

## Purpose

The KaoBox Agent is a structured operational intelligence layer
running on top of the deterministic core.

It does not replace the system.
It orchestrates it.

---

## Agent Nature

The agent is:

- Deterministic-aware
- State-conscious
- Modular
- Tool-driven
- Language-aware

It must never:
- Corrupt core
- Modify base manifests directly
- Break deterministic guarantees

---

## Agent Layers

### 1. Perception

Reads:
- state/
- manifests
- module availability
- environment variables

### 2. Reasoning

Uses:
- defined tools
- deterministic scripts
- explicit logic flows

No hidden state allowed.

### 3. Action

Allowed actions:
- Execute modules
- Update runtime state
- Log operations
- Trigger safe hooks

Forbidden:
- Direct modification of core/
- Direct modification of base/

---

## Memory

Memory is modular.

Current module:
    modules/memory

Memory must:
- Be indexed
- Be explicit
- Be recoverable

---

## Safety Model

The agent operates under:

- Explicit boundaries
- Observable actions
- Logged operations

All state mutation must be traceable.

---

## Evolution

Future agent upgrades must:

- Preserve core determinism
- Remain modular
- Be documented in roadmap
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

Rules:

Core must :
- Never depend on modules
- Never contain business logic
- Remain minimal and stable

Core = infrastructure only.

---

## Layer 2 — Cognitive Layer (Brain)

Directory :
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

Components :
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

Components :
- engine.sh
- ranker.sh

Purpose:
Composite retrieval and ranking.

Dependencies:
- memory/query.sh
- context/session.sh

Ranking formula :
composite_score =
normalized_fts
+ focus_boost
+ graph_boostt

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

### Features :
- SQLite WAL
- FTS5 search
- transactional indexing
- tag extraction
- markdown link graph
- file hash tracking
- graph adjacency queries
- deterministic path traversal support

### Modules must :
- remain isolated
- not mutate core
- expose explicit interfaces

## Graph Model

The memory module persists explicit graph relations in the links table.

Graph capabilities now include :
- outgoing link inspection
- backlinks inspection
- direct neighbors inspection
- path traversal over indexed markdown links
- graph proximity queries

Batch rebuild uses a two-pass strategy :
1. notes / FTS / tags materialization
2. graph link resolution

This guarantees forward links resolve correctly during deterministic rebuilds.

---

## Layer 4 — CLI Interface

Directory :
> bin/

### Components :
- bin/brain
- bin/kaobox-shell

### The CLI :
- parses user commands
- invokes the brain dispatcher
- never accesses the database directly as business logic owner

---

## Layer 5 — Runtime State

### Directory :
> state/

### Contains :
- version state
- language state
- runtime flags

Mutable by design.

---

## Layer 6 — Documentation

### Directory :
> doc/

### Contains :
- architecture
- roadmap
- phase history
- agent specifications
- test protocols

Documentation is considered part of the system contract.

---

## Brain Graph Surface

### Current graph-facing commands :
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

- semantic ranking layer
- reinforcement signals
- agent orchestration layer

## Status

Phase 3.5 — Graph-Aware Cognition  
System Status: Stable Cognitive Kernel with Graph Traversal and Graph-Aware Ranking
# KaoBox Module Contract

## Purpose

This document defines how modules interact with the KaoBox Core.

Modules extend the system.
They must never modify or weaken the Core.

The Core remains deterministic.
Modules provide business logic.

---

# Architectural Principle

Core = Infrastructure  
Modules = Engines  

Separation is mandatory.

---

# Location

All modules must reside in :
`/opt/kaobox/modules/<module_name>/`

Example :
`/opt/kaobox/modules/memory/`

---

# Required Structure

Each module must contain :
- init.sh        → initialization entrypoint
- index.sh       → public module entry
- query.sh       → public query interface (graph, search, traversal, etc.)

Recommended structure :
module/
├── engine/      → low-level logic
├── context/     → adaptive logic (if applicable)
├── init.sh
├── index.sh
├── query.sh
└── gc.sh

Modules must explicitly expose their public interface.

---

## Core Responsibilities

Core is responsible for :
- Environment bootstrap
- Logging system
- Sanity validation
- Locking
- Localization
- Runtime state management

Core provides :
- Logging utilities
- Environment variables
- Controlled execution context
- Stable runtime state

Core must remain :
- Deterministic
- Minimal
- Module-agnostic

---

## Allowed Interactions

Modules MAY :
Modules SHOULD prefer SQL emission patterns when interacting
with the persistence layer. Execution orchestration is handled
by higher-level runtime components.

- Use Core logging utilities
- Read from state/
- Write to logs/
- Use defined environment variables
- Persist their own data
- Register CLI commands through the dispatcher layer
- Maintain their own internal SQLite schema

Modules MAY implement :
- Adaptive ranking
- Context engines
- Graph logic
- Business-specific storage
- Traversal/query primitives

---

## Forbidden Interactions

Modules must NOT :
- Modify core/
- Modify base/
- Override bin/brain
- Directly alter golden.version
- Modify other modules
- Depend on undocumented global variables

Core integrity is non-negotiable.

---

## CLI Separation Rule

CLI layer (lib/brain/commands/) must :
- Validate arguments
- Call module interfaces
- Not contain business logic

Modules must expose callable functions.
CLI must orchestrate, not compute.

This rule applies especially to :
- SQL access
- graph traversal
- ranking logic
- state mutation rules

---

## Isolation Rule

Modules must :
- Be self-contained
- Fail safely
- Handle their own schema
- Not assume external state unless explicitly provided

If a module crashes, Core must remain operational.

---

## Determinism Rule

Core is deterministic.

Modules may introduce adaptive behavior,
but only inside their isolated engine.

Example :
- Context ranking
- Temporal decay
- Session boosting
- Graph traversal ordering

These must never compromise Core stability.

---

## Hook System (Future Extension)

Planned standard hooks :
- on_init
- on_before_execute
- on_after_execute
- on_shutdown

Hooks must be :
- Explicitly registered
- Non-invasive
- Optional

Core must function without any module installed.

---

## Data Ownership Rule

Each module owns :
- Its database schema
- Its indexing logic
- Its ranking model
- Its internal cache
- Its graph query API
- Its public query API

Core owns :
- Runtime state
- System versioning
- Execution safety

---

## Failure Model

Modules must :
- Fail explicitly
- Log errors
- Not silently corrupt state
- Not block system startup

Graceful degradation is mandatory.

---

## Extension Philosophy

### Modules are engines.

They may introduce :
- Intelligence
- Context
- Learning
- Ranking
- Traversal

But never structural instability.

---

## Contract Summary

Core :
- Deterministic
- Stable
- Minimal

Modules :
- Isolated
- Explicit
- Replaceable
- Evolvable

KaoBox evolves through modules, not by expanding the Core.
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
# KaoBox TODO

Version: v2.9  
Aligned with Phase 3.4 completion

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

Outcome:

Graph is now a first-class navigation surface in Brain.

---

# DONE (Phase 3.5 — Graph-Aware Cognition)

Goal achieved: promote graph structure from navigation layer
to active cognitive ranking signal.

- [x] Graph proximity query API (`query_graph_proximity_by_note`)
- [x] Graph context expansion in Think Engine
- [x] Graph proximity boost in ranking model
- [x] Composite ranking model implemented:
      normalized_fts + focus_boost + graph_boost
- [x] Deterministic integration with existing ranking pipeline
- [x] Test suite additions:
      - `test_graph_proximity.sh`
      - `test_think_graph_boost.sh`
- [x] CLI smoke test extended with `brain think`

Outcome :
The markdown graph is now used as a **cognitive relevance signal**
in addition to navigation..

---

# Immediate (Phase 3.6 — Graph Expansion)

- [ ] Configurable graph weighting
- [ ] Path-aware context expansion
- [ ] Related notes command based on graph distance
- [ ] Graph export groundwork
- [ ] Stronger ambiguous note resolution policy

---

# Short Term (Stabilization Layer)

- [ ] CLI regression test suite
- [ ] Index stress test
- [ ] Concurrent indexing validation
- [ ] Structured logging format (JSON-compatible)
- [ ] State validation command (`brain validate`)
- [ ] Memory indexing performance benchmarks
- [ ] Module capability introspection

---

# Mid Term (Phase 4 Preparation)

- [ ] Hybrid semantic ranking (FTS + graph)
- [ ] Context reinforcement signals
- [ ] Execution policy framework
- [ ] Multi-module orchestration model
- [ ] Agent task routing prototype

---

# Long Term (Distributed Brain)

- [ ] Snapshot export/import
- [ ] Remote node synchronization
- [ ] Multi-instance coordination
- [ ] External toolchain connectors
- [ ] Replication strategy design

---

# Architectural Constraint Reminder

All future work must:

- Preserve Core determinism
- Maintain module isolation
- Avoid hidden state
- Remain reversible where possible
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

# Phase 4 — Adaptive Layer (Planned)

Goal:

Extend contextual intelligence toward structured agent behavior.

Planned capabilities :
- Hybrid semantic ranking (FTS + graph)
- Cross-note reinforcement signals
- Multi-module orchestration
- Structured task planning
- Controlled execution graphs

Constraint :
Core must remain deterministic.  
Adaptation must remain modular.

---

# Phase 5 — Distributed Brain (Vision)

Long-term evolution :
- Multi-instance coordination
- State replication
- Remote orchestration
- Snapshot & recovery model
- External toolchain integration

---

# Architectural Trajectory

Phase 1 → Deterministic Foundation  
Phase 2 → Infrastructure Hardening  
Phase 3 → Contextual Intelligence  
Phase 3.4 → Graph Navigation  
Phase 3.5 → Graph-Aware Cognition (current milestone)   
Phase 4 → Structured Adaptation  
Phase 5 → Distributed Cognition  

---

# Current Position

Infrastructure: Stable  
Memory Engine: Production-grade  
Context Engine: Operational  
Observability: Integrated  
Graph Navigation: Integrated  
Graph Cognition: Integrated  
Agent Layer: Emerging  

KaoBox has transitioned from a structural system
to a **deterministic cognitive infrastructure** with explicit graph traversal.
# KaoBox Test Protocol

Version: v2.9  
Aligned with Phase 3.5 completion

A version can be validated only if all checks pass.

Validation must confirm:
- Determinism
- Isolation
- Integrity
- Reproducibility

---

# 1 Core Validation

Core must remain deterministic and stable.

Checks :
- `core/env.sh` loads without error
- `core/sanity.sh` returns success
- `core/logger.sh` initializes correctly
- `core/shell.sh` loads without side effects
- No module directly modifies `core/`

Failure of any check invalidates the release.

---

# 2 SQLite & Memory Engine Validation

Checks :
- WAL mode enabled
- `PRAGMA synchronous = FULL` or runtime durability policy consistent with current track
- Integrity check passes (`brain doctor`)
- Transaction wrapper enforces `BEGIN IMMEDIATE`
- No partial writes after simulated crash
- Reindex is idempotent
- No schema drift detected

Memory must be:
- Deterministic to rebuild
- Crash-safe
- Concurrency-safe

---

# 3 Memory Index Validation

Checks :
- Markdown notes are indexed
- Titles extracted correctly
- Tags extracted from `#tags`
- Links extracted from `[[links]]`
- File hash stored
- File mtime stored

Verification commands :
Verification:
brain graph <note>
brain backlinks <note>
brain neighbors <note>
brain path <a> <b>
query_graph_proximity_by_note <note_id>
sqlite3 brain.db "SELECT COUNT(*) FROM links;"

Expected :
- FTS rows == notes count
- tags count stable
- links count consistent

---

# 4 Graph Navigation Validation

Checks :
- Markdown links `[[note]]` detected
- Links inserted into `links` table
- `brain graph <note>` resolves outgoing and incoming edges
- `brain backlinks <note>` returns incoming links
- `brain neighbors <note>` returns direct graph neighbors
- `brain path <a> <b>` returns a deterministic traversal when a path exists
- Two-pass batch reindex resolves forward links correctly
- Graph proximity query returns deterministic neighbors

Verification :
brain graph <note>
brain backlinks <note>
brain neighbors <note>
brain path <a> <b>
sqlite3 brain.db "SELECT COUNT(*) FROM links;"

---

# 5 Context Engine Validation

Checks :
- Context resolver returns structured layers
- SELF node present
- GRAPH_IN nodes detected
- GRAPH_OUT nodes detected
- RECENT nodes included
- Temporal decay applied

Verification :
brain context <note>
brain context --trace <note>

Scoring must remain reproducible.

---

# 6 Think Engine Validation

Checks :
- FTS results retrieved
- Composite ranking applied
- Focus boost applied to active session
- Graph proximity boost applied when neighbors match
- Ranking stable across repeated queries

Verification :
brain think <query>

Expected :
- results sorted by composite score
- active session note boosted

---

# 7 Observability Validation

Checks :
- Runtime diagnostics available
- Context session visible
- Query explainability functional

Verification commands :
brain status
brain doctor
brain health
brain stats
brain session
brain explain <query>

Expected :
- DB integrity reported
- runtime metrics visible
- session focus displayed

---

# 8 CLI Validation

Checks :
- `brain` CLI loads correctly
- `brain --help` displays command list
- commands return correct exit codes
- no uncaught errors
- dispatcher contains no business logic
- `set -o pipefail` safe

CLI must orchestrate, not compute.

---

# 9 Module Isolation Validation

Checks :
- Modules load without modifying Core
- memory module initializes safely
- No module overrides `bin/brain`
- No module modifies `base/`
- Module failures do not crash CLI

Isolation is mandatory.

---

# 10 State Validation

Checks :
- `state/golden.version` matches runtime
- `state/system.lang` readable
- state directory writable
- session focus persistence works

State must remain explicit and recoverable.

---

# 11 Determinism Validation

Checks :
- Reindex twice → identical DB state
- Context query twice → identical ordering
- Think query twice → identical ranking
- Graph query twice → identical ordering
- Path query twice → identical traversal
- No hidden runtime memory
- No implicit global mutation

Core must remain deterministic.

Adaptive behavior must remain bounded to modules.

---

# 12 Validation Result

All checks must pass before :
- Phase closure
- Version bump
- Release tagging
- Documentation freeze

Failure of any check blocks release.

---

# Automated Test Suite

The following scripts must pass :
./tests/run_all.sh

Which includes :
- test_logger.sh
- test_memory_index.sh
- test_graph_navigation.sh
- test_graph_path.sh
- test_graph_proximity.sh
- test_think_graph_boost.sh
- test_brain_cli.sh
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


# KAOBOX — MANIFESTE FONDATEUR

### A Modular Deterministic Cognitive System

Version : 1.1  
Author : KaoLegion  
Project : KaoBox + KaoBox Brain  

---

# 1. Vision

KaoBox vise à construire un **système cognitif modulaire, déterministe et programmable**.

Ce système doit permettre d’orchestrer :
- la mémoire
- la connaissance
- le contexte
- les graphes de relations
- les outils
- les workflows cognitifs
- les futurs agents

L’objectif n’est pas seulement de stocker des notes.

L’objectif est de bâtir une **infrastructure cognitive explicite**.

---

# 2. Philosophie du projet

## 2.1 Modularité radicale

Chaque composant doit être :
- indépendant
- remplaçable
- testable
- extensible

Aucun composant ne doit devenir un monolithe opaque.

---

## 2.2 Déterminisme

Le système doit rester :
- prévisible
- reproductible
- auditable

Le déterminisme n’est pas une contrainte secondaire.
Il est au cœur de l’identité KaoBox.

---

## 2.3 Transparence

Les mécanismes internes doivent être :
- lisibles
- traçables
- inspectables

L’intelligence ne doit jamais être cachée dans des effets implicites.

---

## 2.4 IA augmentative

L’IA n’est pas un remplacement humain.

Elle est un **amplificateur cognitif**.

KaoBox doit permettre :
- d’augmenter la mémoire
- d’augmenter la navigation dans la connaissance
- d’augmenter le raisonnement contextualisé
- d’automatiser certaines opérations cognitives

---

# 3. Le concept de Brain

Le Brain est la couche cognitive de KaoBox.

Il agit comme :
- moteur mémoire
- moteur d’indexation
- moteur de recherche
- moteur de contexte
- moteur de graphe
- moteur de raisonnement

Il gère :
- les notes
- les métadonnées
- les tags
- les liens markdown
- les chemins entre notes

---

# 4. Architecture générale

KaoBox repose sur plusieurs couches :
- Core → infrastructure déterministe
- Brain → runtime cognitif
- Modules → moteurs spécialisés
- Data → mémoire, index, état
- Interfaces → CLI, agents, intégrations futures

Le système doit croître **par composition**, non par opacité.

---

# 5. KaoBox Brain aujourd’hui

Le Brain fournit déjà :

## 5.1 Memory Engine

- indexation transactionnelle
- stockage SQLite
- FTS5
- tags
- graph markdown

## 5.2 Context Engine

- couches SELF / GRAPH_OUT / GRAPH_IN / RECENT
- scoring temporel
- focus de session

## 5.3 Observability Layer

- health
- stats
- session
- explain
- diagnostics

## 5.4 Graph Navigation Layer

- `brain graph`
- `brain backlinks`
- `brain neighbors`
- `brain path`

KaoBox a maintenant dépassé la simple indexation.
Il entre dans une logique de **navigation cognitive explicite**.

## 5.5 Think Engine

- `brain think`
- composite ranking model
- focus-aware retrieval
- graph-aware ranking
- deterministic ranking pipeline

Ranking model :
normalized_fts  
+ focus_boost  
+ graph_boost

The Brain now uses graph proximity as a cognitive relevance signal,
not only as a navigation structure.

---

# 6. Le modèle cognitif

Le système vise une chaîne de transformation :

Entrées
↓
Memory
↓
Graph
↓
Context
↓
Think
↓
Action 

Les composants principaux sont :
- Inbox
- Memory
- Graph
- Context
- Think
- Action

---

# 7. Portabilité

KaoBox est conçu pour être :
- portable
- installable sur Linux
- indépendant d’une machine spécifique
- lisible sans dépendre d’une interface propriétaire

Le système doit pouvoir être transporté comme un **cerveau externe modulaire**.

---

# 8. Principes d’ingénierie

## Shell First

KaoBox privilégie :
- bash
- SQLite
- outils Unix
- scripts explicites

Ce choix favorise :
- la portabilité
- l’auditabilité
- la robustesse

## Infrastructure before intelligence

L’intelligence n’a de valeur que si l’infrastructure est saine.

## Tests as contract

Les tests ne sont pas accessoires.
Ils participent au contrat architectural.

---

# 9. Cas d’usage

KaoBox peut servir à :
- gestion de connaissance
- mémoire personnelle structurée
- recherche contextuelle
- navigation par graphe
- préparation d’agents
- système cognitif personnel portable

---

# 10. Trajectoire

Phase 1 → fondation  
Phase 2 → durcissement production  
Phase 3 → intelligence opérationnelle
Phase 3.4 → navigation graphe
Phase 3.5 → cognition graphe-aware  
Phase 4 → agents structurés  
Phase 5 → cognition distribuée  

---

# 11. Vision long terme

Créer une infrastructure où :
- humains
- IA
- agents
- outils

peuvent coopérer dans un **espace cognitif partagé, explicite et modulaire**.

KaoBox n’est pas simplement un gestionnaire de notes.

C’est une tentative de construire un **système cognitif programmable**.

---

# 12. Conclusion

KaoBox cherche à augmenter la pensée humaine sans sacrifier :
- la lisibilité
- le contrôle
- l’auditabilité
- le déterminisme

Ce n’est pas seulement un logiciel.

C’est une **infrastructure cognitive déterministe**.
