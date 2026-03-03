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
