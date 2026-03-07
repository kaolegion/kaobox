E:\Documents-Kao\kaobox\lib\LIB_GLOBAL.md

# KaoBox Brain Commands

## Overview

`lib/brain/commands/` contains the **CLI-facing command handlers** of the KaoBox Brain runtime.

These commands are the user-visible interface of the cognitive kernel.

They do not own storage logic.  
They orchestrate:

- Brain runtime helpers
- context engine
- think engine
- memory module interfaces

This directory represents the **operational command surface** of `brain`.

---

# Command Design Rules

Commands must:

- remain deterministic
- validate input explicitly
- avoid direct business logic when a lower layer exists
- use Brain runtime helpers when available
- preserve module isolation

Commands are orchestration units, not engines.

---

# Command Categories

## System Commands

### `status`
Displays Brain runtime state:

- paths
- database location
- log level
- basic runtime availability

### `doctor`
Runs structural diagnostics:

- database existence
- notes directory existence
- schema validation
- SQLite integrity check

---

## Memory Commands

### `new`
Creates a new note and indexes it transactionally.

### `open`
Resolves and opens a note from the index.

### `ls`
Lists indexed notes with metadata.

### `search`
Queries the memory engine using:

- FTS
- tag queries
- backlinks queries

### `reindex`
Rebuilds the memory index transactionally.

### `fuzzy`
Interactive fuzzy note selection using `fzf`.

---

## Context Commands

### `context`
Displays contextual candidates for a note.

Supports:

- standard contextual ranking
- `--trace` observability mode

### `focus`
Sets the active session note and resolves its context.

---

## Think Commands

### `think`
Executes context-aware retrieval and ranking.

It combines:

- memory FTS retrieval
- session focus
- composite scoring

---

## Graph Commands

### `graph`
Displays outgoing links and backlinks for a note.

This command depends on the indexed markdown graph.

---

## Observability Commands

### `health`
Displays runtime metrics:

- notes count
- tags count
- links count
- FTS rows
- database size
- integrity status

### `stats`
Displays Brain statistics in summary form.

### `session`
Displays the current active Brain session focus.

### `explain`
Displays query explainability output.

Supports:

- query summary
- result display
- `--trace` query plan output

---

# Command Execution Model

Execution flow:

brain <command>
  ↓
dispatcher.sh
  ↓
commands/<command>.sh
  ↓
context / think / memory interfaces
  ↓
modules/*

Commands are invoked only through the dispatcher.

---

Runtime Dependencies

Commands may depend on:

preflight_check

safe_source

render_results

sanitize_fts

acquire_lock / release_lock

query_fts

resolve_context

score_context

think_engine_run

This keeps command handlers thin and composable.

---

## Current Command Surface
	
Validated commands:

brain status
brain doctor
brain health
brain stats
brain session
brain explain
brain new
brain open
brain ls
brain search
brain reindex
brain fuzzy
brain context
brain focus
brain think
brain graph

## Status

Track: v2.9
Phase: 3.3 — Observability Layer Stable

Command layer status:

- stable
- shellcheck-clean
- runtime validated
- graph-aware
- observability integrated
