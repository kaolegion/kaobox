#!/usr/bin/env bash
set -euo pipefail

# ==========================================================
# KAOBOX - Memory Engine Metadata Layer (v2.5)
# ----------------------------------------------------------
# Emits SQL only.
# No direct sqlite3 calls.
# Orchestrator manages execution & transactions.
# ==========================================================

source "$(dirname "$0")/utils.sh"

compute_hash() {
    sha256sum "$1" | awk '{print $1}'
}

file_mtime() {
    stat -c %Y "$1"
}

file_size() {
    stat -c %s "$1"
}

extract_title() {
    head -n 1 "$1" | sed 's/^#\+ *//'
}

# ----------------------------------------------------------
# SQL: UPSERT NOTE + RETURN ID
# ----------------------------------------------------------

metadata_sql() {
    local path="$1"
    local title="$2"
    local hash="$3"
    local mtime="$4"
    local size="$5"

    cat <<SQL
INSERT INTO notes (path, title, updated_at, content_hash, file_mtime, file_size)
VALUES (
    '$(sql_escape "$path")',
    '$(sql_escape "$title")',
    datetime('now'),
    '$hash',
    $mtime,
    $size
)
ON CONFLICT(path) DO UPDATE SET
    title=excluded.title,
    updated_at=datetime('now'),
    content_hash=excluded.content_hash,
    file_mtime=excluded.file_mtime,
    file_size=excluded.file_size;

SELECT id FROM notes WHERE path='$(sql_escape "$path")';
SQL
}

# ----------------------------------------------------------
# SQL: DELETE NOTE (CASCADE CLEAN)
# ----------------------------------------------------------

delete_note_sql() {
    local note_id="$1"
    echo "DELETE FROM notes WHERE id=$note_id;"
}
