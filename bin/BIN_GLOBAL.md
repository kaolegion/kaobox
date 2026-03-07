E:\Documents-Kao\kaobox\bin\BIN_BRAIN_GLOBAL.md

## KaoBox CLI Entry Points

The bin/ directory contains the user-facing entrypoints of KaoBox.

These scripts provide the external interface to the system while keeping the internal architecture isolated.

The entrypoints are intentionally minimal and deterministic.

---

## Design Principles

Entry points must:
- contain no business logic
- perform only environment bootstrap
- delegate execution to the internal runtime
- remain deterministic and portable

All cognitive logic resides inside:

> lib/brain/

Modules are located in:

> modules/

---

## Structure

bin/
 ├── brain
 └── kaobox-shell

---

## brain

Primary CLI interface to the KaoBox Brain.

Example usage:

> brain status
> brain search "query"
> brain think "query"
> brain reindex

### Responsibilities

The entrypoint performs only minimal tasks:

1. Validate Bash version
2. Resolve the installation path (symlink-safe)
3. Detect KAOBOX_ROOT
4. Prevent interactive profile bootstrap
5. Load the Brain dispatcher
6. Delegate execution

Execution flow:

brain
  ↓
lib/brain/dispatcher.sh
  ↓
lib/brain/commands/*
  ↓
modules/*

This design guarantees that the CLI remains a thin deterministic layer.

---

## kaobox-shell

Minimal interactive shell environment for KaoBox.

It provides a simple prompt to execute commands within the KaoBox runtime environment.

Example:

> kaobox>

Supported built-in commands:

> help
> exit
> env

Any other command is executed directly by the local shell.

The shell runner does not implement system logic and serves only as a convenience interface.

---

## Entry Point Guarantees

Both entrypoints follow strict design guarantees:

- deterministic startup
- zero domain logic
- environment bootstrap only
- safe path resolution
- dispatcher delegation

These guarantees ensure that KaoBox remains modular and auditable.

---

## Architectural Role

The bin/ directory forms the boundary between the user and the cognitive kernel.

System flow:

User
 ↓
bin/brain
 ↓
Brain Dispatcher
 ↓
Commands
 ↓
Modules
 ↓
SQLite + Filesystem

---

## Future Evolution

The entrypoints may later support:

- environment profiles
- execution policies
- debugging modes
- distributed runtime invocation

However they must remain minimal and deterministic.

---

## Status

Track: v2.9
Phase: 3.3 — Observability Layer

Entry points are considered stable.
