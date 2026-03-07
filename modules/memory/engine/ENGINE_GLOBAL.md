E:\Documents-Kao\kaobox\modules\memory\engine\ENGINE_GLOBAL.md

# Memory Engine Layer

`modules/memory/engine/` contains the low-level building blocks of the KaoBox Memory module.

## Responsibilities

- emit SQL fragments for indexing
- analyze files before indexing
- expose transaction primitives

## Files

- `utils.sh` → file analysis helpers
- `metadata.sh` → notes metadata SQL
- `fts.sh` → full-text indexing SQL
- `tags.sh` → tag extraction SQL
- `links.sh` → markdown graph SQL
- `tx.sh` → transaction SQL

## Rule

Except for `utils.sh`, engine files should remain **SQL emitters only**.

This layer must stay reusable, deterministic, and isolated from CLI concerns.
