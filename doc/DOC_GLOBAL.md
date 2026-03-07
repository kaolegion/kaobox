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

All modules must reside in:

/opt/kaobox/modules/<module_name>/

Example:
/opt/kaobox/modules/memory/

---

# Required Structure

Each module must contain:

- init.sh        → initialization entrypoint
- index.sh       → public module entry
- query.sh       → exposed query interface (if applicable)

Recommended structure:

module/
├── engine/      → low-level logic
├── context/     → adaptive logic (if applicable)
├── init.sh
├── index.sh
├── query.sh
└── gc.sh

Modules must explicitly expose their public interface.

---

# Core Responsibilities

Core is responsible for:

- Environment bootstrap
- Logging system
- Sanity validation
- Locking
- Localization
- Runtime state management

Core provides:

- Logging utilities
- Environment variables
- Controlled execution context
- Stable runtime state

Core must remain:

- Deterministic
- Minimal
- Module-agnostic

---

# Allowed Interactions

Modules MAY:

- Use Core logging utilities
- Read from state/
- Write to logs/
- Use defined environment variables
- Persist their own data
- Register CLI commands through the dispatcher layer
- Maintain their own internal SQLite schema

Modules MAY implement:

- Adaptive ranking
- Context engines
- Graph logic
- Business-specific storage

---

# Forbidden Interactions

Modules must NOT:

- Modify core/
- Modify base/
- Override bin/brain
- Directly alter golden.version
- Modify other modules
- Depend on undocumented global variables

Core integrity is non-negotiable.

---

# CLI Separation Rule

CLI layer (lib/brain/commands/) must:

- Validate arguments
- Call module interfaces
- Not contain business logic

Modules must expose callable functions.
CLI must orchestrate, not compute.

---

# Isolation Rule

Modules must:

- Be self-contained
- Fail safely
- Handle their own schema
- Not assume external state unless explicitly provided

If a module crashes,
Core must remain operational.

---

# Determinism Rule

Core is deterministic.

Modules may introduce adaptive behavior,
but only inside their isolated engine.

Example:
- Context ranking
- Temporal decay
- Session boosting

These must never compromise Core stability.

---

# Hook System (Future Extension)

Planned standard hooks:

- on_init
- on_before_execute
- on_after_execute
- on_shutdown

Hooks must be:

- Explicitly registered
- Non-invasive
- Optional

Core must function without any module installed.

---

# Data Ownership Rule

Each module owns:

- Its database schema
- Its indexing logic
- Its ranking model
- Its internal cache

Core owns:

- Runtime state
- System versioning
- Execution safety

---

# Failure Model

Modules must:

- Fail explicitly
- Log errors
- Not silently corrupt state
- Not block system startup

Graceful degradation is mandatory.

---

# Extension Philosophy

Modules are engines.

They may introduce:

- Intelligence
- Context
- Learning
- Ranking

But never structural instability.

---

# Contract Summary

Core:
- Deterministic
- Stable
- Minimal

Modules:
- Isolated
- Explicit
- Replaceable
- Evolvable

KaoBox grows through modules,
not by expanding the Core.
# KaoBox Roadmap

Version: v2.9  
Last Update: 2026-03-04

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

Objectives:

- Clean layered architecture
- Deterministic Core
- Strict separation between Core and Modules
- Environment contract stabilization
- Modular engine design
- Documentation baseline

Memory:

- Brain module initialized
- SQL-only emission model
- Transaction wrapper architecture
- Explicit schema ownership

Status: COMPLETE

---

# Phase 2 — Production Hardening (Brain v2.8) ✅

Objective:

Transform Brain into a production-grade,
concurrency-safe memory engine.

Delivered:

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

Tag: v2.8  
Branch: release/brain-v2.8  
Status: STABLE

---

# Phase 3 — Operational Intelligence (v2.9) 🚧

Objective:

Build a stable operational layer
on top of the hardened infrastructure.

## Phase 3.1 — CLI Stabilization

- Command normalization
- Dispatcher cleanup
- Argument validation consistency
- Shell integration
- Completion system

## Phase 3.2 — Context Engine ✅

