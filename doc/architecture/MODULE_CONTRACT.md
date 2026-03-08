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

`/opt/kaobox/modules/<module_name>/`

Example:
`/opt/kaobox/modules/memory/`

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

## Core Responsibilities

### Core is responsible for:

- Environment bootstrap
- Logging system
- Sanity validation
- Locking
- Localization
- Runtime state management

### Core provides:

- Logging utilities
- Environment variables
- Controlled execution context
- Stable runtime state

### Core must remain:

- Deterministic
- Minimal
- Module-agnostic

---

## Allowed Interactions

### Modules MAY:

- Use Core logging utilities
- Read from state/
- Write to logs/
- Use defined environment variables
- Persist their own data
- Register CLI commands through the dispatcher layer
- Maintain their own internal SQLite schema

### Modules MAY implement:

- Adaptive ranking
- Context engines
- Graph logic
- Business-specific storage
- Traversal/query primitives

---

## Forbidden Interactions

### Modules must NOT:

- Modify core/
- Modify base/
- Override bin/brain
- Directly alter golden.version
- Modify other modules
- Depend on undocumented global variables

Core integrity is non-negotiable.

---

## CLI Separation Rule

### CLI layer (lib/brain/commands/) must:

- Validate arguments
- Call module interfaces
- Not contain business logic

Modules must expose callable functions.
CLI must orchestrate, not compute.

This rule applies especially to:

- SQL access
- graph traversal
- ranking logic
- state mutation rules

---

## Isolation Rule

### Modules must:

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

### Example:

- Context ranking
- Temporal decay
- Session boosting
- Graph traversal ordering

These must never compromise Core stability.

---

## Hook System (Future Extension)

###Planned standard hooks:

- on_init
- on_before_execute
- on_after_execute
- on_shutdown

### Hooks must be:

- Explicitly registered
- Non-invasive
- Optional

Core must function without any module installed.

---

## Data Ownership Rule

Each module owns:

- Its database schema
- Its indexing logic
- Its ranking model
- Its internal cache
- Its graph query API

Core owns:

- Runtime state
- System versioning
- Execution safety

---

##Failure Model

Modules must:

- Fail explicitly
- Log errors
- Not silently corrupt state
- Not block system startup

Graceful degradation is mandatory.

---

## Extension Philosophy

### Modules are engines.

They may introduce:

- Intelligence
- Context
- Learning
- Ranking
- Traversal

But never structural instability.

---

## Contract Summary

### Core:

- Deterministic
- Stable
- Minimal

### Modules:

- Isolated
- Explicit
- Replaceable
- Evolvable

KaoBox grows through modules, not by expanding the Core.
