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

KX_DATA="/data"
KX_BRAIN="$KX_DATA/brain"
KX_INDEX="$KX_BRAIN/.index"
KX_DB="$KX_INDEX/brain.db"

export BRAIN_DB="$KX_DB"

echo "[Memory] Ensuring brain directory structure..."

mkdir -p "$KX_BRAIN/inbox"
mkdir -p "$KX_BRAIN/notes"
mkdir -p "$KX_BRAIN/projects"
mkdir -p "$KX_BRAIN/archive"
mkdir -p "$KX_INDEX"

# =========================================================
# SQLITE INITIALIZATION
# =========================================================

sqlite3 "$KX_DB" <<'SQL'

PRAGMA foreign_keys=ON;

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
