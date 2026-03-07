#!/usr/bin/env bash
set -euo pipefail

# ==========================================================
# KAOBOX - Memory Engine FTS Layer (v2.5 Simple)
# ----------------------------------------------------------
# Emits SQL only.
# Uses SELECT id internally (path is UNIQUE).
# Must be executed inside an active transaction.
# ==========================================================

fts_sql() {
    local path="$1"
    local title="$2"
    local content="$3"

    local escaped_path
    escaped_path="$(sql_escape "$path")"

    cat <<SQL
-- Remove existing FTS row
DELETE FROM notes_fts
WHERE rowid = (SELECT id FROM notes WHERE path='$escaped_path');

-- Insert updated FTS content
INSERT INTO notes_fts(rowid, title, content)
VALUES (
    (SELECT id FROM notes WHERE path='$escaped_path'),
    '$(sql_escape "$title")',
    '$(sql_escape "$content")'
);
SQL
}
