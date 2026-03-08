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
/opt/kaobox/modules/<module_name>/

Example :
/opt/kaobox/modules/memory/


---

# Required Structure

Each module must contain :
- `init.sh` → initialization entrypoint
- `index.sh` → indexing / ingestion interface
- `query.sh` → public query interface

Recommended structure :
module/
├── engine/ → low-level logic
├── context/ → adaptive logic (optional)
├── init.sh
├── index.sh
├── query.sh
├── export.sh → external export surface (optional)
└── gc.sh


Modules must explicitly expose their **public interface**.

---

# Core Responsibilities

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

# Allowed Interactions

Modules MAY :
- Use Core logging utilities
- Read from `state/`
- Write to `logs/`
- Use defined environment variables
- Persist their own data
- Maintain their own SQLite schema
- Register CLI commands through the dispatcher layer

Modules SHOULD prefer **SQL emission patterns** when interacting with the persistence layer.

Execution orchestration must remain in the runtime layer.

Modules MAY implement :
- Adaptive ranking
- Context engines
- Graph logic
- Business-specific storage
- Traversal/query primitives
- Export surfaces for external systems

---

# Forbidden Interactions

Modules must NOT :
- Modify `core/`
- Override `bin/brain`
- Modify other modules
- Directly alter `golden.version`
- Depend on undocumented global variables

Core integrity is non-negotiable.

---

# CLI Separation Rule

The CLI layer (`lib/brain/commands/`) must :
- Validate arguments
- Call module interfaces
- Never contain business logic

Modules must expose callable functions.

CLI must **orchestrate**, not compute.

This rule applies especially to :
- SQL access
- Graph traversal
- Ranking logic
- Export logic
- State mutation

---

# Module API Rule

Modules must expose explicit functions that serve as **public module APIs**.

Example :

Memory module exports :
index_note
query_notes
query_graph_neighbors
query_graph_path
export_graph_edges_tsv


The Brain runtime may call these APIs, but must not replicate their internal logic.

---

# Graph Export Rule

Graph extraction and export logic must remain **module-owned**.

Example implementation : modules/memory/export.sh

CLI exposure :
brain export graph
brain export graph --format tsv

The CLI must only dispatch to module functions.

This ensures :
- deterministic exports
- reusable graph pipelines
- separation of concerns

---

# Isolation Rule

Modules must :
- Be self-contained
- Fail safely
- Handle their own schema
- Not assume external state unless explicitly provided

If a module crashes, Core must remain operational.

---

# Determinism Rule

Core is deterministic.

Modules may introduce adaptive behavior,
but only inside their isolated engines.

Examples :
- Context ranking
- Temporal decay
- Session boosting
- Graph traversal ordering

These must never compromise Core stability.

---

# Hook System (Future Extension)

Planned standard hooks :
- `on_init`
- `on_before_execute`
- `on_after_execute`
- `on_shutdown`

Hooks must be :
- Explicitly registered
- Non-invasive
- Optional

Core must function without any module installed.

---

# Data Ownership Rule

Each module owns :
- Its database schema
- Its indexing logic
- Its ranking model
- Its internal cache
- Its graph query API
- Its export surfaces
- Its public query API

Core owns :
- Runtime state
- System versioning
- Execution safety

---

# Failure Model

Modules must :
- Fail explicitly
- Log errors
- Not silently corrupt state
- Not block system startup

Graceful degradation is mandatory.

---

# Extension Philosophy

Modules are engines.

They may introduce :
- Intelligence
- Context
- Learning
- Ranking
- Traversal
- External export pipelines

But never structural instability.

---

# Contract Summary

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
