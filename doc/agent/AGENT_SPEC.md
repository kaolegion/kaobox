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
