#!/usr/bin/env bash

set -e

# =========================================================
# KAOBOX MEMORY MODULE
# File: init.sh
# Purpose: Initialize Brain structure (Markdown + SQLite)
# =========================================================

# --- Paths ------------------------------------------------

KX_DATA="/data"
KX_BRAIN="$KX_DATA/brain"
KX_INDEX="$KX_BRAIN/.index"
KX_DB="$KX_INDEX/brain.db"

# --- Create directory structure --------------------------

echo "[Memory] Creating brain directories..."

mkdir -p "$KX_BRAIN/inbox"
mkdir -p "$KX_BRAIN/notes"
mkdir -p "$KX_BRAIN/projects"
mkdir -p "$KX_BRAIN/archive"
mkdir -p "$KX_INDEX"

# TODO: Future support for multi-brain instances

# --- Initialize SQLite database --------------------------

if [ ! -f "$KX_DB" ]; then
    echo "[Memory] Initializing SQLite index..."

    sqlite3 "$KX_DB" <<EOF
CREATE TABLE notes (
    id INTEGER PRIMARY KEY,
    path TEXT UNIQUE,
    title TEXT,
    created_at TEXT,
    updated_at TEXT,
    hash TEXT
);

CREATE TABLE tags (
    id INTEGER PRIMARY KEY,
    name TEXT UNIQUE
);

CREATE TABLE note_tags (
    note_id INTEGER,
    tag_id INTEGER
);

CREATE TABLE links (
    from_note INTEGER,
    to_note INTEGER
);
EOF

    echo "[Memory] Brain index created."
else
    echo "[Memory] Brain already initialized."
fi

echo "[Memory] Initialization complete."
