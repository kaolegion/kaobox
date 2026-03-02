## Module Communication Contract

- **Core** is responsible for:
  - Logging
  - Environment setup
  - Basic utilities
  
- **Modules** must not modify Core functionality.
- **Modules** can communicate with the Core only through predefined interfaces, such as logging utilities and configuration files.

---
# MAJ-OLD

# KaoBox Module Contract

## Purpose

Defines how modules are allowed to interact with the KaoBox core.

Modules must extend.
They must never modify.

---

## Location

All modules must reside in:

    /opt/kaobox/modules/<module_name>/

---

## Required Structure

Each module must contain:

- init.sh        → initialization entrypoint
- index.sh       → exposed functions registry

Optional:
- hooks.sh
- README.md
- config/

---

## Allowed Interactions

Modules may:

- Read from state/
- Append to logs/
- Register commands through defined hooks
- Execute isolated logic

Modules must NOT:

- Modify core/
- Modify base/
- Override bin/brain
- Directly alter golden.version

---

## Hook System (Planned Phase 2)

Future standard hooks:

- on_init
- on_before_execute
- on_after_execute
- on_shutdown

Hooks must be explicitly registered.

---

## Isolation Rule

Modules must:

- Be self-contained
- Fail safely
- Not assume global variables unless defined by core

---

## Determinism Rule

Core must remain deterministic.

Modules may introduce adaptive behavior,
but never at the cost of core integrity.
