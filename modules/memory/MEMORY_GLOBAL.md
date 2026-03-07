#!/usr/bin/env bash
set -euo pipefail

# ==========================================================
# KAOBOX - Memory Garbage Collector (v2.6)
# ----------------------------------------------------------
# - Emits SQL only
# - No transaction control (handled by index.sh)
# - Safe against accidental full wipe
# - Cleans:
#     * Deleted notes
#     * Orphan note_tags
#     * Orphan links
#     * Unused tags
#     * Orphan FTS rows
# ==========================================================

gc_sql() {
    local notes_dir="$1"

    # Safety: directory must exist
    [[ -d "$notes_dir" ]] || {
        echo "[Memory][GC] Invalid notes directory: $notes_dir" >&2
        exit 1
    }

    # Collect existing markdown files
    local existing_paths=()
    while IFS= read -r file; do
        existing_paths+=("'$(sql_escape "$file")'")
    done < <(find "$notes_dir" -type f -name "*.md")

    # Build NOT IN clause safely
    local path_clause
    if [[ ${#existing_paths[@]} -eq 0 ]]; then
        # No files found → delete all notes
        path_clause="1=1"
    else
        path_clause="path NOT IN ($(IFS=,; echo "${existing_paths[*]}"))"
    fi

    cat <<SQL

-- =========================================================
-- Remove deleted notes
-- =========================================================
DELETE FROM notes WHERE $path_clause;

-- =========================================================
-- Clean orphan note_tags
-- =========================================================
DELETE FROM note_tags
WHERE note_id NOT IN (SELECT id FROM notes);

-- =========================================================
-- Clean orphan links
-- =========================================================
DELETE FROM links
WHERE source_id NOT IN (SELECT id FROM notes)
   OR target_id NOT IN (SELECT id FROM notes);

-- =========================================================
-- Clean unused tags
-- =========================================================
DELETE FROM tags
WHERE id NOT IN (SELECT tag_id FROM note_tags);

-- =========================================================
-- Clean orphan FTS rows
-- =========================================================
DELETE FROM notes_fts
WHERE rowid NOT IN (SELECT id FROM notes);

SQL
}
#!/usr/bin/env bash
set -euo pipefail

# ==========================================================
# KaoBox - Memory Index Orchestrator (Module Pure)
# ==========================================================

[[ -n "${BRAIN_INDEX_LOADED:-}" ]] && return 0
readonly BRAIN_INDEX_LOADED=1

# ----------------------------------------------------------
# Environment validation (module must not exit shell)
# ----------------------------------------------------------

[[ -n "${BRAIN_DB:-}" ]] || {
    echo "[Memory][ERROR] BRAIN_DB not defined" >&2
    return 1
}

[[ -f "$BRAIN_DB" ]] || {
    echo "[Memory][ERROR] Database not found: $BRAIN_DB" >&2
    return 1
}

# ----------------------------------------------------------
# Engine bootstrap
# ----------------------------------------------------------

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENGINE="$BASE_DIR/engine"

source "$ENGINE/utils.sh"
source "$ENGINE/tx.sh"
source "$ENGINE/metadata.sh"
source "$ENGINE/fts.sh"
source "$ENGINE/tags.sh"
source "$ENGINE/links.sh"
source "$BASE_DIR/gc.sh"

# ----------------------------------------------------------
# Notes directory (respects env)
# ----------------------------------------------------------

: "${BRAIN_NOTES_DIR:=$NOTES_DIR}"
readonly BRAIN_NOTES_DIR

# ----------------------------------------------------------
# SQLite wrapper
# ----------------------------------------------------------

_sqlite_index_exec() {
    sqlite3 -batch "$BRAIN_DB" -cmd ".timeout 5000"
}

# ==========================================================
# INDEX SINGLE NOTE
# ==========================================================

index_note() {

    local file="$1"

    require_absolute "$file"
    require_file "$file"
    analyze_file "$file"

    {
        begin_tx

        metadata_sql "$file" "$FILE_TITLE" "$FILE_HASH" "$FILE_MTIME" "$FILE_SIZE"
        fts_sql "$file" "$FILE_TITLE" "$FILE_CONTENT"
        tags_sql "$file" "$file"
        links_sql "$file" "$file"

        commit_tx

    } | _sqlite_index_exec || {
        echo "[Memory][ERROR] Index transaction failed: $file" >&2
        return 1
    }

    log INFO "Indexed: $file"
}

# ==========================================================
# BATCH REINDEX
# ==========================================================

reindex_all() {

    local files=("$@")
    [[ ${#files[@]} -eq 0 ]] && return 0

    {
        begin_tx

        for file in "${files[@]}"; do
            require_absolute "$file"
            require_file "$file"
            analyze_file "$file"

            metadata_sql "$file" "$FILE_TITLE" "$FILE_HASH" "$FILE_MTIME" "$FILE_SIZE"
            fts_sql "$file" "$FILE_TITLE" "$FILE_CONTENT"
            tags_sql "$file" "$file"
            links_sql "$file" "$file"
        done

        gc_sql "$BRAIN_NOTES_DIR"

        commit_tx

    } | _sqlite_index_exec || {
        echo "[Memory][ERROR] Batch reindex failed" >&2
        return 1
    }

    # WAL maintenance (non critical)
    sqlite3 -batch "$BRAIN_DB" "PRAGMA wal_checkpoint(TRUNCATE);" >/dev/null 2>&1 || true
    sqlite3 -batch "$BRAIN_DB" "PRAGMA optimize;" >/dev/null 2>&1 || true

    log INFO "Batch reindex completed (${#files[@]} files)"
}
#!/usr/bin/env bash
set -euo pipefail

# =========================================================
# KAOBOX MEMORY MODULE
# File: init.sh
# Purpose: Initialize Brain structure (Markdown + SQLite)
#
# Guarantees:
#   - Idempotent schema
#   - Foreign keys enforced
#   - FTS rowid bound to notes.id
#   - Production safe
#
# Version: Brain v2.6 Stable
# =========================================================

# Environment must be injected by dispatcher

[[ -n "${BRAIN_DB:-}" ]] || {
    echo "[Memory][ERROR] Environment not initialized (BRAIN_DB missing)"
    exit 1
}

[[ -n "${BRAIN_ROOT:-}" ]] || {
    echo "[Memory][ERROR] BRAIN_ROOT not defined"
    exit 1
}

[[ -n "${INDEX_DIR:-}" ]] || {
    echo "[Memory][ERROR] INDEX_DIR not defined"
    exit 1
}

[[ -n "${BRAIN_DB:-}" ]] || {
    echo "[Memory][ERROR] BRAIN_DB not defined"
    exit 1
}

echo "[Memory] Ensuring brain directory structure..."

mkdir -p "$BRAIN_ROOT/inbox"
mkdir -p "$BRAIN_ROOT/notes"
mkdir -p "$BRAIN_ROOT/projects"
mkdir -p "$BRAIN_ROOT/archive"
mkdir -p "$INDEX_DIR"

# =========================================================
# SQLITE INITIALIZATION
# =========================================================

sqlite3 "$BRAIN_DB" <<'SQL'

PRAGMA journal_mode=WAL;
PRAGMA synchronous=NORMAL;
PRAGMA foreign_keys=ON;
PRAGMA busy_timeout=5000;
PRAGMA journal_size_limit=10485760;

-- =====================================================
-- CORE NOTES TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS notes (
    id INTEGER PRIMARY KEY,
    path TEXT UNIQUE NOT NULL,
    title TEXT,
    created_at TEXT DEFAULT (datetime('now')),
    updated_at TEXT,
    content_hash TEXT,
    file_mtime INTEGER,
    file_size INTEGER
);

CREATE INDEX IF NOT EXISTS idx_notes_title ON notes(title);

-- =====================================================
-- FTS5 VIRTUAL TABLE
-- -----------------------------------------------------
-- rowid == notes.id
-- Managed manually by engine (no triggers)
-- =====================================================

CREATE VIRTUAL TABLE IF NOT EXISTS notes_fts USING fts5(
    title,
    content
);

-- =====================================================
-- TAGS
-- =====================================================

CREATE TABLE IF NOT EXISTS tags (
    id INTEGER PRIMARY KEY,
    name TEXT UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS note_tags (
    note_id INTEGER NOT NULL,
    tag_id INTEGER NOT NULL,
    PRIMARY KEY (note_id, tag_id),
    FOREIGN KEY (note_id) REFERENCES notes(id) ON DELETE CASCADE,
    FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_tags_name ON tags(name);
CREATE INDEX IF NOT EXISTS idx_note_tags_note ON note_tags(note_id);
CREATE INDEX IF NOT EXISTS idx_note_tags_tag ON note_tags(tag_id);

-- =====================================================
-- LINKS (Graph Layer)
-- =====================================================

CREATE TABLE IF NOT EXISTS links (
    source_id INTEGER NOT NULL,
    target_id INTEGER NOT NULL,
    PRIMARY KEY (source_id, target_id),
    FOREIGN KEY (source_id) REFERENCES notes(id) ON DELETE CASCADE,
    FOREIGN KEY (target_id) REFERENCES notes(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_links_source ON links(source_id);
CREATE INDEX IF NOT EXISTS idx_links_target ON links(target_id);

SQL

echo "[Memory] Initialization complete (v2.6)."
#!/usr/bin/env bash
set -euo pipefail

# ==========================================================
# KaoBox - Memory Query Engine (Hardened V1)
# ----------------------------------------------------------
# - Idempotent
# - No exit
# - Safe LIMIT
# - Consistent output
# ==========================================================

[[ -n "${BRAIN_QUERY_LOADED:-}" ]] && return 0
readonly BRAIN_QUERY_LOADED=1

DEFAULT_LIMIT=20

# ----------------------------------------------------------
# Internal SQLite wrapper
# ----------------------------------------------------------

_sqlite_exec() {
    sqlite3 -batch -noheader -separator $'\t' "$BRAIN_DB"
}

# ----------------------------------------------------------
# Utility: sanitize LIMIT (integer only)
# ----------------------------------------------------------

_sanitize_limit() {
    local value="$1"

    [[ "$value" =~ ^[0-9]+$ ]] || value="$DEFAULT_LIMIT"
    printf "%s" "$value"
}

# ----------------------------------------------------------
# FTS Query
# ----------------------------------------------------------

query_fts() {

    [[ -n "${BRAIN_DB:-}" ]] || {
        echo "[Query] BRAIN_DB not defined"
        return 1
    }

    local q="$1"
    local limit
    limit="$(_sanitize_limit "${2:-$DEFAULT_LIMIT}")"

    [[ -z "$q" ]] && {
        echo "[Query] Empty search query"
        return 1
    }

    _sqlite_exec <<SQL
.parameter init
.parameter set @q "$q"
SELECT n.id,
       n.path,
       n.title,
       bm25(notes_fts) AS score
FROM notes_fts
JOIN notes n ON n.rowid = notes_fts.rowid
WHERE notes_fts MATCH @q
ORDER BY score
LIMIT $limit;
SQL
}

# ----------------------------------------------------------
# Tag Query
# ----------------------------------------------------------

query_by_tag() {

    [[ -n "${BRAIN_DB:-}" ]] || {
        echo "[Query] BRAIN_DB not defined"
        return 1
    }

    local tag="$1"
    local limit
    limit="$(_sanitize_limit "${2:-50}")"

    [[ -z "$tag" ]] && {
        echo "[Query] Empty tag"
        return 1
    }

    _sqlite_exec <<SQL
.parameter init
.parameter set @tag "$tag"
SELECT n.id,
       n.path,
       n.title,
       NULL as score
FROM notes n
JOIN note_tags nt ON n.id = nt.note_id
JOIN tags t ON t.id = nt.tag_id
WHERE t.name = @tag
ORDER BY n.updated_at DESC
LIMIT $limit;
SQL
}

# ----------------------------------------------------------
# Backlinks Query
# ----------------------------------------------------------

query_backlinks() {

    [[ -n "${BRAIN_DB:-}" ]] || {
        echo "[Query] BRAIN_DB not defined"
        return 1
    }

    local path="$1"

    [[ -z "$path" ]] && {
        echo "[Query] Missing path"
        return 1
    }

    _sqlite_exec <<SQL
.parameter init
.parameter set @path "$path"
SELECT src.id,
       src.path,
       src.title,
       NULL as score
FROM links l
JOIN notes src ON src.id = l.source_id
JOIN notes tgt ON tgt.id = l.target_id
WHERE tgt.path = @path;
SQL
}
