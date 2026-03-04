#!/usr/bin/env bash
set -euo pipefail

# ==========================================================
# KAOBOX - Memory Query Engine
# ----------------------------------------------------------
# Role:
#   - Read-only query layer
#   - Full-text search
#   - Tag search
#   - Graph navigation
# ==========================================================

[[ -n "${BRAIN_DB:-}" ]] || {
    echo "[Memory] BRAIN_DB not defined"
    exit 1
}

search_fts() {
    local query="$1"

    sqlite3 "$BRAIN_DB" <<SQL
SELECT notes.path
FROM notes_fts
JOIN notes ON notes_fts.rowid = notes.id
WHERE notes_fts MATCH '$query'
ORDER BY rank;
SQL
}

search_tag() {
    local tag="$1"

    sqlite3 "$BRAIN_DB" <<SQL
SELECT n.path
FROM notes n
JOIN note_tags nt ON nt.note_id = n.id
JOIN tags t ON t.id = nt.tag_id
WHERE t.name = '$tag';
SQL
}

backlinks() {
    local path="$1"

    sqlite3 "$BRAIN_DB" <<SQL
SELECT src.path
FROM links l
JOIN notes src ON src.id = l.source_id
JOIN notes tgt ON tgt.id = l.target_id
WHERE tgt.path = '$path';
SQL
}

related() {
    local path="$1"

    sqlite3 "$BRAIN_DB" <<SQL
SELECT tgt.path
FROM links l
JOIN notes src ON src.id = l.source_id
JOIN notes tgt ON tgt.id = l.target_id
WHERE src.path = '$path';
SQL
}