Location:
modules/memory/context/

Delivered:

- Context resolver
- Adaptive scoring model
- Session focus tracking
- Layered ranking system

Context Layers:

- SELF
- GRAPH_OUT
- GRAPH_IN
- RECENT

Scoring Model:

Score =
    (Layer Weight × Temporal Decay)
    + Session Boost

Outcome:

Context-aware memory navigation
without breaking Core determinism.

Status: STABLE

---

## Phase 3.3 — Observability & Health (Next)

Goals:

- Runtime health scoring
- Context diagnostics
- Brain explainability output
- Focus traceability
- CLI introspection tools

Expected outcome:

Transparent operational intelligence layer.

Status: IN PROGRESS

---

# Phase 4 — Adaptive Layer

Goal:

Introduce controlled adaptive intelligence
above deterministic infrastructure.

Planned:

- Hybrid semantic indexing (FTS + graph)
- Context-aware execution policies
- Cross-note graph reinforcement
- Multi-module orchestration
- Structured planning layer
- Agent task routing

Constraint:

Adaptive logic must remain modular.
Core must remain deterministic.

Expected outcome:

Semi-autonomous structured agent.

Status: PLANNED

---

# Phase 5 — Distributed Brain (Long-Term)

Vision:

Extend KaoBox beyond a single runtime.

Goals:

- Multi-brain instances
- State replication
- Remote orchestration
- Snapshot & recovery layer
- External toolchain integration

Expected outcome:

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

Brain v2.8 is production-hardened and concurrency-safe.

Phase 3.2 Context Engine is operational and stable.

KaoBox is transitioning from:

Infrastructure maturity  
→ Operational intelligence  
→ Structured adaptive cognition
# KaoBox TODO

Version: v2.9  
Aligned with Phase 3.2 completion

---

# Immediate (Phase 3.3 — Observability)

- [ ] Implement context explainability output (`brain context --explain`)
- [ ] Add health scoring command (`brain health`)
- [ ] Add session inspection command (`brain session`)
- [ ] Add runtime diagnostics summary
- [ ] Validate CLI exit codes consistency
- [ ] Harden pipefail across dispatcher

---

# Short Term (Stabilization Layer)

- [ ] Structured logging format (JSON-compatible)
- [ ] Add state validation script (`brain validate`)
- [ ] Improve memory indexing performance benchmarks
- [ ] Add module enable/disable mechanism
- [ ] Add module capability introspection

---

# Mid Term (Phase 4 Preparation)

- [ ] Hybrid semantic indexing (FTS + graph ranking)
- [ ] Context reinforcement signals
- [ ] Execution policy framework
- [ ] Multi-module orchestration model
- [ ] Agent task routing prototype

---

# Long Term (Distributed Brain)

- [ ] Snapshot export/import mechanism
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

---

# Next: Graph Boost

- Boost notes linked to active note
- Weight configurable
- Based on links table
# KaoBox Phase History

This document tracks architectural milestones.
Each phase represents a structural evolution of the system.

---

# Phase 1 — Structural Foundation ✅

Version: v1.0.0-alpha  
Status: COMPLETED

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

Version: v2.8  
Status: COMPLETED  
Branch: release/brain-v2.8

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

# Phase 3 — Operational Intelligence 🚧

Version: v2.9  
Status: IN PROGRESS

Goal:

Build structured operational intelligence
on top of hardened infrastructure.

---

## Phase 3.1 — CLI Stabilization ✅

- Command normalization
- Dispatcher cleanup
- Separation between CLI and business logic
- Shell integration
- Completion groundwork

CLI now orchestrates modules without containing logic.

---

## Phase 3.2 — Context Engine ✅

Location:
modules/memory/context/

## Phase 3.2+ — Think Engine Stabilization

- Composite ranking stabilized
- Safe TAB parsing
- Session-based focus boost integrated
- Strict dependency loading enforced
- Documentation aligned with structure

### Delivered

- Context resolver
- Layered context model (SELF, GRAPH_IN, GRAPH_OUT, RECENT)
- Adaptive scoring engine
- Temporal decay model
- Session focus persistence

