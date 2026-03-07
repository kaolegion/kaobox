#!/usr/bin/env bash
set -euo pipefail

# =========================================================
# KAOBOX MEMORY MODULE
# File: init.sh
#
# Initializes Brain filesystem + SQLite schema
#
# Guarantees:
#   - Idempotent schema
#   - Foreign keys enforced
#   - WAL journal mode
#   - FTS5 enabled
#   - Knowledge graph ready
#
# Version: Brain v3
# =========================================================


# ---------------------------------------------------------
# Environment validation
# ---------------------------------------------------------

[[ -n "${BRAIN_DB:-}" ]] || {
    echo "[Memory][ERROR] BRAIN_DB not defined"
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


# ---------------------------------------------------------
# Filesystem structure
# ---------------------------------------------------------

echo "[Memory] Ensuring brain directory structure..."

mkdir -p \
    "$BRAIN_ROOT/inbox" \
    "$BRAIN_ROOT/notes" \
    "$BRAIN_ROOT/projects" \
    "$BRAIN_ROOT/archive" \
    "$INDEX_DIR"


# ---------------------------------------------------------
# SQLite initialization
# ---------------------------------------------------------

echo "[Memory] Initializing SQLite brain..."

sqlite3 "$BRAIN_DB" <<'SQL'

-- =====================================================
-- PRAGMA CONFIG
-- =====================================================

PRAGMA journal_mode=WAL;
PRAGMA synchronous=NORMAL;
PRAGMA foreign_keys=ON;
PRAGMA busy_timeout=5000;

PRAGMA temp_store=MEMORY;
PRAGMA cache_size=-20000;

-- =====================================================
-- NOTES TABLE
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

CREATE INDEX IF NOT EXISTS idx_notes_path
ON notes(path);

CREATE INDEX IF NOT EXISTS idx_notes_title
ON notes(title);

CREATE INDEX IF NOT EXISTS idx_notes_updated
ON notes(updated_at);


-- =====================================================
-- FTS5 SEARCH ENGINE
-- External content mode
-- rowid = notes.id
-- =====================================================

CREATE VIRTUAL TABLE IF NOT EXISTS notes_fts
USING fts5(
    title,
    content,

    content='notes',
    content_rowid='id',

    tokenize='porter unicode61'
);


-- =====================================================
-- TAG SYSTEM
-- =====================================================

CREATE TABLE IF NOT EXISTS tags (
    id INTEGER PRIMARY KEY,
    name TEXT UNIQUE NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_tags_name
ON tags(name);


CREATE TABLE IF NOT EXISTS note_tags (
    note_id INTEGER NOT NULL,
    tag_id INTEGER NOT NULL,

    PRIMARY KEY (note_id, tag_id),

    FOREIGN KEY (note_id)
        REFERENCES notes(id)
        ON DELETE CASCADE,

    FOREIGN KEY (tag_id)
        REFERENCES tags(id)
        ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_note_tags_note
ON note_tags(note_id);

CREATE INDEX IF NOT EXISTS idx_note_tags_tag
ON note_tags(tag_id);


-- =====================================================
-- KNOWLEDGE GRAPH
-- =====================================================

CREATE TABLE IF NOT EXISTS links (
    source_id INTEGER NOT NULL,
    target_id INTEGER NOT NULL,

    PRIMARY KEY (source_id, target_id),

    FOREIGN KEY (source_id)
        REFERENCES notes(id)
        ON DELETE CASCADE,

    FOREIGN KEY (target_id)
        REFERENCES notes(id)
        ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_links_source
ON links(source_id);

CREATE INDEX IF NOT EXISTS idx_links_target
ON links(target_id);

SQL


echo "[Memory] Initialization complete."
echo "[Memory] Database: $BRAIN_DB"
