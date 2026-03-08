# KaoBox Agent Specification

## Purpose

The KaoBox Agent is a structured operational intelligence layer
running on top of the deterministic core.

It does not replace the system.
It orchestrates it.

The agent interacts with the Brain runtime
through explicit commands and module APIs.

---

## Agent Nature

The agent is :
- Deterministic-aware
- State-conscious
- Modular
- Tool-driven
- Language-aware
- Graph-aware

It must never :
- Corrupt core
- Modify base manifests directly
- Break deterministic guarantees

---

## Agent Layers

### 1. Perception

Reads :
- `state/`
- manifests
- module availability
- environment variables
- Brain graph structure

Typical sources :
- memory index
- graph relations
- context engine signals

---

### 2. Reasoning

Uses :
- Brain CLI commands
- module APIs
- deterministic scripts
- explicit reasoning flows

No hidden state allowed.

Typical reasoning inputs :
- search results
- graph neighbors
- graph proximity signals
- contextual ranking

---

### 3. Action

Allowed actions :
- Execute modules
- Invoke Brain CLI commands
- Update runtime state
- Log operations
- Trigger safe hooks

Forbidden :
- Direct modification of `core/`
- Direct modification of base manifests
- Bypassing module interfaces

---

## Brain Interface

The agent interacts with KaoBox through the Brain runtime.

Primary interface : 
brain <command>

Examples :
brain search <query>
brain think <query>
brain graph <note>
brain neighbors <note>
brain path <a> <b>
brain export graph

The agent must never bypass the Brain dispatcher.

All execution must remain observable and reproducible.

---

## Memory

Memory is modular.

Current module :
modules/memory

Memory must :
- Be indexed
- Be explicit
- Be recoverable
- Remain deterministic to rebuild

The memory module exposes :
- indexing primitives
- query primitives
- graph traversal APIs
- export surfaces

---

## Graph Awareness

The agent may use the Brain graph to :
- explore note relationships
- identify relevant context
- discover related notes
- reason about structural proximity

Graph traversal must remain deterministic.

Possible tools :
brain graph
brain backlinks
brain neighbors
brain path

---

## Graph Export

The Brain graph can be exported for external processing.

Export command :
brain export graph

Output format :
source_path<TAB>target_path


The agent may use this export surface to :
- feed external reasoning tools
- build visualization pipelines
- analyze graph structure

Export remains read-only and module-owned.

---

## Safety Model

The agent operates under :
- Explicit boundaries
- Observable actions
- Logged operations

All state mutation must be traceable.

The agent must always prefer :
- module APIs
- Brain commands
- deterministic scripts

over direct system mutation.

---

## Evolution

Future agent upgrades must :
- Preserve core determinism
- Remain modular
- Be documented in the roadmap
- Maintain compatibility with module contracts

Agent capabilities may evolve toward :
- contextual task orchestration
- multi-module coordination
- structured execution planning