### Architectural Impact

- Introduced contextual awareness
- Preserved Core determinism
- Maintained module isolation

This phase marks the first controlled adaptive layer.

---

## Phase 3.3 — Observability (Next)

Planned:

- Health scoring system
- Context explainability output
- Focus trace tracing
- Runtime introspection commands

Objective:

Make intelligence transparent and inspectable.

---

# Phase 4 — Adaptive Layer (Planned)

Goal:

Extend contextual intelligence toward structured agent behavior.

Planned capabilities:

- Hybrid semantic indexing (FTS + graph)
- Cross-note reinforcement signals
- Multi-module orchestration
- Structured task planning
- Controlled execution graphs

Constraint:

Core must remain deterministic.
Adaptation must remain modular.

---

# Phase 5 — Distributed Brain (Vision)

Long-term evolution:

- Multi-instance coordination
- State replication
- Remote orchestration
- Snapshot & recovery model
- External toolchain integration

## Phase 6 – Think Engine Stabilization

Date: 2026-03-05

- Fixed parsing robustness in ranker
- Integrated session-based focus boost
- Enforced strict dependency loading
- Stabilized composite scoring

---

# Architectural Trajectory

Phase 1 → Deterministic Foundation  
Phase 2 → Infrastructure Hardening  
Phase 3 → Contextual Intelligence  
Phase 4 → Structured Adaptation  
Phase 5 → Distributed Cognition  

---

# Current Position

Infrastructure: Stable  
Memory Engine: Production-grade  
Context Engine: Operational  
Agent Layer: Emerging  

KaoBox has transitioned from a structural system
to a controlled cognitive infrastructure.
# KaoBox Test Protocol

Version: v2.9  
Aligned with Phase 3.2 completion

A version can be validated only if all checks pass.

Validation must confirm:

- Determinism
- Isolation
- Integrity
- Reproducibility

---

# 1️⃣ Core Validation

Core must remain deterministic and stable.

Checks:

- env.sh loads without error
- sanity.sh returns success
- logger.sh initializes properly
- shell bootstrap executes without side effects
- No module directly modifies core/

Failure of any check invalidates the release.

---

# 2️⃣ SQLite & Memory Engine Validation (Phase 2)

Checks:

- WAL mode enabled
- PRAGMA synchronous = FULL
- Integrity check passes (`brain doctor`)
- Transaction wrapper enforces BEGIN IMMEDIATE
- No partial writes after simulated crash
- Reindex is idempotent
- No schema drift detected

Memory must be:

- Deterministic to rebuild
- Crash-safe
- Concurrency-safe

---

# 3️⃣ Context Engine Validation (Phase 3.2)

Checks:

- resolve_context returns structured layers
- score_context returns sorted numeric scores
- SELF note appears in results
- Session boost applied correctly
- Temporal decay behaves consistently
- No direct SQL inside CLI commands

Scoring must be reproducible.

Context must not mutate state unexpectedly.

---

# 4️⃣ CLI Validation

Checks:

- brain --help executes
- brain exits cleanly
- Commands return proper exit codes
- No uncaught errors
- Dispatcher does not contain business logic
- set -o pipefail behavior validated

CLI must orchestrate, not compute.

---

# 5️⃣ Module Validation

Checks:

- Modules load without breaking Core
- memory module initializes safely
- No module overrides bin/brain
- No module modifies base/
- Modules handle failure gracefully

Isolation is mandatory.

---

# 6️⃣ State Validation

Checks:

- golden.version matches runtime
- state directory writable
- No forbidden file mutation
- Session focus persistence works
- Runtime flags consistent

State must be explicit and recoverable.

---

# 7️⃣ Determinism Validation

Checks:

- Reindex twice → identical DB state
- Context query twice → identical ordering (if no new writes)
- No hidden runtime memory
- No implicit global mutation

Core must remain deterministic.
Adaptive behavior must remain bounded to modules.

---

# 8️⃣ Validation Result

All checks must pass before:

- Phase closure
- Version bump
- Release tagging
- Documentation freeze

Failure to meet any check blocks release.
