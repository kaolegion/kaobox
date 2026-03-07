#!/usr/bin/env bash
set -euo pipefail

# ==========================================================
# KAOBOX - Memory Engine Metadata Layer (v2.5)
# ----------------------------------------------------------
# Emits SQL only.
# No direct sqlite3 calls.
# Orchestrator manages execution & transactions.
# ==========================================================
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
SQL
}
