## System Layers

### Layer 0 — OS
Linux environment

### Layer 1 — Kaobox Core
`core/`
`init.sh`
`state/`
`lang/`

Responsibilities:
- Bootstrap
- Environment setup
- Logging
- Safety
- Localization

### Layer 2 — Modules
`lib/*`
`modules/*`

Responsibilities:
- Business logic
- Storage
- CLI commands

### Layer 3 — CLI Entrypoints
`bin/*`

---
# MAJ-OLD

# KaoBox Architecture

## Overview

KaoBox is a modular agentic infrastructure designed as a deterministic brain system.

Root path:
    /opt/kaobox

The system is structured in layers.

---

## Layer 1 — Base

Directory:
    base/

Contains system manifests.

Purpose:
- Define golden state
- Define required tools
- Define minimal runtime expectations

---

## Layer 2 — Core

Directory:
    core/

Contains the system engine.

Components:
- env.sh       → environment bootstrap
- logger.sh    → logging system
- sanity.sh    → validation checks
- i18n.sh      → language support
- init.sh      → system initialization

Core is deterministic and must not depend on modules.

---

## Layer 3 — Modules

Directory:
    modules/

Optional extensions.

Current module:
    memory/

Modules must:
- Be isolated
- Not modify core directly
- Use defined hooks

---

## Layer 4 — Runtime State

Directory:
    state/

Contains:
- version state
- language state
- runtime flags

This directory is mutable.

---

## Layer 5 — Documentation

Directory:
    doc/

Contains system-level documentation:
- architecture
- agent specification
- roadmap
- state records

---

## Design Principles

- Deterministic core
- Modular extensions
- Explicit state
- Minimal surface
- Infrastructure first, intelligence second
