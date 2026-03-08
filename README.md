# KaoBox

KaoBox is a modular deterministic cognitive system for Linux. **deterministic brain kernel**

It is designed as a programmable brain runtime capable of managing:

- knowledge
- notes
- projects
- context
- graph relations
- cognitive workflows
- future agent orchestration

Root path:

> `/opt/kaobox`

---

## Brain CLI

Main entrypoint:

> brain <command>

Examples:

- brain status
- brain search "query"
- brain think "query"
- brain graph test
- brain backlinks test
- brain neighbors test
- brain path test-modular test
- brain reindex

---

## Architecture

### Main layers:

- core/ → deterministic infrastructure
- lib/brain/ → cognitive runtime
- modules/ → domain engines
- bin/ → CLI entrypoints
- doc/ → architecture and roadmap
- tests/ → validation suite

---

## Current State

Track: v2.9
Current phase: Phase 3.4 — Graph Navigation

### Delivered capabilities:

- transactional memory indexing
- FTS5 retrieval
- tag extraction
- markdown graph extraction
- observability commands
- graph navigation commands
- deterministic path traversal

---

## Graph Commands

> brain graph <note>
> brain backlinks <note>
> brain neighbors <note>
> brain path <from_note> <to_note>

These commands use the indexed markdown graph as an explicit navigation layer.

---

## Testing

### Run all tests:

> ./tests/run_all.sh

### Expected result:

> [SUCCESS] All tests passed

---

## Principles

- deterministic core
- modular isolation
- explicit state
- no hidden side effects
- shell-first design
- infrastructure before intelligence

---

## Vision

KaoBox is not only a note tool.

It is a deterministic cognitive infrastructure designed to evolve toward graph-aware cognition and structured agent orchestration.
