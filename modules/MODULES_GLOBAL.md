E:\Documents-Kao\kaobox\modules\MODULES_GLOBAL.md

# KaoBox Memory Module

## Overview

`modules/memory/` is the **persistent knowledge module** of KaoBox Brain.

It is responsible for:

- note indexing
- transactional storage updates
- full-text search integration
- tag extraction
- markdown link graph construction
- deterministic rebuild of memory state

This module is the primary storage engine currently used by the Brain.

---

# Design Rules

The memory module must:

- remain isolated from `core/`
- expose explicit interfaces
- preserve transactional integrity
- keep deterministic rebuild behavior
- avoid hidden mutable state

The module is allowed to depend on Brain runtime environment,
but must not mutate Brain orchestration logic.

---

# Structure

modules/memory/
├── init.sh
├── index.sh
├── query.sh
├── gc.sh
└── engine/
    ├── utils.sh
    ├── metadata.sh
    ├── fts.sh
    ├── tags.sh
    ├── links.sh
    └── tx.sh

## Module Components
> init.sh

Initializes the Memory module.

Responsibilities:

- create Brain filesystem structure
- initialize SQLite schema
- enable WAL mode
- prepare FTS, tags and links tables

Guarantees:

- idempotent schema initialization
- graph-ready storage
- Brain storage bootstrap

---

## index.sh

Main transactional indexing orchestrator.

Responsibilities:

- load engine components
- analyze markdown notes
- index a single note
- batch reindex all notes
- invoke garbage collection
- run WAL maintenance
	
This file is the operational heart of the module.

---

> query.sh

Read/query layer of the memory module.

Provides:

- FTS queries
- tag queries
- backlinks queries

Output is structured for Brain commands and ranking engines.

---

> gc.sh

Garbage collection layer.

Responsibilities:

- remove deleted notes from the database
- clean orphan tag relations
- clean orphan links
- clean unused tags
- clean orphan FTS rows

This keeps the index deterministic and rebuild-safe.

---

## Engine Layer

Directory:

> modules/memory/engine/

This layer contains low-level helpers used by index.sh.

---

## SQL Emitters

These files emit SQL only:

> metadata.sh

Emit SQL for the notes table.

> fts.sh

Emit SQL for the notes_fts table.

> tags.sh

Emit SQL for tag extraction and note_tags linkage.

> links.sh

Emit SQL for markdown link graph creation.

> tx.sh

Emit transaction SQL:

- BEGIN IMMEDIATE
- COMMIT
- ROLLBACK

---

## Analysis Helper
> utils.sh

This file is not a SQL emitter.

It provides:

- file validation
- title extraction
- content hashing
- file size / mtime retrieval
- SQL escaping
- shared analysis state for index orchestration

It prepares the data consumed by SQL emitters.

---

## Data Model

The memory module manages:

- notes
- notes_fts
- tags
- note_tags
- links

This enables:

- persistent note metadata
- FTS retrieval
- tag navigation
- graph navigation

---

## Indexing Model

Indexing flow:

Markdown note
  ↓
analyze_file()
  ↓
metadata_sql()
fts_sql()
tags_sql()
links_sql()
  ↓
transaction stream
  ↓
sqlite3 execution

This model preserves:

- explicit state mutation
- deterministic rebuild
- transactional writes

---

## Graph Model

Markdown links are parsed from:

[[note]]
[[note.md]]
[[note|alias]]
[[note#section]]

The module resolves links against indexed notes using:

- note title
- note path
- .md filename variants

This allows the Brain to maintain a usable markdown graph.

---

## Guarantees

The memory module currently provides:

- transactional indexing
- deterministic reindexing
- FTS search
- tag extraction
- graph indexing
- garbage collection
- WAL-based persistence

---

## Current Status

Track: v2.9
Phase: 3.3 — Observability Layer Stable

Memory module status:

- operational
- graph-aware
- shellcheck-clean
- runtime validated
- transaction-safe

